import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_theme.dart';
import '../domain/planner_models.dart';

Future<void> showMonthOverviewSheet({
  required BuildContext context,
  required PlannerState state,
  required ValueChanged<DateTime> onDateSelected,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => _MonthOverviewSheet(
      state: state,
      onDateSelected: onDateSelected,
    ),
  );
}

class _MonthOverviewSheet extends StatefulWidget {
  const _MonthOverviewSheet({
    required this.state,
    required this.onDateSelected,
  });

  final PlannerState state;
  final ValueChanged<DateTime> onDateSelected;

  @override
  State<_MonthOverviewSheet> createState() => _MonthOverviewSheetState();
}

class _MonthOverviewSheetState extends State<_MonthOverviewSheet> {
  late DateTime _focusedMonth;

  @override
  void initState() {
    super.initState();
    _focusedMonth = DateTime(
      widget.state.focusedMonth.year,
      widget.state.focusedMonth.month,
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final accent = Theme.of(context).colorScheme.secondary;
    final monthDays = _buildMonthDays(_focusedMonth);
    final eventCountByDay = <int, int>{};

    for (final event in widget.state.filteredEvents) {
      if (event.startAt.year == _focusedMonth.year &&
          event.startAt.month == _focusedMonth.month) {
        eventCountByDay[event.startAt.day] =
            (eventCountByDay[event.startAt.day] ?? 0) + 1;
      }
    }

    final monthEvents = widget.state.filteredEvents
        .where((event) =>
            event.startAt.year == _focusedMonth.year &&
            event.startAt.month == _focusedMonth.month)
        .toList()
      ..sort((a, b) => a.startAt.compareTo(b.startAt));

    final today = DateTime.now();
    final isCurrentMonth = _focusedMonth.year == today.year &&
        _focusedMonth.month == today.month;

    return FractionallySizedBox(
      heightFactor: 0.85,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.charcoal,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 40,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 46,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _MonthNavButton(
                      icon: Icons.chevron_left_rounded,
                      onTap: _previousMonth,
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            DateFormat('MMMM').format(_focusedMonth).toUpperCase(),
                            textAlign: TextAlign.center,
                            style: textTheme.displayMedium?.copyWith(
                              color: accent,
                              fontSize: 28,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            '${_focusedMonth.year}',
                            textAlign: TextAlign.center,
                            style: textTheme.labelLarge?.copyWith(
                              color: Colors.white38,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _MonthNavButton(
                      icon: Icons.chevron_right_rounded,
                      onTap: _nextMonth,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: const [
                    _MonthWeekdayLabel('S'),
                    _MonthWeekdayLabel('M'),
                    _MonthWeekdayLabel('T'),
                    _MonthWeekdayLabel('W'),
                    _MonthWeekdayLabel('T'),
                    _MonthWeekdayLabel('F'),
                    _MonthWeekdayLabel('S'),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  flex: 5,
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: monthDays.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      mainAxisSpacing: 6,
                      crossAxisSpacing: 4,
                      childAspectRatio: 1,
                    ),
                    itemBuilder: (context, index) {
                      final day = monthDays[index];
                      if (day == null) {
                        return const SizedBox.shrink();
                      }

                      final isSelected = day.day == widget.state.selectedDate.day &&
                          day.month == widget.state.selectedDate.month &&
                          day.year == widget.state.selectedDate.year;
                      final isToday = isCurrentMonth && day.day == today.day;
                      final eventCount = eventCountByDay[day.day] ?? 0;

                      return GestureDetector(
                        onTap: () {
                          widget.onDateSelected(day);
                          Navigator.of(context).pop();
                        },
                        child: _MonthDayCell(
                          day: day.day,
                          isSelected: isSelected,
                          isToday: isToday,
                          eventCount: eventCount,
                          textTheme: textTheme,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'THIS MONTH',
                      style: textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.teal.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${monthEvents.length} event${monthEvents.length == 1 ? '' : 's'}',
                        style: textTheme.labelLarge?.copyWith(
                          color: AppColors.teal,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  flex: 3,
                  child: monthEvents.isEmpty
                      ? Center(
                          child: Text(
                            'No events this month',
                            style: textTheme.bodyMedium?.copyWith(
                              color: Colors.white38,
                            ),
                          ),
                        )
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          itemCount: monthEvents.length,
                          itemBuilder: (context, index) {
                            final event = monthEvents[index];
                            final calendar = widget.state.calendarById(event.calendarId);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: calendar.color,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          event.title,
                                          style: textTheme.bodyLarge?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          '${DateFormat('EEE d MMM').format(event.startAt)}  ·  ${event.timeRange}',
                                          style: textTheme.bodyMedium?.copyWith(
                                            color: Colors.white54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
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

  void _previousMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
    });
  }

  List<DateTime?> _buildMonthDays(DateTime date) {
    final firstOfMonth = DateTime(date.year, date.month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(date.year, date.month);
    final leadingBlankCount = firstOfMonth.weekday % 7;
    final result = <DateTime?>[
      for (var i = 0; i < leadingBlankCount; i++) null,
      for (var day = 1; day <= daysInMonth; day++)
        DateTime(date.year, date.month, day),
    ];

    while (result.length < 35) {
      result.add(null);
    }

    return result;
  }
}

class _MonthNavButton extends StatelessWidget {
  const _MonthNavButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}

class _MonthDayCell extends StatelessWidget {
  const _MonthDayCell({
    required this.day,
    required this.isSelected,
    required this.isToday,
    required this.eventCount,
    required this.textTheme,
  });

  final int day;
  final bool isSelected;
  final bool isToday;
  final int eventCount;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;
    Color? bgColor;
    Color textColor = Colors.white;

    if (isSelected) {
      bgColor = Colors.white;
      textColor = AppColors.charcoal;
    } else if (isToday) {
      bgColor = accent.withValues(alpha: 0.25);
      textColor = accent;
    } else if (eventCount > 0) {
      bgColor = _heatColor(eventCount);
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
            border: isToday && !isSelected
                ? Border.all(color: accent, width: 1.5)
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            '$day',
            style: textTheme.bodyMedium?.copyWith(
              color: textColor,
              fontWeight: isSelected || isToday ? FontWeight.w800 : FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
        if (eventCount > 0 && !isSelected) ...[
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < eventCount.clamp(1, 3); i++) ...[
                if (i > 0) const SizedBox(width: 2),
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _dotColor(i),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Color _heatColor(int count) {
    if (count >= 4) return AppColors.teal.withValues(alpha: 0.35);
    if (count >= 2) return AppColors.coral.withValues(alpha: 0.28);
    return AppColors.lilac.withValues(alpha: 0.22);
  }

  Color _dotColor(int index) {
    final colors = [AppColors.teal, AppColors.coral, AppColors.lilac];
    return colors[index % colors.length];
  }
}

class _MonthWeekdayLabel extends StatelessWidget {
  const _MonthWeekdayLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Colors.white54,
            ),
      ),
    );
  }
}
