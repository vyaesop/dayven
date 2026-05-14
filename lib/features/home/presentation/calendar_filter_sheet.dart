import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../domain/planner_models.dart';

Future<void> showCalendarFilterSheet({
  required BuildContext context,
  required PlannerState state,
  required ValueChanged<String> onToggleCalendar,
  required VoidCallback onShowAll,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _CalendarFilterSheet(
      state: state,
      onToggleCalendar: onToggleCalendar,
      onShowAll: onShowAll,
    ),
  );
}

class _CalendarFilterSheet extends StatelessWidget {
  const _CalendarFilterSheet({
    required this.state,
    required this.onToggleCalendar,
    required this.onShowAll,
  });

  final PlannerState state;
  final ValueChanged<String> onToggleCalendar;
  final VoidCallback onShowAll;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return FractionallySizedBox(
      heightFactor: 0.72,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.charcoal,
          borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 54,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Text(
                      'CALENDARS',
                      style: textTheme.displayMedium?.copyWith(
                        color: Colors.white,
                        fontSize: 24,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: onShowAll,
                      child: const Text('Show all'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Choose which calendars are visible in the timeline and month heatmap.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 22),
                Expanded(
                  child: ListView.separated(
                    itemCount: state.calendars.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final calendar = state.calendars[index];
                      final isVisible = state.isCalendarVisible(calendar.id);
                      return InkWell(
                        onTap: () => onToggleCalendar(calendar.id),
                        borderRadius: BorderRadius.circular(22),
                        child: Ink(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: calendar.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  calendar.name,
                                  style: textTheme.bodyLarge?.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              Icon(
                                isVisible
                                    ? Icons.check_circle_rounded
                                    : Icons.radio_button_unchecked_rounded,
                                color: isVisible
                                    ? const Color(0xFFE1C06C)
                                    : Colors.white54,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
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
