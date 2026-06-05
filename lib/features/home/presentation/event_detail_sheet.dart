import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/theme/app_theme.dart';
import '../domain/planner_models.dart';

Future<void> showEventDetailSheet({
  required BuildContext context,
  required PlannerEvent event,
  required PlannerCalendar calendar,
  required VoidCallback onEdit,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) =>
        _EventDetailSheet(event: event, calendar: calendar, onEdit: onEdit),
  );
}

class _EventDetailSheet extends StatelessWidget {
  const _EventDetailSheet({
    required this.event,
    required this.calendar,
    required this.onEdit,
  });

  final PlannerEvent event;
  final PlannerCalendar calendar;
  final VoidCallback onEdit;

  void _shareCountdown(BuildContext context) {
    final days = _daysUntil;
    final isPast = days < 0;
    final isToday = days == 0;
    final countdownText = isToday
        ? 'TODAY'
        : isPast
            ? '${days.abs()} day${days.abs() == 1 ? '' : 's'} ago'
            : '$days day${days == 1 ? '' : 's'}';
    final message = '${event.title}\n'
        '${event.timeRange}\n'
        'Countdown: $countdownText';
    Share.share(message, subject: event.title);
  }

  int get _daysUntil {
    final now = DateTime.now();
    final start = DateTime(
      event.startAt.year,
      event.startAt.month,
      event.startAt.day,
    );
    final today = DateTime(now.year, now.month, now.day);
    return start.difference(today).inDays;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final days = _daysUntil;
    final isPast = days < 0;
    final isToday = days == 0;

    final tones = context.plannerTones;
    return FractionallySizedBox(
      heightFactor: 0.82,
      child: Container(
        decoration: BoxDecoration(
          color: tones.scaffold,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 46,
                    height: 4,
                    decoration: BoxDecoration(
                      color: tones.mutedInk.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: calendar.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      calendar.name.toUpperCase(),
                      style: textTheme.labelLarge?.copyWith(
                        color: tones.mutedInk,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: IconButton.styleFrom(
                        backgroundColor: tones.line,
                        foregroundColor: tones.ink,
                        fixedSize: const Size(38, 38),
                        padding: EdgeInsets.zero,
                      ),
                      icon: const Icon(Icons.close_rounded, size: 18),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  event.title,
                  style: textTheme.displayMedium?.copyWith(
                    fontSize: 32,
                    letterSpacing: -1,
                    color: tones.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  event.timeRange,
                  style: textTheme.titleMedium?.copyWith(
                    color: tones.mutedInk,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                // Countdown banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: isPast
                        ? tones.line
                        : isToday
                            ? AppColors.teal.withValues(alpha: 0.12)
                            : calendar.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isPast
                          ? tones.line
                          : isToday
                              ? AppColors.teal.withValues(alpha: 0.4)
                              : calendar.color.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'COUNTDOWN',
                            style: textTheme.labelLarge?.copyWith(
                              color: tones.mutedInk,
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isToday
                                ? 'TODAY'
                                : isPast
                                    ? '${days.abs()} DAY${days.abs() == 1 ? '' : 'S'} AGO'
                                    : '$days DAY${days == 1 ? '' : 'S'}',
                            style: textTheme.displayMedium?.copyWith(
                              fontSize: 26,
                              color: isPast
                                  ? tones.mutedInk
                                  : isToday
                                      ? AppColors.teal
                                      : calendar.color,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Icon(
                        isToday
                            ? Icons.today_rounded
                            : isPast
                                ? Icons.history_rounded
                                : Icons.hourglass_bottom_rounded,
                        size: 32,
                        color: isPast
                            ? tones.mutedInk
                            : isToday
                                ? AppColors.teal
                                : calendar.color,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (event.reminder != PlannerReminder.none)
                      _DetailChip(
                        icon: Icons.alarm_rounded,
                        label: event.reminder.label,
                        color: AppColors.coral,
                      ),
                    if (event.repeatRule != PlannerRepeatRule.never)
                      _DetailChip(
                        icon: Icons.repeat_rounded,
                        label: event.repeatRule.label,
                        color: AppColors.lilac,
                      ),
                    if (event.attendees.isNotEmpty)
                      _DetailChip(
                        icon: Icons.group_rounded,
                        label: event.attendees.length == 1
                            ? event.attendees.first
                            : '${event.attendees.length} people',
                        color: AppColors.teal,
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    children: [
                      if (event.location.isNotEmpty)
                        _DetailRow(
                          icon: Icons.place_rounded,
                          title: 'Location',
                          value: event.location,
                          accentColor: AppColors.coral,
                        ),
                      if (event.attendees.isNotEmpty)
                        _DetailRow(
                          icon: Icons.people_alt_rounded,
                          title: 'People',
                          value: event.attendees.join(', '),
                          accentColor: AppColors.teal,
                        ),
                      if (event.url.isNotEmpty)
                        _DetailRow(
                          icon: Icons.link_rounded,
                          title: 'URL',
                          value: event.url,
                          accentColor: AppColors.teal,
                        ),
                      if (event.note.isNotEmpty)
                        _DetailRow(
                          icon: Icons.notes_rounded,
                          title: 'Notes',
                          value: event.note,
                          accentColor: AppColors.mutedInk,
                        ),
                      if (event.location.isEmpty &&
                          event.url.isEmpty &&
                          event.note.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Text(
                              'No additional details',
                              style: textTheme.bodyMedium,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onEdit();
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: tones.ink,
                      foregroundColor: tones.scaffold,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    icon: const Icon(Icons.edit_rounded, size: 18),
                    label: const Text('Edit Event'),
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => _shareCountdown(context),
                    style: TextButton.styleFrom(
                      foregroundColor: tones.mutedInk,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'SHARE WITH A FRIEND',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
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
class _DetailChip extends StatelessWidget {
  const _DetailChip({
    required this.icon,
    required this.label,
    this.color,
  });

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tones = context.plannerTones;
    final chipColor = color ?? tones.mutedInk;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: chipColor.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: chipColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: tones.ink,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.title,
    required this.value,
    this.accentColor,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final tones = context.plannerTones;
    final color = accentColor ?? tones.mutedInk;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tones.surfaceRaised,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tones.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: tones.mutedInk,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 4),
                Text(value, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: tones.ink)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
