import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/ai/ai_event_service.dart';
import '../../../core/weather/weather_service.dart';
import '../../../core/auth/firebase_auth_service.dart';
import '../../account/application/local_account_controller.dart';
import '../../menu/presentation/planner_feature_screens.dart';
import '../../preferences/application/app_preferences_controller.dart';
import '../application/planner_controller.dart';
import '../domain/planner_models.dart';
import 'ai_capture_sheet.dart';
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

/// The three ways the day's schedule can be rendered.
// v1 ships two timeline layouts: Cards (traditional) and Hourly. The legacy
// "Multi-line" list view was dropped to keep one strong default + one
// alternative; the persisted value 'Multi-line' falls back to Cards.
enum _TimelineLayout { traditional, hourly }

_TimelineLayout _layoutFromPref(String value) => switch (value) {
      'Day Hourly' => _TimelineLayout.hourly,
      _ => _TimelineLayout.traditional,
    };

String _layoutToPref(_TimelineLayout layout) => switch (layout) {
      _TimelineLayout.hourly => 'Day Hourly',
      _TimelineLayout.traditional => 'Traditional',
    };

extension _TimelineLayoutX on _TimelineLayout {
  _TimelineLayout get next => switch (this) {
        _TimelineLayout.traditional => _TimelineLayout.hourly,
        _TimelineLayout.hourly => _TimelineLayout.traditional,
      };

  String get label => switch (this) {
        _TimelineLayout.traditional => 'Cards',
        _TimelineLayout.hourly => 'Hourly',
      };

  IconData get icon => switch (this) {
        _TimelineLayout.traditional => Icons.view_agenda_rounded,
        _TimelineLayout.hourly => Icons.access_time_rounded,
      };
}

class _HomeLoadedState extends ConsumerState<_HomeLoaded> {
  _TimelineLayout? _layoutOverride;

  PlannerState get state => widget.state;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowWelcome());
  }

  /// On the very first launch (after storage selection) show the welcome tour
  /// once, so the onboarding isn't stranded in the menu where users never see it.
  Future<void> _maybeShowWelcome() async {
    const key = 'has_seen_welcome_v1';
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(key) ?? false) return;
    await prefs.setBool(key, true);
    if (!mounted) return;
    openPlannerMenuDestination(context, PlannerMenuDestination.welcome);
  }

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
    final layout = _layoutOverride ??
        _layoutFromPref(preferences.timelineLayoutMode);
    final preferenceController = ref.read(
      appPreferencesControllerProvider.notifier,
    );
    final accent = preferences.accentPalette.color;
    final tones = context.plannerTones;
    final aiAvailable = ref.watch(aiCaptureAvailableProvider);
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
              days: state.railRangeDays(),
              visibleCount: preferences.daysAtAGlance.clamp(3, 10),
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
                            tooltip: 'Open menu',
                            style: IconButton.styleFrom(
                              backgroundColor: tones.surfaceRaised.withValues(
                                alpha: 0.92,
                              ),
                              foregroundColor: tones.ink,
                              fixedSize: const Size(44, 44),
                            ),
                            icon: const Icon(Icons.menu_rounded),
                          );
                        },
                      ),
                      const Spacer(),
                      Text(
                        'DAYVEN',
                        style: textTheme.labelLarge?.copyWith(
                          color: tones.mutedInk,
                        ),
                      ),
                      const Spacer(),
                      if (aiAvailable) ...[
                        IconButton(
                          onPressed: () =>
                              _openAiCaptureSheet(context, ref, state),
                          tooltip: 'Add with AI',
                          style: IconButton.styleFrom(
                            backgroundColor: tones.surfaceRaised.withValues(
                              alpha: 0.92,
                            ),
                            foregroundColor: accent,
                            fixedSize: const Size(44, 44),
                          ),
                          icon: const Icon(Icons.auto_awesome_rounded),
                        ),
                        const SizedBox(width: 8),
                      ],
                      IconButton(
                        onPressed: controller.jumpToToday,
                        tooltip: 'Jump to today',
                        style: IconButton.styleFrom(
                          backgroundColor: tones.surfaceRaised.withValues(
                            alpha: 0.92,
                          ),
                          foregroundColor: tones.ink,
                          fixedSize: const Size(44, 44),
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
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(32),
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
                                Builder(
                                  builder: (context) {
                                    final secondary = preferences
                                        .secondaryCalendar
                                        .labelFor(state.selectedDate);
                                    if (secondary == null) {
                                      return const SizedBox.shrink();
                                    }
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 3),
                                      child: Text(
                                        secondary,
                                        style: textTheme.labelSmall?.copyWith(
                                          color: tones.mutedInk,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                // Weather is only meaningful for today, so the
                                // briefing is shown for the current day only
                                // (rather than implying a forecast for any
                                // arbitrary future/past date).
                                if (preferences.showWeather &&
                                    _isSameDay(
                                      state.selectedDate,
                                      DateTime.now(),
                                    )) ...[
                                  const SizedBox(height: 14),
                                  _WeatherBriefingCard(
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
                                    Tooltip(
                                      message:
                                          'Switch layout (currently ${layout.label})',
                                      child: Semantics(
                                        button: true,
                                        label:
                                            'Switch schedule layout, currently ${layout.label}',
                                        child: GestureDetector(
                                          onTap: () {
                                            final nextLayout = layout.next;
                                            setState(() {
                                              _layoutOverride = nextLayout;
                                            });
                                            preferenceController
                                                .setStringPreference(
                                                  PreferenceKeys
                                                      .timelineLayoutMode,
                                                  _layoutToPref(nextLayout),
                                                );
                                          },
                                          behavior: HitTestBehavior.opaque,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: tones.surfaceSoft,
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                              border:
                                                  Border.all(color: tones.line),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  layout.icon,
                                                  size: 13,
                                                  color: tones.ink,
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  layout.label,
                                                  style: textTheme.labelSmall
                                                      ?.copyWith(
                                                        color: tones.ink,
                                                        fontSize: 11,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Expanded(
                                  child: ClipRect(
                                    child: dayEvents.isEmpty
                                        ? _EmptyDayState(
                                            onAddEvent: () =>
                                                _openCreateEventSheet(
                                                  context,
                                                  ref,
                                                  state,
                                                ),
                                            onAddWithAi: aiAvailable
                                                ? () => _openAiCaptureSheet(
                                                      context,
                                                      ref,
                                                      state,
                                                    )
                                                : null,
                                          )
                                        : switch (layout) {
                                            _TimelineLayout.hourly =>
                                              _HourlyTimeline(
                                                events: dayEvents,
                                                state: state,
                                                colorCard: colorCard,
                                                selectedDate:
                                                    state.selectedDate,
                                                onEventTap: (event) =>
                                                    _openEventDetailSheet(
                                                      context,
                                                      ref,
                                                      event,
                                                      state.calendarById(
                                                        event.calendarId,
                                                      ),
                                                      state,
                                                    ),
                                              ),
                                            _TimelineLayout.traditional =>
                                              ListView.separated(
                                                physics:
                                                    const BouncingScrollPhysics(),
                                                itemCount: dayEvents.length,
                                                separatorBuilder: (_, _) =>
                                                    const SizedBox(height: 14),
                                                itemBuilder: (context, index) {
                                                  final event =
                                                      dayEvents[index];
                                                  final calendar =
                                                      state.calendarById(
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
                                onToggleCalendar:
                                    controller.toggleCalendarVisibility,
                                onShowAll: controller.setAllCalendarsVisible,
                                onCreateCalendar: controller.createCalendar,
                                onLoadHolidays:
                                    controller.loadHolidaysForCountry,
                              ),
                              onAddEvent: () =>
                                  _openCreateEventSheet(context, ref, state),
                            ),
                          ),
                        ],
                      ),
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
    final controller = ref.read(plannerControllerProvider.notifier);
    return showEventEditorSheet(
      context: context,
      selectedDate: state.selectedDate,
      calendars: state.calendars,
      defaultCalendarId: defaultCalendarId,
      onCreate: controller.createEvent,
    );
  }

  /// AI quick-capture: describe an event in words, parse it via the backend,
  /// then open the editor prefilled so the user reviews before it's saved.
  Future<void> _openAiCaptureSheet(
    BuildContext context,
    WidgetRef ref,
    PlannerState state,
  ) async {
    final defaultCalendarId = ref
        .read(appPreferencesControllerProvider)
        .asData
        ?.value
        .defaultCalendarId;
    final draft = await showAiCaptureSheet(
      context: context,
      calendars: state.calendars,
      selectedDate: state.selectedDate,
      defaultCalendarId: defaultCalendarId,
    );
    if (draft == null || !context.mounted) return;
    final controller = ref.read(plannerControllerProvider.notifier);
    await showEventEditorSheet(
      context: context,
      selectedDate: state.selectedDate,
      calendars: state.calendars,
      defaultCalendarId: defaultCalendarId,
      initialDraft: draft,
      onCreate: controller.createEvent,
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
      onCreate: controller.createEvent,
      onUpdate: controller.updateEvent,
      onDelete: controller.deleteEvent,
      onEditSeriesAll: (template) =>
          controller.editSeriesAll(template.id, template),
      onExcludeOccurrence: controller.excludeOccurrence,
      onEditSeriesFollowing: (template, fromDate) =>
          controller.editSeriesFollowing(template.id, fromDate, template),
      onTruncateSeries: controller.truncateSeriesFrom,
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

class _TimelineRail extends StatefulWidget {
  const _TimelineRail({
    required this.monthLabel,
    required this.days,
    required this.visibleCount,
    required this.selectedDate,
    required this.accent,
    required this.onDaySelected,
  });

  final String monthLabel;
  final List<PlannerDay> days;

  /// How many day chips fit in the rail at once. The chip height is sized so
  /// this many fill the visible rail; the rest are reached by scrolling.
  final int visibleCount;
  final DateTime selectedDate;
  final Color accent;
  final ValueChanged<DateTime> onDaySelected;

  @override
  State<_TimelineRail> createState() => _TimelineRailState();
}

class _TimelineRailState extends State<_TimelineRail> {
  final ScrollController _scrollController = ScrollController();
  double _itemExtent = 0;
  double _viewportHeight = 0;

  /// The selected day always sits in the middle of [days] (the range is built
  /// centred on it), so centring on this index keeps the selection in view.
  int get _selectedIndex => widget.days.length ~/ 2;

  @override
  void didUpdateWidget(covariant _TimelineRail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameDay(oldWidget.selectedDate, widget.selectedDate)) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _centerSelected(animate: true),
      );
    }
  }

  void _centerSelected({required bool animate}) {
    if (!_scrollController.hasClients || _itemExtent <= 0) return;
    final target = _selectedIndex * _itemExtent -
        (_viewportHeight - _itemExtent) / 2;
    final clamped = target.clamp(
      _scrollController.position.minScrollExtent,
      _scrollController.position.maxScrollExtent,
    );
    if (animate) {
      _scrollController.animateTo(
        clamped,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(clamped);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

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
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: 18,
                      child: Center(
                        child: RotatedBox(
                          quarterTurns: 3,
                          child: Text(
                            widget.monthLabel,
                            style: textTheme.labelLarge?.copyWith(
                              color: Color.lerp(
                                widget.accent,
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
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final height = constraints.maxHeight;
                          final extent = height / widget.visibleCount;
                          final needsInitialCenter = _itemExtent == 0;
                          _itemExtent = extent;
                          _viewportHeight = height;
                          if (needsInitialCenter) {
                            WidgetsBinding.instance.addPostFrameCallback(
                              (_) => _centerSelected(animate: false),
                            );
                          }
                          return ListView.builder(
                            controller: _scrollController,
                            itemExtent: extent,
                            itemCount: widget.days.length,
                            padding: EdgeInsets.zero,
                            itemBuilder: (context, index) {
                              final day = widget.days[index];
                              return _RailDayChip(
                                day: day,
                                isSelected: _sameDay(
                                  day.date,
                                  widget.selectedDate,
                                ),
                                accent: widget.accent,
                                onTap: () => widget.onDaySelected(day.date),
                              );
                            },
                          );
                        },
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
    return Semantics(
      button: true,
      selected: isSelected,
      label: '${day.label} ${day.dayNumber}${day.isToday ? ', today' : ''}',
      child: GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
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
            width: 32,
            height: 32,
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
      ),
    );
  }
}

class _WeatherBriefingCard extends StatefulWidget {
  const _WeatherBriefingCard({
    required this.date,
    required this.events,
    required this.preferences,
  });

  final DateTime date;
  final List<PlannerEvent> events;
  final AppPreferences preferences;

  @override
  State<_WeatherBriefingCard> createState() => _WeatherBriefingCardState();
}

class _WeatherBriefingCardState extends State<_WeatherBriefingCard> {
  WeatherData? _weather;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    final data = await WeatherService.instance.getWeather();
    if (mounted) setState(() { _weather = data; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final tones = context.plannerTones;
    final firstLocation = widget.events
        .map((e) => e.location.trim())
        .firstWhere((l) => l.isNotEmpty, orElse: () => '');
    final nextTimedEvent = widget.events
        .where((e) => !e.isAllDay)
        .cast<PlannerEvent?>()
        .firstWhere((_) => true, orElse: () => null);

    final weather = _weather;

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
          if (_loading)
            SizedBox(
              width: 42,
              height: 42,
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: tones.mutedInk,
                  ),
                ),
              ),
            )
          else
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: (weather?.color ?? tones.mutedInk).withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                weather?.icon ?? Icons.cloud_off_rounded,
                color: weather?.color ?? tones.mutedInk,
                size: 22,
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  weather != null
                      ? '${weather.temperatureC.round()}°C, ${weather.description}'
                      : _loading ? 'Fetching weather…' : 'Weather unavailable',
                  style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  _briefingLine(
                    weather?.city ?? firstLocation,
                    nextTimedEvent,
                    hasWeather: weather != null,
                  ),
                  style: textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (widget.preferences.travelAlerts && firstLocation.isNotEmpty) ...[
            const SizedBox(width: 8),
            Column(
              children: [
                Icon(
                  _travelIcon(widget.preferences.travelMode),
                  color: tones.mutedInk,
                  size: 18,
                ),
                const SizedBox(height: 3),
                Text(
                  widget.preferences.travelMode,
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

  String _briefingLine(String city, PlannerEvent? next, {required bool hasWeather}) {
    final loc = city.isEmpty ? 'your area' : city;
    final locationPart = hasWeather ? loc : 'offline';
    if (next == null) return 'Weather in $locationPart. No events today.';
    return '$locationPart. Next: ${next.title}.';
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

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

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

    return Semantics(
      button: true,
      // Consolidate the card into one announcement instead of reading each
      // text fragment separately.
      label: '${event.title}, ${event.timeRange}, ${calendar.name}',
      excludeSemantics: true,
      child: InkWell(
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

  /// Assigns overlapping events to side-by-side columns so concurrent events
  /// don't render on top of each other. Returns each event with its column
  /// index and the number of columns in its overlap cluster.
  List<({PlannerEvent event, int col, int cols})> _layoutColumns(
    List<PlannerEvent> events,
  ) {
    final sorted = [...events]..sort((a, b) {
        final byStart = a.startAt.compareTo(b.startAt);
        return byStart != 0 ? byStart : a.endAt.compareTo(b.endAt);
      });
    final result = <({PlannerEvent event, int col, int cols})>[];

    var i = 0;
    while (i < sorted.length) {
      // Grow a cluster of transitively-overlapping events.
      var clusterEnd = sorted[i].endAt;
      final cluster = <PlannerEvent>[sorted[i]];
      var j = i + 1;
      while (j < sorted.length && sorted[j].startAt.isBefore(clusterEnd)) {
        cluster.add(sorted[j]);
        if (sorted[j].endAt.isAfter(clusterEnd)) clusterEnd = sorted[j].endAt;
        j++;
      }

      // First-fit column assignment within the cluster.
      final columnEnds = <DateTime>[];
      final columns = <int>[];
      for (final event in cluster) {
        var placed = -1;
        for (var c = 0; c < columnEnds.length; c++) {
          if (!event.startAt.isBefore(columnEnds[c])) {
            placed = c;
            columnEnds[c] = event.endAt;
            break;
          }
        }
        if (placed == -1) {
          placed = columnEnds.length;
          columnEnds.add(event.endAt);
        }
        columns.add(placed);
      }

      final colCount = columnEnds.length;
      for (var k = 0; k < cluster.length; k++) {
        result.add((event: cluster[k], col: columns[k], cols: colCount));
      }
      i = j;
    }
    return result;
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
            clipBehavior: Clip.hardEdge,
            children: [
              // Hour grid: labels + vertical divider line
              Column(
                children: [for (final hour in hours) _HourGridRow(hour: hour)],
              ),
              // Duration bars - one per timed event, spans start→end
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
              // Event cards positioned at start time, split into columns so
              // overlapping events sit side by side instead of stacking.
              Positioned.fill(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final available = constraints.maxWidth - _cardLeft - 8;
                    final placements = _layoutColumns(timedEvents);
                    return Stack(
                      clipBehavior: Clip.hardEdge,
                      children: [
                        for (final p in placements)
                          Positioned(
                            top: _topFor(p.event),
                            left: _cardLeft +
                                (p.cols > 1
                                    ? p.col * (available / p.cols)
                                    : 0),
                            width: p.cols > 1
                                ? (available / p.cols) - 4
                                : available,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: _EventCard(
                                event: p.event,
                                calendar: state.calendarById(p.event.calendarId),
                                colorCard: colorCard,
                                compact: true,
                                suppressLeftBar: true,
                                onTap: () => onEventTap(p.event),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
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
    required this.onAddEvent,
  });

  final VoidCallback onPrevDay;
  final VoidCallback onNextDay;
  final VoidCallback onMonthPressed;
  final VoidCallback onTodayPressed;
  final VoidCallback onFilterPressed;
  final VoidCallback onAddEvent;

  @override
  Widget build(BuildContext context) {
    final tones = context.plannerTones;
    return Center(
      child: Container(
        height: 56,
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
              _BarButton(
                icon: Icons.chevron_left_rounded,
                tooltip: 'Previous day',
                onTap: onPrevDay,
              ),
              _BarButton(
                icon: Icons.today_rounded,
                tooltip: 'Jump to today',
                onTap: onTodayPressed,
              ),
              // Primary, always-available create action.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Tooltip(
                  message: 'New event',
                  child: GestureDetector(
                    onTap: onAddEvent,
                    behavior: HitTestBehavior.opaque,
                    child: Semantics(
                      button: true,
                      label: 'New event',
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: context.plannerAccent,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.add_rounded,
                          color: context.onPlannerAccent,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              _BarButton(
                icon: Icons.tune_rounded,
                tooltip: 'Filter calendars',
                onTap: onFilterPressed,
              ),
              _BarButton(
                icon: Icons.calendar_view_month_rounded,
                tooltip: 'Month overview',
                onTap: onMonthPressed,
              ),
              _BarButton(
                icon: Icons.chevron_right_rounded,
                tooltip: 'Next day',
                onTap: onNextDay,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BarButton extends StatelessWidget {
  const _BarButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          // 48dp minimum touch target.
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SizedBox(
              width: 24,
              height: 48,
              child: Icon(icon, color: context.plannerTones.ink, size: 22),
            ),
          ),
        ),
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
    final user = ref.watch(firebaseUserProvider).asData?.value;
    final account =
        ref.watch(localAccountControllerProvider).asData?.value ??
        LocalAccountState.defaults();
    final preferences =
        ref.watch(appPreferencesControllerProvider).asData?.value ??
        AppPreferences.defaults();
    final accent = preferences.accentPalette.color;
    final items = [
      PlannerMenuDestination.search,
      PlannerMenuDestination.calendars,
      PlannerMenuDestination.themes,
      PlannerMenuDestination.preferences,
      PlannerMenuDestination.textSize,
      PlannerMenuDestination.whatsNew,
      PlannerMenuDestination.welcome,
      PlannerMenuDestination.help,
      PlannerMenuDestination.account,
      // Hidden for v1 (non-functional scaffolds / no billing):
      //   rsvp, smartAlerts, travel - feature stubs with no backend
      //   paywall - billing deferred; ships free
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
                account.displayName.isEmpty
                    ? 'Hello'
                    : 'Hello,\n${account.displayName}',
                style: textTheme.displayMedium?.copyWith(
                  color: accent,
                  fontSize: 30,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'DAYVEN',
                style: textTheme.displayMedium?.copyWith(
                  fontSize: 30,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 18),
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
                      user != null
                          ? Icons.cloud_done_outlined
                          : Icons.cloud_off_outlined,
                      color: Colors.white70,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        user?.email ?? user?.displayName ?? 'Synced to cloud',
                        style: textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
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
                    openPlannerMenuDestination(context, item);
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
              if (user != null)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () async {
                      await ref.read(firebaseAuthServiceProvider).signOut();
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
                    child: const Text('Sign Out'),
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
  const _EmptyDayState({required this.onAddEvent, this.onAddWithAi});

  final VoidCallback onAddEvent;

  /// When non-null, offers an "Add with AI" shortcut alongside the manual one.
  final VoidCallback? onAddWithAi;

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
              'Add an event to start planning this day.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onAddEvent,
              style: FilledButton.styleFrom(
                backgroundColor: context.plannerAccent,
                foregroundColor: context.onPlannerAccent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('New event'),
            ),
            if (onAddWithAi != null) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: onAddWithAi,
                style: TextButton.styleFrom(
                  foregroundColor: context.plannerAccent,
                ),
                icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                label: const Text('Add with AI'),
              ),
            ],
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
