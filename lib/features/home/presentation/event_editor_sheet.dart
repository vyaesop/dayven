import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../domain/planner_models.dart';

Future<void> showEventEditorSheet({
  required BuildContext context,
  required DateTime selectedDate,
  required List<PlannerCalendar> calendars,
  String? defaultCalendarId,
  Future<void> Function(PlannerEventDraft draft)? onCreate,
  Future<void> Function(PlannerEvent event)? onUpdate,
  Future<void> Function(String eventId)? onDelete,
  PlannerEvent? initialEvent,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _EventEditorSheet(
      selectedDate: selectedDate,
      calendars: calendars,
      defaultCalendarId: defaultCalendarId,
      onCreate: onCreate,
      onUpdate: onUpdate,
      onDelete: onDelete,
      initialEvent: initialEvent,
    ),
  );
}

class _EventEditorSheet extends StatefulWidget {
  const _EventEditorSheet({
    required this.selectedDate,
    required this.calendars,
    this.defaultCalendarId,
    this.onCreate,
    this.onUpdate,
    this.onDelete,
    this.initialEvent,
  });

  final DateTime selectedDate;
  final List<PlannerCalendar> calendars;
  final String? defaultCalendarId;
  final Future<void> Function(PlannerEventDraft draft)? onCreate;
  final Future<void> Function(PlannerEvent event)? onUpdate;
  final Future<void> Function(String eventId)? onDelete;
  final PlannerEvent? initialEvent;

  @override
  State<_EventEditorSheet> createState() => _EventEditorSheetState();
}

class _EventEditorSheetState extends State<_EventEditorSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _locationController;
  late final TextEditingController _urlController;
  late final TextEditingController _noteController;
  late final TextEditingController _attendeesController;
  late DateTime _selectedDate;
  late bool _isAllDay;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late String _calendarId;
  late PlannerReminder _reminder;
  late PlannerRepeatRule _repeatRule;
  bool _isSaving = false;

  bool get _isEditing => widget.initialEvent != null;

  @override
  void initState() {
    super.initState();
    final initialEvent = widget.initialEvent;

    _titleController = TextEditingController(text: initialEvent?.title ?? '');
    _locationController = TextEditingController(
      text: initialEvent?.location ?? '',
    );
    _urlController = TextEditingController(text: initialEvent?.url ?? '');
    _noteController = TextEditingController(text: initialEvent?.note ?? '');
    _attendeesController = TextEditingController(
      text: initialEvent?.attendees.join(', ') ?? '',
    );
    _selectedDate = initialEvent == null
        ? DateTime(
            widget.selectedDate.year,
            widget.selectedDate.month,
            widget.selectedDate.day,
          )
        : DateTime(
            initialEvent.startAt.year,
            initialEvent.startAt.month,
            initialEvent.startAt.day,
          );
    _isAllDay = initialEvent?.isAllDay ?? false;
    final startDateTime =
        initialEvent?.startAt ??
        DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          9,
          0,
        );
    _startTime = TimeOfDay.fromDateTime(startDateTime);
    _endTime = TimeOfDay.fromDateTime(
      initialEvent?.endAt ??
          DateTime(
            _selectedDate.year,
            _selectedDate.month,
            _selectedDate.day,
            10,
            0,
          ),
    );
    _calendarId =
        initialEvent?.calendarId ??
        widget.defaultCalendarId ??
        widget.calendars.first.id;
    _reminder = initialEvent?.reminder ?? PlannerReminder.none;
    _repeatRule = initialEvent?.repeatRule ?? PlannerRepeatRule.never;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _urlController.dispose();
    _noteController.dispose();
    _attendeesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return FractionallySizedBox(
      heightFactor: 0.92,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 14,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 54,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.mutedInk.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _isSaving
                            ? null
                            : () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                      const Spacer(),
                      Text(
                        _isEditing ? 'EDIT EVENT' : 'NEW EVENT',
                        style: textTheme.labelLarge,
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: _isSaving ? null : _handleSave,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.charcoal,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 12,
                          ),
                        ),
                        child: Text(
                          _isSaving ? 'Saving…' : 'Save',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _LabeledField(
                    label: 'Title',
                    child: TextField(
                      controller: _titleController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: 'Event title',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _LabeledField(
                    label: 'Calendar',
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final calendar in widget.calendars)
                          ChoiceChip(
                            label: Text(calendar.name),
                            selected: _calendarId == calendar.id,
                            avatar: CircleAvatar(
                              radius: 5,
                              backgroundColor: calendar.color,
                            ),
                            onSelected: (_) {
                              setState(() {
                                _calendarId = calendar.id;
                              });
                            },
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _LabeledField(
                    label: 'Date & Time',
                    child: Column(
                      children: [
                        _ActionRow(
                          title: 'Date',
                          value:
                              '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                          onTap: _pickDate,
                        ),
                        const SizedBox(height: 10),
                        SwitchListTile.adaptive(
                          value: _isAllDay,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 4,
                          ),
                          title: const Text('All day'),
                          onChanged: (value) {
                            setState(() {
                              _isAllDay = value;
                            });
                          },
                        ),
                        if (!_isAllDay) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _ActionRow(
                                  title: 'Start',
                                  value: _startTime.format(context),
                                  onTap: _pickStartTime,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _ActionRow(
                                  title: 'End',
                                  value: _endTime.format(context),
                                  onTap: _pickEndTime,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _LabeledField(
                    label: 'Reminders & Repeats',
                    child: Column(
                      children: [
                        _ActionRow(
                          title: 'Reminder',
                          value: _reminder.label,
                          onTap: _pickReminder,
                        ),
                        const SizedBox(height: 10),
                        _ActionRow(
                          title: 'Repeats',
                          value: _repeatRule.label,
                          onTap: _pickRepeatRule,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _LabeledField(
                    label: 'People',
                    child: TextField(
                      controller: _attendeesController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        hintText: 'Jane, Sam, Avery',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _LabeledField(
                    label: 'Location',
                    child: TextField(
                      controller: _locationController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        hintText: 'Where is it happening?',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _LabeledField(
                    label: 'URL',
                    child: TextField(
                      controller: _urlController,
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(hintText: 'https://'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _LabeledField(
                    label: 'Notes',
                    child: TextField(
                      controller: _noteController,
                      minLines: 4,
                      maxLines: 6,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: 'Anything important to remember?',
                      ),
                    ),
                  ),
                  if (_isEditing && widget.onDelete != null) ...[
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _isSaving ? null : _handleDelete,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFD04545),
                          side: const BorderSide(
                            color: Color(0xFFD04545),
                            width: 1.2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('Delete Event'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
    );

    if (picked == null) {
      return;
    }

    setState(() {
      _selectedDate = DateTime(picked.year, picked.month, picked.day);
    });
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );

    if (picked == null) {
      return;
    }

    setState(() {
      _startTime = picked;
    });
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );

    if (picked == null) {
      return;
    }

    setState(() {
      _endTime = picked;
    });
  }

  Future<void> _handleSave() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      _showMessage('Title is required.');
      return;
    }

    final startAt = _isAllDay
        ? DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day)
        : DateTime(
            _selectedDate.year,
            _selectedDate.month,
            _selectedDate.day,
            _startTime.hour,
            _startTime.minute,
          );
    final endAt = _isAllDay
        ? DateTime(
            _selectedDate.year,
            _selectedDate.month,
            _selectedDate.day + 1,
          )
        : DateTime(
            _selectedDate.year,
            _selectedDate.month,
            _selectedDate.day,
            _endTime.hour,
            _endTime.minute,
          );

    if (!_isAllDay && !endAt.isAfter(startAt)) {
      _showMessage('End time must be after start time.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      if (_isEditing) {
        final original = widget.initialEvent!;
        if (original.repeatRule != PlannerRepeatRule.never) {
          final choice = await _showEditRepeatingDialog();
          if (choice == null) {
            if (mounted) setState(() => _isSaving = false);
            return;
          }
        }
        await widget.onUpdate?.call(
          original.copyWith(
            title: title,
            isAllDay: _isAllDay,
            startAt: startAt,
            endAt: endAt,
            location: _locationController.text.trim(),
            url: _urlController.text.trim(),
            note: _noteController.text.trim(),
            calendarId: _calendarId,
            reminder: _reminder,
            repeatRule: _repeatRule,
            attendees: _parseAttendees(),
          ),
        );
      } else {
        await widget.onCreate?.call(
          PlannerEventDraft(
            title: title,
            isAllDay: _isAllDay,
            startAt: startAt,
            endAt: endAt,
            location: _locationController.text.trim(),
            url: _urlController.text.trim(),
            note: _noteController.text.trim(),
            calendarId: _calendarId,
            reminder: _reminder,
            repeatRule: _repeatRule,
            attendees: _parseAttendees(),
          ),
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (_) {
      _showMessage('Could not save this event.');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _handleDelete() async {
    if (widget.initialEvent == null || widget.onDelete == null) return;

    final confirmed = await _showDeleteConfirmation();
    if (confirmed != true) return;

    setState(() => _isSaving = true);

    try {
      await widget.onDelete!(widget.initialEvent!.id);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      _showMessage('Could not delete this event.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<bool?> _showDeleteConfirmation() {
    final eventTitle = widget.initialEvent?.title ?? 'this event';
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(ctx).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 46,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.mutedInk.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 22),
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD04545).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: Color(0xFFD04545),
                    size: 26,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Delete Event?',
                  style: Theme.of(ctx).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  '"$eventTitle" will be permanently removed.',
                  style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                    color: AppColors.mutedInk,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFD04545),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Yes, Delete This Event',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.ink,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Returns true = edit all future, false = only this, null = cancelled
  Future<bool?> _showEditRepeatingDialog() {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final textTheme = Theme.of(ctx).textTheme;
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(ctx).scaffoldBackgroundColor,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 46,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.mutedInk.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'This is a repeating event',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.mutedInk,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _EditRepeatOption(
                    label: 'Edit all future events',
                    onTap: () => Navigator.of(ctx).pop(true),
                    textTheme: textTheme,
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  _EditRepeatOption(
                    label: 'Edit only this event',
                    onTap: () => Navigator.of(ctx).pop(false),
                    textTheme: textTheme,
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.of(ctx).pop(null),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.mutedInk,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<String> _parseAttendees() {
    return _attendeesController.text
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList();
  }

  Future<void> _pickReminder() async {
    final selected = await showModalBottomSheet<PlannerReminder>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _ReminderPickerSheet(current: _reminder),
    );
    if (selected == null) return;
    setState(() => _reminder = selected);
  }

  Future<void> _pickRepeatRule() async {
    final selected = await showModalBottomSheet<PlannerRepeatRule>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _RepeatRuleSheet(current: _repeatRule),
    );
    if (selected == null) return;
    setState(() => _repeatRule = selected);
  }


  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(color: AppColors.mutedInk),
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.title,
    required this.value,
    required this.onTap,
  });

  final String title;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            Text(title, style: Theme.of(context).textTheme.bodyLarge),
            const Spacer(),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditRepeatOption extends StatelessWidget {
  const _EditRepeatOption({
    required this.label,
    required this.onTap,
    required this.textTheme,
  });

  final String label;
  final VoidCallback onTap;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        child: Row(
          children: [
            Text(
              label,
              style: textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.mutedInk,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Reminder Picker ──────────────────────────────────────────────────────────

class _ReminderPickerSheet extends StatelessWidget {
  const _ReminderPickerSheet({required this.current});
  final PlannerReminder current;

  static const _quickGrid = [
    PlannerReminder.fiveMinutesBefore,
    PlannerReminder.tenMinutesBefore,
    PlannerReminder.fifteenMinutesBefore,
    PlannerReminder.thirtyMinutesBefore,
  ];

  static const _longer = [
    PlannerReminder.oneHourBefore,
    PlannerReminder.twoHoursBefore,
    PlannerReminder.oneDayBefore,
    PlannerReminder.oneWeekBefore,
  ];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 46, height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.mutedInk.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text('Reminder', style: textTheme.headlineMedium),
              const SizedBox(height: 16),
              // None tile
              _ReminderTile(
                value: PlannerReminder.none,
                current: current,
                onTap: (v) => Navigator.of(context).pop(v),
              ),
              const SizedBox(height: 12),
              Text(
                'MINUTES BEFORE',
                style: textTheme.labelSmall?.copyWith(
                  color: AppColors.mutedInk, letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (final r in _quickGrid) ...[
                    Expanded(
                      child: _ReminderGridCell(
                        value: r,
                        current: current,
                        onTap: (v) => Navigator.of(context).pop(v),
                      ),
                    ),
                    if (r != _quickGrid.last) const SizedBox(width: 8),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'LONGER',
                style: textTheme.labelSmall?.copyWith(
                  color: AppColors.mutedInk, letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              for (final r in _longer)
                _ReminderTile(
                  value: r,
                  current: current,
                  onTap: (v) => Navigator.of(context).pop(v),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReminderGridCell extends StatelessWidget {
  const _ReminderGridCell({
    required this.value,
    required this.current,
    required this.onTap,
  });
  final PlannerReminder value;
  final PlannerReminder current;
  final void Function(PlannerReminder) onTap;

  @override
  Widget build(BuildContext context) {
    final selected = value == current;
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.coral : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? AppColors.coral
                : AppColors.mutedInk.withValues(alpha: 0.15),
          ),
        ),
        child: Center(
          child: Text(
            value.label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}

class _ReminderTile extends StatelessWidget {
  const _ReminderTile({
    required this.value,
    required this.current,
    required this.onTap,
  });
  final PlannerReminder value;
  final PlannerReminder current;
  final void Function(PlannerReminder) onTap;

  @override
  Widget build(BuildContext context) {
    final selected = value == current;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(value.label),
      trailing: selected
          ? const Icon(Icons.check_circle_rounded, color: AppColors.coral)
          : null,
      onTap: () => onTap(value),
    );
  }
}

// ── Repeat Rule Builder ───────────────────────────────────────────────────────

enum _EndsMode { never, afterN, onDate }

class _RepeatRuleSheet extends StatefulWidget {
  const _RepeatRuleSheet({required this.current});
  final PlannerRepeatRule current;

  @override
  State<_RepeatRuleSheet> createState() => _RepeatRuleSheetState();
}

class _RepeatRuleSheetState extends State<_RepeatRuleSheet> {
  late PlannerRepeatRule _selected;
  int _repeatEvery = 1;
  _EndsMode _endsMode = _EndsMode.never;
  int _endsAfterN = 1;
  late DateTime _endsOnDate;

  static const _tabs = [
    PlannerRepeatRule.never,
    PlannerRepeatRule.daily,
    PlannerRepeatRule.weekly,
    PlannerRepeatRule.biweekly,
    PlannerRepeatRule.monthly,
    PlannerRepeatRule.yearly,
  ];

  static const _tabLabels = ['OFF', 'DAILY', 'WEEKLY', '2 WEEKS', 'MONTHLY', 'YEARLY'];

  static const _unitLabels = ['', 'day', 'week', 'weeks', 'month', 'year'];

  @override
  void initState() {
    super.initState();
    _selected = widget.current;
    _endsOnDate = DateTime.now().add(const Duration(days: 30));
  }

  String get _repeatEveryLabel {
    final idx = _tabs.indexOf(_selected).clamp(0, _tabs.length - 1);
    final unit = _unitLabels[idx];
    return '$_repeatEvery $unit${_repeatEvery > 1 && idx > 0 ? 's' : ''}';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final tabIdx = _tabs.indexOf(_selected).clamp(0, _tabs.length - 1);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 46, height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.mutedInk.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Text('Repeats', style: textTheme.headlineMedium),
                  const Spacer(),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(_selected),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.charcoal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10,
                      ),
                    ),
                    child: const Text('Done',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _tabs.length,
                  separatorBuilder: (context, i) => const SizedBox(width: 6),
                  itemBuilder: (context, i) {
                    final isSelected = i == tabIdx;
                    return GestureDetector(
                      onTap: () => setState(() => _selected = _tabs[i]),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: isSelected ? accent : Colors.white,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: isSelected
                                ? accent
                                : AppColors.mutedInk.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            _tabLabels[i],
                            style: textTheme.labelMedium?.copyWith(
                              color: isSelected ? Colors.white : AppColors.ink,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (_selected != PlannerRepeatRule.never) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── REPEAT EVERY ──
                      Text(
                        'REPEAT EVERY',
                        style: textTheme.labelSmall?.copyWith(
                          color: AppColors.mutedInk, letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Text(_repeatEveryLabel, style: textTheme.bodyLarge),
                          const Spacer(),
                          _CountStepper(
                            value: _repeatEvery,
                            min: 1,
                            max: 99,
                            accentColor: accent,
                            onChanged: (v) => setState(() => _repeatEvery = v),
                          ),
                        ],
                      ),
                      // ── REPEAT ON (weekly/biweekly) ──
                      if (_selected == PlannerRepeatRule.weekly ||
                          _selected == PlannerRepeatRule.biweekly) ...[
                        const SizedBox(height: 14),
                        const Divider(height: 1),
                        const SizedBox(height: 14),
                        Text(
                          'REPEAT ON',
                          style: textTheme.labelSmall?.copyWith(
                            color: AppColors.mutedInk, letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _WeekdaySelector(accentColor: accent),
                      ],
                      const SizedBox(height: 14),
                      const Divider(height: 1),
                      const SizedBox(height: 14),
                      // ── ENDS ──
                      Text(
                        'ENDS',
                        style: textTheme.labelSmall?.copyWith(
                          color: AppColors.mutedInk, letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _EndsRadioRow(
                        label: 'Never',
                        selected: _endsMode == _EndsMode.never,
                        onTap: () => setState(() => _endsMode = _EndsMode.never),
                        textTheme: textTheme,
                        accentColor: accent,
                      ),
                      const SizedBox(height: 2),
                      _EndsRadioRow(
                        label: 'After a number of times',
                        selected: _endsMode == _EndsMode.afterN,
                        onTap: () => setState(() => _endsMode = _EndsMode.afterN),
                        textTheme: textTheme,
                        accentColor: accent,
                        trailing: _endsMode == _EndsMode.afterN
                            ? _CountStepper(
                                value: _endsAfterN,
                                min: 1,
                                max: 999,
                                accentColor: accent,
                                onChanged: (v) =>
                                    setState(() => _endsAfterN = v),
                              )
                            : null,
                      ),
                      const SizedBox(height: 2),
                      _EndsRadioRow(
                        label: 'On a date',
                        selected: _endsMode == _EndsMode.onDate,
                        onTap: () => setState(() => _endsMode = _EndsMode.onDate),
                        textTheme: textTheme,
                        accentColor: accent,
                      ),
                      if (_endsMode == _EndsMode.onDate) ...[
                        const SizedBox(height: 14),
                        _DateWheelPicker(
                          date: _endsOnDate,
                          accentColor: accent,
                          onChanged: (d) => setState(() => _endsOnDate = d),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EndsRadioRow extends StatelessWidget {
  const _EndsRadioRow({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.textTheme,
    required this.accentColor,
    this.trailing,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final TextTheme textTheme;
  final Color accentColor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? accentColor
                      : AppColors.mutedInk.withValues(alpha: 0.35),
                  width: selected ? 6 : 1.5,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: textTheme.bodyMedium?.copyWith(
                color: selected ? AppColors.ink : AppColors.mutedInk,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if (trailing != null) ...[
              const Spacer(),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

class _CountStepper extends StatelessWidget {
  const _CountStepper({
    required this.value,
    required this.min,
    required this.max,
    required this.accentColor,
    required this.onChanged,
  });

  final int value;
  final int min;
  final int max;
  final Color accentColor;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StepBtn(
          icon: Icons.remove_rounded,
          onTap: value > min ? () => onChanged(value - 1) : null,
          accentColor: accentColor,
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 32,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: accentColor,
            ),
          ),
        ),
        const SizedBox(width: 6),
        _StepBtn(
          icon: Icons.add_rounded,
          onTap: value < max ? () => onChanged(value + 1) : null,
          accentColor: accentColor,
        ),
      ],
    );
  }
}

class _StepBtn extends StatelessWidget {
  const _StepBtn({
    required this.icon,
    required this.onTap,
    required this.accentColor,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: enabled
                ? accentColor.withValues(alpha: 0.5)
                : AppColors.line,
          ),
        ),
        child: Icon(
          icon,
          size: 16,
          color: enabled ? accentColor : AppColors.mutedInk,
        ),
      ),
    );
  }
}

class _DateWheelPicker extends StatefulWidget {
  const _DateWheelPicker({
    required this.date,
    required this.accentColor,
    required this.onChanged,
  });

  final DateTime date;
  final Color accentColor;
  final ValueChanged<DateTime> onChanged;

  @override
  State<_DateWheelPicker> createState() => _DateWheelPickerState();
}

class _DateWheelPickerState extends State<_DateWheelPicker> {
  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  late FixedExtentScrollController _monthCtrl;
  late FixedExtentScrollController _dayCtrl;
  late FixedExtentScrollController _yearCtrl;

  late int _month;
  late int _day;
  late int _year;

  @override
  void initState() {
    super.initState();
    _month = widget.date.month - 1;
    _day = widget.date.day - 1;
    _year = widget.date.year;
    _monthCtrl = FixedExtentScrollController(initialItem: _month);
    _dayCtrl = FixedExtentScrollController(initialItem: _day);
    _yearCtrl = FixedExtentScrollController(
      initialItem: _year - DateTime.now().year,
    );
  }

  @override
  void dispose() {
    _monthCtrl.dispose();
    _dayCtrl.dispose();
    _yearCtrl.dispose();
    super.dispose();
  }

  int get _daysInMonth =>
      DateUtils.getDaysInMonth(_year, _month + 1);

  void _notify() {
    final day = _day.clamp(0, _daysInMonth - 1);
    widget.onChanged(DateTime(_year, _month + 1, day + 1));
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final baseYear = DateTime.now().year;
    const itemH = 40.0;
    const visibleItems = 3;

    return SizedBox(
      height: itemH * visibleItems,
      child: Row(
        children: [
          // Month
          Expanded(
            flex: 5,
            child: ListWheelScrollView.useDelegate(
              controller: _monthCtrl,
              itemExtent: itemH,
              physics: const FixedExtentScrollPhysics(),
              onSelectedItemChanged: (i) {
                setState(() {
                  _month = i;
                  _day = _day.clamp(0, _daysInMonth - 1);
                });
                _notify();
              },
              childDelegate: ListWheelChildBuilderDelegate(
                childCount: 12,
                builder: (context, i) => _WheelItem(
                  label: _months[i],
                  selected: i == _month,
                  accentColor: widget.accentColor,
                  textTheme: textTheme,
                ),
              ),
            ),
          ),
          // Day
          Expanded(
            flex: 2,
            child: ListWheelScrollView.useDelegate(
              controller: _dayCtrl,
              itemExtent: itemH,
              physics: const FixedExtentScrollPhysics(),
              onSelectedItemChanged: (i) {
                setState(() => _day = i);
                _notify();
              },
              childDelegate: ListWheelChildBuilderDelegate(
                childCount: _daysInMonth,
                builder: (context, i) => _WheelItem(
                  label: '${i + 1}',
                  selected: i == _day,
                  accentColor: widget.accentColor,
                  textTheme: textTheme,
                ),
              ),
            ),
          ),
          // Year
          Expanded(
            flex: 3,
            child: ListWheelScrollView.useDelegate(
              controller: _yearCtrl,
              itemExtent: itemH,
              physics: const FixedExtentScrollPhysics(),
              onSelectedItemChanged: (i) {
                setState(() => _year = baseYear + i);
                _notify();
              },
              childDelegate: ListWheelChildBuilderDelegate(
                childCount: 30,
                builder: (context, i) => _WheelItem(
                  label: '${baseYear + i}',
                  selected: baseYear + i == _year,
                  accentColor: widget.accentColor,
                  textTheme: textTheme,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WheelItem extends StatelessWidget {
  const _WheelItem({
    required this.label,
    required this.selected,
    required this.accentColor,
    required this.textTheme,
  });

  final String label;
  final bool selected;
  final Color accentColor;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        label,
        style: textTheme.bodyLarge?.copyWith(
          color: selected ? accentColor : AppColors.mutedInk,
          fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
          fontSize: selected ? 16 : 14,
        ),
      ),
    );
  }
}

class _WeekdaySelector extends StatefulWidget {
  const _WeekdaySelector({required this.accentColor});
  final Color accentColor;

  @override
  State<_WeekdaySelector> createState() => _WeekdaySelectorState();
}

class _WeekdaySelectorState extends State<_WeekdaySelector> {
  final Set<int> _selected = {};
  static const _labels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (i) {
        final isOn = _selected.contains(i);
        return GestureDetector(
          onTap: () => setState(() {
            if (isOn) { _selected.remove(i); } else { _selected.add(i); }
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: isOn ? widget.accentColor : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: isOn
                    ? widget.accentColor
                    : AppColors.mutedInk.withValues(alpha: 0.25),
              ),
            ),
            child: Center(
              child: Text(
                _labels[i],
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: isOn ? Colors.white : AppColors.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
