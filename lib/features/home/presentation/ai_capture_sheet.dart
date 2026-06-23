import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/ai/ai_event_service.dart';
import '../../../core/network/api_exception.dart';
import '../domain/planner_models.dart';

/// Quick-capture: the user describes an event in plain language and gets back a
/// [PlannerEventDraft] (returned via pop) to review in the editor before saving.
Future<PlannerEventDraft?> showAiCaptureSheet({
  required BuildContext context,
  required List<PlannerCalendar> calendars,
  required DateTime selectedDate,
  String? defaultCalendarId,
}) {
  return showModalBottomSheet<PlannerEventDraft>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _AiCaptureSheet(
      calendars: calendars,
      selectedDate: selectedDate,
      defaultCalendarId: defaultCalendarId,
    ),
  );
}

class _AiCaptureSheet extends ConsumerStatefulWidget {
  const _AiCaptureSheet({
    required this.calendars,
    required this.selectedDate,
    this.defaultCalendarId,
  });

  final List<PlannerCalendar> calendars;
  final DateTime selectedDate;
  final String? defaultCalendarId;

  @override
  ConsumerState<_AiCaptureSheet> createState() => _AiCaptureSheetState();
}

class _AiCaptureSheetState extends ConsumerState<_AiCaptureSheet> {
  final TextEditingController _controller = TextEditingController();
  bool _loading = false;
  String? _error;

  static const _examples = [
    'Lunch with Sara Thursday 1pm at Café Lima, remind me 30 min before',
    'Gym every Mon, Wed, Fri at 7am',
    'Dentist next Tuesday 2pm, remind me a day before',
    "Mom's birthday Aug 14, all day",
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() => _error = 'Type a few words first.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final draft = await ref.read(aiEventServiceProvider).parse(
            text: text,
            calendars: widget.calendars,
            defaultCalendarId: widget.defaultCalendarId,
            now: DateTime.now(),
            fallbackDate: widget.selectedDate,
          );
      if (mounted) Navigator.of(context).pop(draft);
    } on ApiException catch (error) {
      if (mounted) {
        setState(() {
          _error = _friendly(error);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Something went wrong. Try again.';
          _loading = false;
        });
      }
    }
  }

  String _friendly(ApiException error) {
    switch (error.statusCode) {
      case 401:
        return 'Sign in to use AI capture.';
      case 500:
        return 'AI capture isn’t set up on the server yet.';
      default:
        return _extractError(error.message) ??
            'Couldn’t reach AI capture. Check your connection and try again.';
    }
  }

  String? _extractError(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['error'] is String) {
        return decoded['error'] as String;
      }
    } catch (_) {
      // Not JSON — fall through.
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final tones = context.plannerTones;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 46,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.mutedInk.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded,
                        size: 20, color: context.plannerAccent),
                    const SizedBox(width: 8),
                    Text('Add with AI', style: textTheme.headlineMedium),
                    const Spacer(),
                    IconButton(
                      onPressed:
                          _loading ? null : () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Describe your event in your own words.',
                  style:
                      textTheme.bodyMedium?.copyWith(color: tones.mutedInk),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _controller,
                  autofocus: true,
                  enabled: !_loading,
                  minLines: 2,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _loading ? null : _submit(),
                  decoration: const InputDecoration(
                    hintText: "e.g. lunch with Sara Thu 1pm at Café Lima",
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'TRY',
                  style: textTheme.labelSmall?.copyWith(
                    color: tones.mutedInk,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final example in _examples)
                      _ExampleChip(
                        label: example,
                        onTap: _loading
                            ? null
                            : () {
                                setState(() {
                                  _controller.text = example;
                                  _controller.selection =
                                      TextSelection.collapsed(
                                          offset: example.length);
                                  _error = null;
                                });
                              },
                      ),
                  ],
                ),
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          size: 18, color: Color(0xFFD05A5A)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: textTheme.bodyMedium
                              ?.copyWith(color: const Color(0xFFD05A5A)),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _loading ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: context.plannerAccent,
                      foregroundColor: context.onPlannerAccent,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: _loading
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: context.onPlannerAccent,
                            ),
                          )
                        : const Icon(Icons.auto_awesome_rounded, size: 18),
                    label: Text(
                      _loading ? 'Reading…' : 'Create event',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    'You can review and edit everything before it’s saved.',
                    style: textTheme.labelSmall?.copyWith(color: tones.mutedInk),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ExampleChip extends StatelessWidget {
  const _ExampleChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tones = context.plannerTones;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: tones.surfaceRaised,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: tones.line),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: tones.ink,
              ),
        ),
      ),
    );
  }
}
