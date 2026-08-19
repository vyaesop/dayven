import {
  authenticateUser, cors, HttpError,
  type VercelRequest, type VercelResponse,
} from '../../_shared';

// Allowed reminder tokens - mirror PlannerReminder.storageValue on the client.
const REMINDER_TOKENS = [
  'none', 'at_time', '5_min_before', '10_min_before', '15_min_before',
  '30_min_before', '1_hour_before', '2_hours_before', '1_day_before',
  '1_week_before',
];

// Allowed recurrence frequencies - mirror PlannerRepeatRule.storageValue.
const FREQUENCIES = ['never', 'daily', 'weekly', 'biweekly', 'monthly', 'yearly'];

// Gemini structured-output schema (OpenAPI subset; types are UPPERCASE).
const RESPONSE_SCHEMA = {
  type: 'OBJECT',
  properties: {
    title: { type: 'STRING' },
    isAllDay: { type: 'BOOLEAN' },
    start: { type: 'STRING', description: 'Local start "YYYY-MM-DDTHH:mm:ss", no timezone suffix' },
    end: { type: 'STRING', description: 'Local end "YYYY-MM-DDTHH:mm:ss", no timezone suffix' },
    location: { type: 'STRING', nullable: true },
    url: { type: 'STRING', nullable: true },
    note: { type: 'STRING', nullable: true },
    attendees: { type: 'ARRAY', items: { type: 'STRING' } },
    calendarId: { type: 'STRING', nullable: true, description: 'An id from the provided calendar list, or null' },
    reminder: { type: 'STRING', enum: REMINDER_TOKENS },
    recurrence: {
      type: 'OBJECT',
      properties: {
        frequency: { type: 'STRING', enum: FREQUENCIES },
        interval: { type: 'INTEGER' },
        byWeekdays: { type: 'ARRAY', items: { type: 'INTEGER' }, description: '1=Monday .. 7=Sunday' },
        count: { type: 'INTEGER', nullable: true },
        until: { type: 'STRING', nullable: true, description: 'YYYY-MM-DD' },
      },
      required: ['frequency', 'interval'],
      propertyOrdering: ['frequency', 'interval', 'byWeekdays', 'count', 'until'],
    },
  },
  required: ['title', 'isAllDay', 'start', 'end', 'reminder', 'recurrence'],
  propertyOrdering: [
    'title', 'isAllDay', 'start', 'end', 'location', 'url', 'note',
    'attendees', 'calendarId', 'reminder', 'recurrence',
  ],
};

interface CalendarRef { id: string; name: string; }

function readCalendars(input: unknown): CalendarRef[] {
  if (!Array.isArray(input)) return [];
  return input.flatMap((c) => {
    if (c && typeof c === 'object') {
      const id = (c as Record<string, unknown>).id;
      const name = (c as Record<string, unknown>).name;
      if (typeof id === 'string' && id.length > 0) {
        return [{ id, name: typeof name === 'string' ? name : id }];
      }
    }
    return [];
  });
}

function offsetLabel(minutes: number): string {
  const sign = minutes >= 0 ? '+' : '-';
  const abs = Math.abs(minutes);
  const hh = String(Math.floor(abs / 60)).padStart(2, '0');
  const mm = String(abs % 60).padStart(2, '0');
  return `${sign}${hh}:${mm}`;
}

function buildSystemPrompt(body: Record<string, unknown>): string {
  const weekday = typeof body.weekday === 'string' ? body.weekday : 'today';
  const nowLocal = typeof body.now_local === 'string' ? body.now_local : '';
  const timezone = typeof body.timezone === 'string' ? body.timezone : 'local time';
  const offset = typeof body.utc_offset_minutes === 'number' ? body.utc_offset_minutes : 0;
  const calendars = readCalendars(body.calendars);
  const calLines = calendars.length
    ? calendars.map((c) => `- ${c.id} - ${c.name}`).join('\n')
    : '- (none provided)';

  return [
    'You convert a short, plain-language description of a plan into ONE structured calendar event for the Dayven planner.',
    '',
    'Context:',
    `- Right now it is ${weekday}, ${nowLocal} (${timezone}, UTC${offsetLabel(offset)}). Resolve every relative date and time ("tomorrow", "next Thursday", "tonight", "in 2 weeks") against this exact moment, in the user's local time.`,
    '- Available calendars (pick the best fit by meaning and return its id):',
    calLines,
    '',
    'Rules:',
    '- "start" and "end" are local wall-clock times formatted "YYYY-MM-DDTHH:mm:ss" with NO timezone suffix.',
    '- If only a start time is given, make the event 1 hour long. Honor an explicit end time or duration.',
    '- If a day is given with no time, set isAllDay=false and default to 09:00 for 1 hour - unless it clearly reads as an all-day thing (a holiday, a birthday, a full-day trip), then isAllDay=true with 00:00 times.',
    '- If no date is implied at all, use today.',
    '- Choose calendarId from the list above by meaning (a work meeting → a work calendar, a run → exercise, dinner with friends → friends or family). If genuinely unsure, set calendarId to null.',
    '- Set "reminder" only when the user asks for one ("remind me 30 min before" → "30_min_before"); otherwise "none". Use the closest allowed token.',
    '- Detect recurrence ("every Tuesday", "daily", "every other week", "monthly"). byWeekdays uses 1=Monday .. 7=Sunday. If it does not repeat: frequency="never", interval=1, byWeekdays=[].',
    '- Keep "title" short and human ("Lunch with Sara", not the whole sentence). Pull out location, url (meeting links), and people (attendees) when present.',
    '- Never invent details that are not stated or clearly implied. Respond with JSON only.',
  ].join('\n');
}

export default async function handler(req: VercelRequest, res: VercelResponse) {
  cors(res);
  if (req.method === 'OPTIONS') return res.status(204).end();

  try {
    // Gate on a signed-in user so the (server-held) model key can't be abused.
    await authenticateUser(req);
    if (req.method !== 'POST') return res.status(405).json({ error: 'Method not allowed' });

    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) throw new HttpError(500, 'GEMINI_API_KEY not configured');
    // Default to a model with free-tier quota. `gemini-2.5-flash-lite` is an
    // even cheaper/faster option for this extraction task.
    const model = process.env.GEMINI_MODEL ?? 'gemini-2.5-flash';

    const raw = req.body;
    const body = (typeof raw === 'string' ? JSON.parse(raw) : raw ?? {}) as Record<string, unknown>;
    const text = typeof body.text === 'string' ? body.text.trim() : '';
    if (!text) throw new HttpError(400, 'Missing "text"');
    if (text.length > 2000) throw new HttpError(400, 'That description is too long.');

    const geminiBody = {
      systemInstruction: { parts: [{ text: buildSystemPrompt(body) }] },
      contents: [{ role: 'user', parts: [{ text }] }],
      generationConfig: {
        temperature: 0.2,
        maxOutputTokens: 1024,
        // This is a fast, deterministic extraction - turn off 2.5's "thinking"
        // so it doesn't consume the output budget (which truncates the JSON)
        // and stays cheap. Ignored by models without a thinking mode.
        thinkingConfig: { thinkingBudget: 0 },
        responseMimeType: 'application/json',
        responseSchema: RESPONSE_SCHEMA,
      },
    };

    const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`;
    const geminiRes = await fetch(url, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify(geminiBody),
    });

    if (!geminiRes.ok) {
      const detail = await geminiRes.text();
      // Surface a trimmed reason (e.g. quota/rate limits) without the full payload.
      throw new HttpError(502, `AI service error (${geminiRes.status}): ${detail.slice(0, 240)}`);
    }

    const data = (await geminiRes.json()) as {
      candidates?: { content?: { parts?: { text?: string }[] } }[];
      promptFeedback?: { blockReason?: string };
    };

    if (data.promptFeedback?.blockReason) {
      throw new HttpError(422, 'That description could not be processed.');
    }

    const parts = data.candidates?.[0]?.content?.parts ?? [];
    const jsonText = parts.map((p) => p.text ?? '').join('').trim();
    if (!jsonText) throw new HttpError(422, 'No event could be read from that.');

    let parsed: unknown;
    try {
      parsed = JSON.parse(jsonText);
    } catch {
      throw new HttpError(502, 'AI returned malformed output. Try rephrasing.');
    }
    if (!parsed || typeof parsed !== 'object') {
      throw new HttpError(502, 'AI returned an unexpected shape.');
    }

    return res.status(200).json({ parsed });
  } catch (err) {
    if (err instanceof HttpError) return res.status(err.status).json({ error: err.message });
    return res.status(500).json({ error: err instanceof Error ? err.message : 'Unexpected error' });
  }
}
