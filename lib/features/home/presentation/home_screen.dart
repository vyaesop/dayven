import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/storage/storage_mode.dart';
import '../../account/application/local_account_controller.dart';
import '../../bootstrap/application/app_bootstrap_controller.dart';
import '../../menu/presentation/planner_feature_screens.dart';
import '../../preferences/application/app_preferences_controller.dart';
import '../application/planner_controller.dart';
import '../domain/planner_models.dart';
import 'calendar_filter_sheet.dart';
import 'event_detail_sheet.dart';
import 'event_editor_sheet.dart';
import 'month_overview_sheet.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plannerState = ref.watch(plannerControllerProvider);

    return Scaffold(
      drawer: const _PlannerMenu(),
      body: plannerState.when(
        data: (state) => _HomeLoaded(state: state),
        loading: () => const _HomeLoading(),
        error: (error, stackTrace) => _HomeError(error: error.toString()),
      ),
    );
  }
}

class _HomeLoaded extends ConsumerStatefulWidget {
  const _HomeLoaded({required this.state});

  final PlannerState state;

  @override
  ConsumerState<_HomeLoaded> createState() => _HomeLoadedState();
}

class _HomeLoadedState extends ConsumerState<_HomeLoaded> {
  bool? _hourlyViewOverride;

  PlannerState get state => widget.state;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final controller = ref.read(plannerControllerProvider.notifier);
    final preferences =
        ref.watch(appPreferencesControllerProvider).asData?.value ??
        AppPreferences.defaults();
    final dayEvents = state.selectedDayEvents
        .where((event) => preferences.showAllDay || !event.isAllDay)
        .toList();
    final colorCard = preferences.matchTimelineColors;
    final isHourlyView =
        _hourlyViewOverride ?? preferences.timelineLayoutMode == 'Day Hourly';
    final preferenceController = ref.read(
      appPreferencesControllerProvider.notifier,
    );
    final accent = preferences.accentPalette.color;
    final tones = context.plannerTones;
    final timelineSurfaceColor = _timelineSurfaceColor(
      context,
      preferences,
      state.selectedDate,
      accent,
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TimelineRail(
              monthLabel: state.monthLabel,
              days: state.railDaysFor(preferences.daysAtAGlance),
              selectedDate: state.selectedDate,
              accent: accent,
              onDaySelected: controller.selectDate,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                children: [
                  Row(
                    children: [
                      Builder(
                        builder: (context) {
                          return IconButton(
                            onPressed: () => Scaffold.of(context).openDrawer(),
                            style: IconButton.styleFrom(
                              backgroundColor: tones.surfaceRaised.withValues(
                                alpha: 0.92,
                              ),
                              foregroundColor: tones.ink,
                              fixedSize: const Size(42, 42),
                            ),
                            icon: const Icon(Icons.menu_rounded),
                          );
                        },
                      ),
                      const Spacer(),
                      Text(
                        'TODAY',
                        style: textTheme.labelLarge?.copyWith(
                          color: tones.mutedInk,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: controller.jumpToToday,
                        style: IconButton.styleFrom(
                          backgroundColor: tones.surfaceRaised.withValues(
                            alpha: 0.92,
                          ),
                          foregroundColor: tones.ink,
                          fixedSize: const Size(42, 42),
                        ),
                        icon: const Icon(Icons.today_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: timelineSurfaceColor,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: tones.shadow,
                            blurRadius: 28,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 24, 20, 96),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  state.selectedDateHeadline,
                                  style: textTheme.displayMedium?.copyWith(
                                    fontSize: 26,
                                    letterSpacing: -0.9,
                                    color: tones.ink,
                                  ),
                                ),
                                Text(
                                  state.selectedDateSubhead,
                                  style: textTheme.labelLarge?.copyWith(
                                    color: tones.mutedInk,
                                  ),
                                ),
                                if (preferences.showWeather) ...[
                                  const SizedBox(height: 14),
                                  _OfflineBriefingCard(
                                    date: state.selectedDate,
                                    events: dayEvents,
                                    preferences: preferences,
                                  ),
                                ],
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    Text(
                                      'SCHEDULE',
                                      style: textTheme.labelLarge?.copyWith(
                                        color: tones.mutedInk,
                                      ),
                                    ),
                                    const Spacer(),
                                    GestureDetector(
                                      onTap: () {
                                        final nextHourly = !isHourlyView;
                                        setState(() {
                                          _hourlyViewOverride = nextHourly;
                                        });
                                        preferenceController
                                            .setStringPreference(
                                              PreferenceKeys.timelineLayoutMode,
                                              nextHourly
                                                  ? 'Day Hourly'
                                                  : 'Traditional',
                                            );
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isHourlyView
                                              ? tones.ink
                                              : tones.line,
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              isHourlyView
                                                  ? Icons.access_time_rounded
                                                  : Icons.view_agenda_rounded,
                                              size: 12,
                                              color: isHourlyView
                                                  ? tones.surface
                                                  : tones.mutedInk,
                                            ),
                                            const SizedBox(width: 5),
                                            Text(
                                              isHourlyView ? 'Hourly' : 'List',
                                              style: textTheme.labelSmall
                                                  ?.copyWith(
                                                    color: isHourlyView
                                                        ? tones.surface
                                                        : tones.mutedInk,
                                                    fontSize: 10,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Expanded(
                                  child: dayEvents.isEmpty
                                      ? const _EmptyDayState()
                                      : isHourlyView
                                      ? _HourlyTimeline(
                                          events: dayEvents,
                                          state: state,
                                          colorCard: colorCard,
                                          selectedDate: state.selectedDate,
                                          onEventTap: (event) {
                                            final cal = state.calendarById(
                                              event.calendarId,
                                            );
                                            _openEventDetailSheet(
                                              context,
                                              ref,
                                              event,
                                              cal,
                                              state,
                                            );
                                          },
                                        )
                                      : ListView.separated(
                                          physics:
                                              const BouncingScrollPhysics(),
                                          itemCount: dayEvents.length,
                                          separatorBuilder: (_, _) =>
                                              const SizedBox(height: 14),
                                          itemBuilder: (context, index) {
                                            final event = dayEvents[index];
                                            final calendar = state.calendarById(
                                              event.calendarId,
                                            );
                                            return _EventCard(
                                              event: event,
                                              calendar: calendar,
                                              colorCard: colorCard,
                                              onTap: () =>
                                                  _openEventDetailSheet(
                                                    context,
                                                    ref,
                                                    event,
                                                    calendar,
                                                    state,
                                                  ),
                                            );
                                          },
                                        ),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 20,
                            child: _BottomPlannerBar(
                              onPrevDay: () => controller.selectDate(
                                state.selectedDate.subtract(
                                  const Duration(days: 1),
                                ),
                              ),
                              onNextDay: () => controller.selectDate(
                                state.selectedDate.add(const Duration(days: 1)),
                              ),
                              onMonthPressed: () => showMonthOverviewSheet(
                                context: context,
                                state: state,
                                onDateSelected: controller.selectDate,
                              ),
                              onTodayPressed: controller.jumpToToday,
                              onFilterPressed: () => showCalendarFilterSheet(
                                context: context,
                                state: state,
                                onToggleCalendar:
                                    controller.toggleCalendarVisibility,
                                onShowAll: controller.setAllCalendarsVisible,
                              ),
                            ),
                          ),
                          if (preferences.showActions)
                            Positioned(
                              right: 18,
                              bottom: 82,
                              child: FloatingActionButton.small(
                                onPressed: () =>
                                    _openCreateEventSheet(context, ref, state),
                                elevation: 0,
                                backgroundColor: tones.surfaceRaised,
                                foregroundColor: tones.ink,
                                child: const Icon(Icons.add_rounded),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _timelineSurfaceColor(
    BuildContext context,
    AppPreferences preferences,
    DateTime selectedDate,
    Color accent,
  ) {
    final base = Theme.of(context).colorScheme.surface;
    final today = DateTime.now();
    final selected = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );
    final normalizedToday = DateTime(today.year, today.month, today.day);
    final isToday = selected == normalizedToday;
    final isPast = selected.isBefore(normalizedToday);
    final isWeekend =
        selectedDate.weekday == DateTime.saturday ||
        selectedDate.weekday == DateTime.sunday;
    final isAlternate = selectedDate.day.isEven;
    final strength = preferences.heavyShading ? 0.11 : 0.055;

    if (preferences.shadeToday && isToday) {
      return Color.alphaBlend(accent.withValues(alpha: strength), base);
    }
    if (preferences.shadePastDays && isPast) {
      return Color.alphaBlend(
        AppColors.graphite.withValues(alpha: strength),
        base,
      );
    }
    if (preferences.shadeWeekends && isWeekend) {
      return Color.alphaBlend(
        AppColors.lilac.withValues(alpha: strength),
        base,
      );
    }
    if (preferences.shadeAlternateDays && isAlternate) {
      return Color.alphaBlend(
        AppColors.teal.withValues(alpha: strength * 0.75),
        base,
      );
    }

    return base;
  }

  Future<void> _openCreateEventSheet(
    BuildContext context,
    WidgetRef ref,
    PlannerState state,
  ) {
    final defaultCalendarId = ref
        .read(appPreferencesControllerProvider)
        .asData
        ?.value
        .defaultCalendarId;
    return showEventEditorSheet(
      context: context,
      selectedDate: state.selectedDate,
      calendars: state.calendars,
      defaultCalendarId: defaultCalendarId,
      onCreate: ref.read(plannerControllerProvider.notifier).createEvent,
    );
  }

  Future<void> _openEditEventSheet(
    BuildContext context,
    WidgetRef ref,
    PlannerEvent event,
    PlannerState state,
  ) {
    final controller = ref.read(plannerControllerProvider.notifier);
    return showEventEditorSheet(
      context: context,
      selectedDate: state.selectedDate,
      calendars: state.calendars,
      defaultCalendarId: ref
          .read(appPreferencesControllerProvider)
          .asData
          ?.value
          .defaultCalendarId,
      initialEvent: event,
      onUpdate: controller.updateEvent,
      onDelete: controller.deleteEvent,
    );
  }

  Future<void> _openEventDetailSheet(
    BuildContext context,
    WidgetRef ref,
    PlannerEvent event,
    PlannerCalendar calendar,
    PlannerState state,
  ) {
    return showEventDetailSheet(
      context: context,
      event: event,
      calendar: calendar,
      onEdit: () => _openEditEventSheet(context, ref, event, state),
    );
  }
}

class _TimelineRail extends StatelessWidget {
  const _TimelineRail({
    required this.monthLabel,
    required this.days,
    required this.selectedDate,
    required this.accent,
    required this.onDaySelected,
  });

  final String monthLabel;
  final List<PlannerDay> days;
  final DateTime selectedDate;
  final Color accent;
  final ValueChanged<DateTime> onDaySelected;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      width: 58,
      child: Column(
        children: [
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: context.plannerTones.rail,
                borderRadius: BorderRadius.circular(32),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x2818171A),
                    blurRadius: 20,
                    offset: Offset(2, 6),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            width: 18,
                            child: Center(
                              child: RotatedBox(
                                quarterTurns: 3,
                                child: Text(
                                  monthLabel,
                                  style: textTheme.labelLarge?.copyWith(
                                    color: Color.lerp(
                                      accent,
                                      Colors.white,
                                      0.18,
                                    ),
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                for (final day in days)
                                  _RailDayChip(
                                    day: day,
                                    isSelected: _sameDay(
                                      day.date,
                                      selectedDate,
                                    ),
                                    accent: accent,
                                    onTap: () => onDaySelected(day.date),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _RailDayChip extends StatelessWidget {
  const _RailDayChip({
    required this.day,
    required this.isSelected,
    required this.accent,
    required this.onTap,
  });

  final PlannerDay day;
  final bool isSelected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            day.label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: day.isToday ? accent : Colors.white.withValues(alpha: 0.6),
              fontSize: 9,
            ),
          ),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.white
                  : day.isToday
                  ? accent.withValues(alpha: 0.22)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              '${day.dayNumber}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isSelected
                    ? AppColors.ink
                    : day.isToday
                    ? accent
                    : Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OfflineBriefingCard extends StatelessWidget {
  const _OfflineBriefingCard({
    required this.date,
    required this.events,
    required this.preferences,
  });

  final DateTime date;
  final List<PlannerEvent> events;
  final AppPreferences preferences;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final tones = context.plannerTones;
    final weather = _offlineWeatherFor(date);
    final firstLocation = events
        .map((event) => event.location.trim())
        .firstWhere((location) => location.isNotEmpty, orElse: () => '');
    final nextTimedEvent = events
        .where((event) => !event.isAllDay)
        .cast<PlannerEvent?>()
        .firstWhere((event) => event != null, orElse: () => null);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tones.surfaceRaised.withValues(alpha: tones.isDark ? 0.55 : 0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tones.line.withValues(alpha: 0.7)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: weather.color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(weather.icon, color: weather.color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${weather.temperature}°, ${weather.summary}',
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _briefingLine(firstLocation, nextTimedEvent),
                  style: textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (preferences.travelAlerts && firstLocation.isNotEmpty) ...[
            const SizedBox(width: 8),
            Column(
              children: [
                Icon(
                  _travelIcon(preferences.travelMode),
                  color: tones.mutedInk,
                  size: 18,
                ),
                const SizedBox(height: 3),
                Text(
                  preferences.travelMode,
                  style: textTheme.labelLarge?.copyWith(
                    color: tones.mutedInk,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _briefingLine(String firstLocation, PlannerEvent? nextTimedEvent) {
    final locationPart = firstLocation.isEmpty
        ? 'No saved location yet'
        : 'Near $firstLocation';
    if (nextTimedEvent == null) {
      return '$locationPart. Offline daily briefing.';
    }

    return '$locationPart. Next: ${nextTimedEvent.title}.';
  }

  _OfflineWeather _offlineWeatherFor(DateTime date) {
    final seed = (date.year + date.month * 7 + date.day * 13) % 4;
    return switch (seed) {
      0 => const _OfflineWeather(
        icon: Icons.wb_sunny_rounded,
        color: AppColors.gold,
        temperature: 72,
        summary: 'clear',
      ),
      1 => const _OfflineWeather(
        icon: Icons.cloud_rounded,
        color: AppColors.lilac,
        temperature: 66,
        summary: 'cloudy',
      ),
      2 => const _OfflineWeather(
        icon: Icons.water_drop_rounded,
        color: AppColors.teal,
        temperature: 61,
        summary: 'light rain',
      ),
      _ => const _OfflineWeather(
        icon: Icons.air_rounded,
        color: AppColors.sage,
        temperature: 69,
        summary: 'breezy',
      ),
    };
  }

  IconData _travelIcon(String mode) {
    return switch (mode) {
      'Walking' => Icons.directions_walk_rounded,
      'Bicycling' || 'Cycling' => Icons.directions_bike_rounded,
      'Transit' => Icons.directions_bus_rounded,
      _ => Icons.directions_car_filled_rounded,
    };
  }
}

class _OfflineWeather {
  const _OfflineWeather({
    required this.icon,
    required this.color,
    required this.temperature,
    required this.summary,
  });

  final IconData icon;
  final Color color;
  final int temperature;
  final String summary;
}

/// Pick a foreground (text/icon) color that reads cleanly on top of [bg].
/// Used by event cards when the card itself is painted in the calendar's color.
Color _onColor(Color bg) {
  final lum = 0.299 * bg.r + 0.587 * bg.g + 0.114 * bg.b;
  return lum > 0.62 ? const Color(0xFF18171A) : Colors.white;
}

class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.event,
    required this.calendar,
    required this.colorCard,
    required this.onTap,
    this.compact = false,
    this.suppressLeftBar = false,
  });

  final PlannerEvent event;
  final PlannerCalendar calendar;
  final bool colorCard;
  final VoidCallback onTap;
  final bool compact;
  final bool suppressLeftBar;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final tones = context.plannerTones;
    // The card always sits one tonal step above the timeline panel so it
    // separates in every theme: brighter than `surface` in light modes, lighter
    // than `surface` in dark mode.
    final bg = colorCard ? calendar.color : tones.surfaceRaised;
    // Pick title color by contrast against the actual card bg, not by mode.
    final onBg = colorCard ? _onColor(calendar.color) : tones.ink;
    final onBgMuted = colorCard
        ? _onColor(calendar.color).withValues(alpha: 0.75)
        : tones.mutedInk;
    final showLeftBar = !colorCard && !suppressLeftBar;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Ink(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(22),
          border: !colorCard && tones.isDark
              ? Border.all(color: tones.line, width: 0.6)
              : null,
          boxShadow: [
            BoxShadow(
              color: colorCard
                  ? calendar.color.withValues(alpha: 0.38)
                  : tones.shadow,
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showLeftBar)
                Container(
                  width: 5,
                  height: 56,
                  decoration: BoxDecoration(
                    color: calendar.color,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              if (showLeftBar) const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: textTheme.titleMedium?.copyWith(color: onBg),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      event.timeRange,
                      style: textTheme.bodyMedium?.copyWith(
                        color: onBg,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (event.location.isNotEmpty || !compact) ...[
                      const SizedBox(height: 2),
                      Text(
                        event.location.isEmpty ? calendar.name : event.location,
                        style: textTheme.bodyMedium?.copyWith(color: onBgMuted),
                      ),
                    ],
                    if (!compact) ...[
                      if (event.reminder != PlannerReminder.none ||
                          event.repeatRule != PlannerRepeatRule.never ||
                          event.attendees.isNotEmpty)
                        const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          if (event.reminder != PlannerReminder.none)
                            _MetaPill(
                              icon: Icons.alarm_rounded,
                              label: event.reminder.label,
                              colorCard: colorCard,
                            ),
                          if (event.repeatRule != PlannerRepeatRule.never)
                            _MetaPill(
                              icon: Icons.repeat_rounded,
                              label: event.repeatRule.label,
                              colorCard: colorCard,
                            ),
                          if (event.attendees.isNotEmpty)
                            _MetaPill(
                              icon: Icons.group_rounded,
                              label: event.attendees.length == 1
                                  ? event.attendees.first
                                  : '${event.attendees.length} people',
                              colorCard: colorCard,
                            ),
                        ],
                      ),
                      if (event.note.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          event.note,
                          style: textTheme.bodyMedium?.copyWith(
                            color: onBgMuted,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ],
                ),
              ),
              if (colorCard) ...[
                const SizedBox(width: 8),
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
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

// ─── Hourly Timeline ──────────────────────────────────────────────────────────

class _HourlyTimeline extends StatelessWidget {
  const _HourlyTimeline({
    required this.events,
    required this.state,
    required this.colorCard,
    required this.selectedDate,
    required this.onEventTap,
  });

  final List<PlannerEvent> events;
  final PlannerState state;
  final bool colorCard;
  final DateTime selectedDate;
  final void Function(PlannerEvent) onEventTap;

  static const _hourHeight = 64.0;
  // label(40) + gap(10) + divider(1) + gap(10)
  static const _barLeft = 61.0;
  static const _barWidth = 5.0;
  static const _cardLeft = _barLeft + _barWidth + 8.0;

  int get _startHour {
    final timedEvents = events.where((e) => !e.isAllDay).toList();
    if (timedEvents.isEmpty) return 8;
    final earliest = timedEvents
        .map((e) => e.startAt.hour)
        .fold(23, (a, b) => a < b ? a : b);
    return (earliest - 1).clamp(0, 23);
  }

  int get _endHour {
    final timedEvents = events.where((e) => !e.isAllDay).toList();
    if (timedEvents.isEmpty) return 20;
    final latest = timedEvents
        .map((e) => e.endAt.hour + (e.endAt.minute > 0 ? 1 : 0))
        .fold(0, (a, b) => a > b ? a : b);
    return (latest + 1).clamp(1, 24);
  }

  double _topFor(PlannerEvent e) {
    final offsetMinutes = (e.startAt.hour - _startHour) * 60 + e.startAt.minute;
    return offsetMinutes / 60 * _hourHeight;
  }

  double _barHeightFor(PlannerEvent e) {
    final minutes = e.endAt.difference(e.startAt).inMinutes;
    return (minutes / 60 * _hourHeight).clamp(
      _hourHeight * 0.375,
      24 * _hourHeight,
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isToday =
        selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day;
    final hours = List.generate(_endHour - _startHour, (i) => _startHour + i);
    final allDayEvents = events.where((e) => e.isAllDay).toList();
    final timedEvents = events.where((e) => !e.isAllDay).toList();
    final timelineHeight = (_endHour - _startHour) * _hourHeight;

    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        if (allDayEvents.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ALL DAY',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: context.plannerTones.mutedInk,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 6),
                for (final e in allDayEvents)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: _EventCard(
                      event: e,
                      calendar: state.calendarById(e.calendarId),
                      colorCard: colorCard,
                      compact: true,
                      onTap: () => onEventTap(e),
                    ),
                  ),
              ],
            ),
          ),
        ],
        SizedBox(
          height: timelineHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Hour grid: labels + vertical divider line
              Column(
                children: [for (final hour in hours) _HourGridRow(hour: hour)],
              ),
              // Duration bars — one per timed event, spans start→end
              for (final e in timedEvents)
                if (!colorCard)
                  Positioned(
                    left: _barLeft,
                    width: _barWidth,
                    top: _topFor(e),
                    height: _barHeightFor(e),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: state.calendarById(e.calendarId).color,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
              // Event cards positioned at start time
              for (final e in timedEvents)
                Positioned(
                  left: _cardLeft,
                  right: 8,
                  top: _topFor(e),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: _EventCard(
                      event: e,
                      calendar: state.calendarById(e.calendarId),
                      colorCard: colorCard,
                      compact: true,
                      suppressLeftBar: true,
                      onTap: () => onEventTap(e),
                    ),
                  ),
                ),
              // Current time indicator
              if (isToday && now.hour >= _startHour && now.hour < _endHour)
                Positioned(
                  top:
                      (now.hour - _startHour) * _hourHeight +
                      (now.minute / 60) * _hourHeight,
                  left: _barLeft - 10,
                  right: 0,
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.coral,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Expanded(
                        child: Container(height: 1.5, color: AppColors.coral),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HourGridRow extends StatelessWidget {
  const _HourGridRow({required this.hour});

  final int hour;

  String get _label {
    if (hour == 0) return '12\nAM';
    if (hour < 12) return '$hour\nAM';
    if (hour == 12) return '12\nPM';
    return '${hour - 12}\nPM';
  }

  @override
  Widget build(BuildContext context) {
    final tones = context.plannerTones;
    return SizedBox(
      height: _HourlyTimeline._hourHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 40,
            child: Text(
              _label,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: tones.mutedInk,
                fontSize: 10,
                height: 1.2,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(width: 1, color: tones.line),
        ],
      ),
    );
  }
}

class _BottomPlannerBar extends StatelessWidget {
  const _BottomPlannerBar({
    required this.onPrevDay,
    required this.onNextDay,
    required this.onMonthPressed,
    required this.onTodayPressed,
    required this.onFilterPressed,
  });

  final VoidCallback onPrevDay;
  final VoidCallback onNextDay;
  final VoidCallback onMonthPressed;
  final VoidCallback onTodayPressed;
  final VoidCallback onFilterPressed;

  @override
  Widget build(BuildContext context) {
    final tones = context.plannerTones;
    return Center(
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: tones.bottomBar.withValues(alpha: 0.97),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: tones.shadow,
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: IntrinsicWidth(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _BarButton(icon: Icons.chevron_left_rounded, onTap: onPrevDay),
              _BarButton(
                icon: Icons.access_time_rounded,
                onTap: onTodayPressed,
              ),
              _BarButton(icon: Icons.tune_rounded, onTap: onFilterPressed),
              _BarButton(
                icon: Icons.calendar_view_month_rounded,
                onTap: onMonthPressed,
              ),
              _BarButton(icon: Icons.chevron_right_rounded, onTap: onNextDay),
            ],
          ),
        ),
      ),
    );
  }
}

class _BarButton extends StatelessWidget {
  const _BarButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Icon(icon, color: context.plannerTones.ink, size: 22),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({
    required this.icon,
    required this.label,
    this.colorCard = false,
  });

  final IconData icon;
  final String label;
  final bool colorCard;

  @override
  Widget build(BuildContext context) {
    final tones = context.plannerTones;
    final bg = colorCard ? Colors.white.withValues(alpha: 0.2) : tones.line;
    final fg = colorCard ? Colors.white : tones.mutedInk;
    final textColor = colorCard ? Colors.white : tones.ink;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlannerMenu extends ConsumerWidget {
  const _PlannerMenu();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final storageMode = ref.watch(selectedStorageModeProvider).asData?.value;
    final account =
        ref.watch(localAccountControllerProvider).asData?.value ??
        LocalAccountState.defaults();
    final preferences =
        ref.watch(appPreferencesControllerProvider).asData?.value ??
        AppPreferences.defaults();
    final accent = preferences.accentPalette.color;
    final items = [
      PlannerMenuDestination.search,
      PlannerMenuDestination.rsvp,
      PlannerMenuDestination.calendars,
      PlannerMenuDestination.themes,
      PlannerMenuDestination.preferences,
      PlannerMenuDestination.smartAlerts,
      PlannerMenuDestination.textSize,
      PlannerMenuDestination.travel,
      PlannerMenuDestination.whatsNew,
      PlannerMenuDestination.welcome,
      PlannerMenuDestination.help,
      PlannerMenuDestination.account,
      // PlannerMenuDestination.paywall — hidden until RevenueCat billing is wired
    ];

    return Drawer(
      backgroundColor: Colors.transparent,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.76,
          margin: const EdgeInsets.only(left: 8, top: 10, bottom: 10),
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
          decoration: BoxDecoration(
            color: context.plannerTones.menuSurface,
            borderRadius: BorderRadius.circular(32),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${account.remainingTrialDays}',
                style: textTheme.displayMedium?.copyWith(
                  color: accent,
                  fontSize: 42,
                ),
              ),
              Text(
                account.hasPremiumPreview
                    ? 'Trial days remaining'
                    : 'Preview days remaining',
                style: textTheme.bodyMedium?.copyWith(color: Colors.white60),
              ),
              const SizedBox(height: 24),
              Text(
                'TIMEPAGE',
                style: textTheme.displayMedium?.copyWith(
                  fontSize: 30,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 18),
              if (storageMode != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        storageMode == StorageMode.localSqlite
                            ? Icons.phone_android_rounded
                            : Icons.cloud_outlined,
                        color: Colors.white70,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          storageMode.label,
                          style: textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              for (final item in items) ...[
                InkWell(
                  onTap: () {
                    Navigator.of(context).pop();
                    openPlannerMenuDestination(
                      context,
                      item,
                      storageMode: storageMode,
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        Icon(item.icon, color: Colors.white54, size: 18),
                        const SizedBox(width: 12),
                        Text(
                          item.label,
                          style: textTheme.bodyLarge?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
              ],
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () async {
                    await ref
                        .read(selectedStorageModeProvider.notifier)
                        .reset();
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.24),
                    ),
                  ),
                  child: const Text('Change Storage Mode'),
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.bottomRight,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Text(
                      account.initials,
                      style: textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyDayState extends StatelessWidget {
  const _EmptyDayState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Nothing booked yet',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Use the add button to create an event for this day.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeLoading extends StatelessWidget {
  const _HomeLoading();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(color: context.plannerTones.ink),
    );
  }
}

class _HomeError extends ConsumerWidget {
  const _HomeError({required this.error});

  final String error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              error,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => ref.invalidate(plannerControllerProvider),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
