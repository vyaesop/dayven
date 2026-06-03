import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/auth/firebase_auth_service.dart';
import '../../../core/notifications/push_notification_service.dart';
import '../../../core/storage/storage_mode.dart';
import '../../account/application/local_account_controller.dart';
import '../../home/application/planner_controller.dart';
import '../../home/domain/planner_models.dart';
import '../application/local_rsvp_controller.dart';
import '../../preferences/application/app_preferences_controller.dart';
import '../../support/application/local_support_controller.dart';

enum PlannerMenuDestination {
  search,
  rsvp,
  calendars,
  themes,
  preferences,
  smartAlerts,
  textSize,
  travel,
  help,
  account,
  paywall,
  signIn,
  whatsNew,
  welcome,
  appIcon,
}

extension PlannerMenuDestinationX on PlannerMenuDestination {
  String get label {
    switch (this) {
      case PlannerMenuDestination.search:
        return 'Search';
      case PlannerMenuDestination.rsvp:
        return 'RSVP';
      case PlannerMenuDestination.calendars:
        return 'Calendars';
      case PlannerMenuDestination.themes:
        return 'Themes';
      case PlannerMenuDestination.preferences:
        return 'Preferences';
      case PlannerMenuDestination.smartAlerts:
        return 'Smart Alerts';
      case PlannerMenuDestination.textSize:
        return 'Text Size';
      case PlannerMenuDestination.travel:
        return 'Travel';
      case PlannerMenuDestination.help:
        return 'Help & Support';
      case PlannerMenuDestination.account:
        return 'My Account';
      case PlannerMenuDestination.paywall:
        return 'Membership';
      case PlannerMenuDestination.signIn:
        return 'Sign In';
      case PlannerMenuDestination.whatsNew:
        return "What's New";
      case PlannerMenuDestination.welcome:
        return 'Welcome';
      case PlannerMenuDestination.appIcon:
        return 'App Icon';
    }
  }

  IconData get icon {
    switch (this) {
      case PlannerMenuDestination.search:
        return Icons.search_rounded;
      case PlannerMenuDestination.rsvp:
        return Icons.mark_email_read_rounded;
      case PlannerMenuDestination.calendars:
        return Icons.calendar_month_rounded;
      case PlannerMenuDestination.themes:
        return Icons.palette_rounded;
      case PlannerMenuDestination.preferences:
        return Icons.tune_rounded;
      case PlannerMenuDestination.smartAlerts:
        return Icons.notifications_active_rounded;
      case PlannerMenuDestination.textSize:
        return Icons.text_fields_rounded;
      case PlannerMenuDestination.travel:
        return Icons.directions_car_filled_rounded;
      case PlannerMenuDestination.help:
        return Icons.help_rounded;
      case PlannerMenuDestination.account:
        return Icons.person_rounded;
      case PlannerMenuDestination.paywall:
        return Icons.workspace_premium_rounded;
      case PlannerMenuDestination.signIn:
        return Icons.login_rounded;
      case PlannerMenuDestination.whatsNew:
        return Icons.new_releases_rounded;
      case PlannerMenuDestination.welcome:
        return Icons.waving_hand_rounded;
      case PlannerMenuDestination.appIcon:
        return Icons.grid_view_rounded;
    }
  }
}

void openPlannerMenuDestination(
  BuildContext context,
  PlannerMenuDestination destination, {
  StorageMode? storageMode,
}) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) =>
          _FeatureScaffold(destination: destination, storageMode: storageMode),
    ),
  );
}

Widget _destinationBody(
  PlannerMenuDestination destination,
  StorageMode? storageMode,
) {
  switch (destination) {
    case PlannerMenuDestination.search:
      return const _SearchSurface();
    case PlannerMenuDestination.rsvp:
      return const _RsvpSurface();
    case PlannerMenuDestination.calendars:
      return const _CalendarSettingsSurface();
    case PlannerMenuDestination.themes:
      return const _ThemeSurface();
    case PlannerMenuDestination.preferences:
      return const _PreferencesSurface();
    case PlannerMenuDestination.smartAlerts:
      return const _SmartAlertsSurface();
    case PlannerMenuDestination.textSize:
      return const _TextSizeSurface();
    case PlannerMenuDestination.travel:
      return const _TravelSurface();
    case PlannerMenuDestination.help:
      return const _SupportSurface();
    case PlannerMenuDestination.account:
      return _AccountSurface(storageMode: storageMode);
    case PlannerMenuDestination.paywall:
      return const _PaywallSurface();
    case PlannerMenuDestination.signIn:
      return const _SignInSurface();
    case PlannerMenuDestination.whatsNew:
      return const _WhatsNewSurface();
    case PlannerMenuDestination.welcome:
      return const _WelcomeSurface();
    case PlannerMenuDestination.appIcon:
      return const _AppIconSurface();
  }
}

class _FeatureScaffold extends ConsumerWidget {
  const _FeatureScaffold({required this.destination, this.storageMode});

  final PlannerMenuDestination destination;
  final StorageMode? storageMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final preferences =
        ref.watch(appPreferencesControllerProvider).asData?.value ??
        AppPreferences.defaults();
    final accent = preferences.accentPalette.color;
    // Settings panels live on a darkened version of the active surface so the
    // user gets a consistent "drawer-like" feel even in light themes — matching
    // the Timepage design where the chrome around setting groups is always a
    // dim charcoal regardless of mode, with subtle tonal shifts.
    final background = switch (preferences.themeMode) {
      PlannerThemeMode.mono => const Color(0xFF6A6860),
      PlannerThemeMode.vivid => AppColors.charcoal,
      PlannerThemeMode.muted => const Color(0xFF4A4843),
      PlannerThemeMode.dark => const Color(0xFF1A1814),
    };

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color: accent,
                        size: 20,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    destination.icon,
                    color: Colors.white.withValues(alpha: 0.32),
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                destination.label.toUpperCase(),
                style: textTheme.displayMedium?.copyWith(
                  color: Colors.white,
                  fontSize: 28,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: _destinationBody(destination, storageMode),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Preferences ─────────────────────────────────────────────────────────────

class _PreferencesSurface extends ConsumerStatefulWidget {
  const _PreferencesSurface();

  @override
  ConsumerState<_PreferencesSurface> createState() =>
      _PreferencesSurfaceState();
}

class _PreferencesSurfaceState extends ConsumerState<_PreferencesSurface> {
  int _tab = 0; // 0=General 1=Timeline 2=Calendars

  static const _tabs = ['General', 'Timeline', 'Calendars'];

  @override
  Widget build(BuildContext context) {
    final prefs =
        ref.watch(appPreferencesControllerProvider).asData?.value ??
        AppPreferences.defaults();
    final notifier = ref.read(appPreferencesControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Three-way tab bar
        Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              for (int i = 0; i < _tabs.length; i++)
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _tab = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _tab == i
                            ? Colors.white.withValues(alpha: 0.18)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        _tabs[i].toUpperCase(),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: _tab == i ? Colors.white : Colors.white38,
                          fontSize: 10,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (_tab == 0) _GeneralSettings(prefs: prefs, notifier: notifier),
        if (_tab == 1) _TimelineSettings(prefs: prefs, notifier: notifier),
        if (_tab == 2) const _CalendarSettingsSurface(),
      ],
    );
  }
}

class _GeneralSettings extends StatelessWidget {
  const _GeneralSettings({required this.prefs, required this.notifier});
  final AppPreferences prefs;
  final AppPreferencesController notifier;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SettingsGroup(
          title: 'Preferences',
          children: [
            _SwitchRow(
              title: 'Sync preferences between my devices',
              value: false,
            ),
          ],
        ),
        const _SettingsGroup(
          title: 'Status Bar',
          children: [_SwitchRow(title: 'Status Bar Visible', value: true)],
        ),
        _SettingsGroup(
          title: 'Day View',
          children: [
            const _SwitchRow(title: 'Schedule', value: true),
            _SwitchRow(
              title: 'Actions',
              value: prefs.showActions,
              onChanged: (v) =>
                  notifier.setBoolPreference(PreferenceKeys.showActions, v),
            ),
            const _SwitchRow(
              title: 'On This Day',
              value: true,
              note: 'On empty days',
            ),
            _SwitchRow(
              title: 'Weather card',
              note: 'Show weather + briefing on the day view',
              value: prefs.showWeather,
              onChanged: (v) =>
                  notifier.setBoolPreference(PreferenceKeys.showWeather, v),
            ),
            _SwitchRow(
              title: 'All Day Events',
              value: prefs.showAllDay,
              onChanged: (v) =>
                  notifier.setBoolPreference(PreferenceKeys.showAllDay, v),
            ),
            _SwitchRow(
              title: 'Birthdays',
              value: prefs.showBirthdays,
              onChanged: (v) =>
                  notifier.setBoolPreference(PreferenceKeys.showBirthdays, v),
            ),
          ],
        ),
        _SettingsGroup(
          title: 'Actions & Flow',
          children: [
            _PrimaryAction(
              label: 'Text Size',
              icon: Icons.text_fields_rounded,
              destination: PlannerMenuDestination.textSize,
            ),
            const SizedBox(height: 6),
            _PrimaryAction(
              label: 'App Icon',
              icon: Icons.grid_view_rounded,
              destination: PlannerMenuDestination.appIcon,
            ),
          ],
        ),
        _SettingsGroup(
          title: 'Reset',
          children: [
            _ActionSettingRow(
              title: 'Reset All Preferences and Tips',
              value: 'Reset',
              onTap: notifier.resetPreferences,
            ),
          ],
        ),
      ],
    );
  }
}

class _TimelineSettings extends StatefulWidget {
  const _TimelineSettings({required this.prefs, required this.notifier});
  final AppPreferences prefs;
  final AppPreferencesController notifier;

  @override
  State<_TimelineSettings> createState() => _TimelineSettingsState();
}

class _TimelineSettingsState extends State<_TimelineSettings> {
  @override
  Widget build(BuildContext context) {
    final prefs = widget.prefs;
    final notifier = widget.notifier;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SettingsGroup(
          title: 'Invites',
          children: [
            _SwitchRow(
              title: 'Show event invites on timeline',
              value: prefs.timelineInvites,
              onChanged: (v) =>
                  notifier.setBoolPreference(PreferenceKeys.timelineInvites, v),
            ),
          ],
        ),
        _SettingsGroup(
          title: 'Shading',
          children: [
            _SwitchRow(
              title: 'Alternate days',
              value: prefs.shadeAlternateDays,
              onChanged: (v) => notifier.setBoolPreference(
                PreferenceKeys.shadeAlternateDays,
                v,
              ),
            ),
            _SwitchRow(
              title: 'The past',
              value: prefs.shadePastDays,
              onChanged: (v) =>
                  notifier.setBoolPreference(PreferenceKeys.shadePastDays, v),
            ),
            _SwitchRow(
              title: 'Weekends',
              value: prefs.shadeWeekends,
              onChanged: (v) =>
                  notifier.setBoolPreference(PreferenceKeys.shadeWeekends, v),
            ),
            _SwitchRow(
              title: 'Today',
              value: prefs.shadeToday,
              onChanged: (v) =>
                  notifier.setBoolPreference(PreferenceKeys.shadeToday, v),
            ),
          ],
        ),
        _SettingsGroup(
          title: 'Heavy Shading',
          children: [
            _SwitchRow(
              title: 'On',
              value: prefs.heavyShading,
              onChanged: (v) =>
                  notifier.setBoolPreference(PreferenceKeys.heavyShading, v),
            ),
          ],
        ),
        _SettingsGroup(
          title: 'Event Animation',
          children: [
            _SwitchRow(
              title: 'Cycle through events on busy days',
              value: prefs.cycleBusyDayEvents,
              onChanged: (v) => notifier.setBoolPreference(
                PreferenceKeys.cycleBusyDayEvents,
                v,
              ),
            ),
          ],
        ),
        _SettingsGroup(
          title: 'Floating Add Button',
          children: [
            _SwitchRow(
              title: 'Show button on timeline',
              value: prefs.showActions,
              onChanged: (v) =>
                  notifier.setBoolPreference(PreferenceKeys.showActions, v),
            ),
          ],
        ),
        _SettingsGroup(
          title: 'Days at a Glance',
          children: [
            for (final n in [3, 4, 5, 6, 7, 8, 9, 10])
              _ChoiceRow(
                title: '$n',
                selected: prefs.daysAtAGlance == n,
                onTap: () =>
                    notifier.setIntPreference(PreferenceKeys.daysAtAGlance, n),
              ),
          ],
        ),
        _SettingsGroup(
          title: 'Layout Mode',
          children: [
            for (final mode in ['Traditional', 'Day Hourly', 'Multi-line'])
              _ChoiceRow(
                title: mode,
                selected: prefs.timelineLayoutMode == mode,
                onTap: () => notifier.setStringPreference(
                  PreferenceKeys.timelineLayoutMode,
                  mode,
                ),
              ),
          ],
        ),
        _SettingsGroup(
          title: 'Hide Events from Timeline',
          children: [
            _SwitchRow(
              title: 'Hide all-day events',
              value: !prefs.showAllDay,
              onChanged: (v) =>
                  notifier.setBoolPreference(PreferenceKeys.showAllDay, !v),
            ),
            _SwitchRow(
              title: 'Hide birthdays',
              value: !prefs.showBirthdays,
              onChanged: (v) =>
                  notifier.setBoolPreference(PreferenceKeys.showBirthdays, !v),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Calendar Settings ────────────────────────────────────────────────────────

class _CalendarSettingsSurface extends ConsumerWidget {
  const _CalendarSettingsSurface();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plannerState = ref.watch(plannerControllerProvider).asData?.value;
    final prefs =
        ref.watch(appPreferencesControllerProvider).asData?.value ??
        AppPreferences.defaults();
    final prefController = ref.read(appPreferencesControllerProvider.notifier);
    final plannerController = ref.read(plannerControllerProvider.notifier);
    final calendars = plannerState?.calendars ?? const <PlannerCalendar>[];
    final visibleIds = plannerState?.visibleCalendarIds ?? const <String>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SegmentHeader(
          primary: 'Layout',
          secondary: 'Calendars',
          selectedSecond: true,
        ),
        const SizedBox(height: 18),
        _SettingsGroup(
          title: 'Default Calendar',
          children: [
            for (final calendar in calendars)
              _CalendarRow(
                title: calendar.name,
                color: calendar.color,
                selected: prefs.defaultCalendarId == calendar.id,
                onTap: () => prefController.setDefaultCalendarId(calendar.id),
              ),
          ],
        ),
        _SettingsGroup(
          title: 'Visible Calendars',
          children: [
            for (final calendar in calendars)
              _CalendarRow(
                title: calendar.id == prefs.defaultCalendarId
                    ? '${calendar.name} (default)'
                    : calendar.name,
                color: calendar.color,
                selected: visibleIds.contains(calendar.id),
                onTap: () =>
                    plannerController.toggleCalendarVisibility(calendar.id),
              ),
          ],
        ),
        _SettingsGroup(
          title: 'Display',
          children: [
            _SwitchRow(
              title: 'Match to Timepage colors',
              value: prefs.matchTimelineColors,
              onChanged: (value) => prefController.setBoolPreference(
                PreferenceKeys.matchTimelineColors,
                value,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Themes ───────────────────────────────────────────────────────────────────

class _ThemeSurface extends ConsumerWidget {
  const _ThemeSurface();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs =
        ref.watch(appPreferencesControllerProvider).asData?.value ??
        AppPreferences.defaults();
    final notifier = ref.read(appPreferencesControllerProvider.notifier);
    final palettes = PlannerAccentPalette.values;
    final accent = prefs.accentPalette.color;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _TinyToolbar(title: 'THEMES'),
        const SizedBox(height: 22),
        // Five small swatches at the top: the four nearest neighbors plus the
        // selected one in the middle (matching the design's "color stack" hint).
        Center(
          child: _AccentNeighborStrip(
            current: prefs.accentPalette,
            onPick: notifier.setAccentPalette,
          ),
        ),
        const SizedBox(height: 26),
        // Decorative scatter cluster: the active swatch is large and centered,
        // surrounded by softly-positioned neighbors. Tapping any spawns a swap.
        Center(
          child: SizedBox(
            width: 300,
            height: 230,
            child: _ScatterBubbleCluster(
              palettes: palettes,
              current: prefs.accentPalette,
              themeMode: prefs.themeMode,
              onPick: notifier.setAccentPalette,
            ),
          ),
        ),
        Center(
          child: Text(
            prefs.accentPalette.label,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 18),
        _ThemeModeSelector(
          selectedMode: prefs.themeMode,
          accent: accent,
          onSelected: notifier.setThemeMode,
        ),
        const SizedBox(height: 22),
        _SettingsGroup(
          title: 'Palette',
          children: [
            for (final palette in palettes)
              _PaletteRow(
                title: palette.label,
                color: palette.color,
                selected: palette == prefs.accentPalette,
                accent: accent,
                onTap: () => notifier.setAccentPalette(palette),
              ),
          ],
        ),
      ],
    );
  }
}

/// Top row of five small swatches centered on the active accent, with the
/// previous/next palette entries flanking it. This is the small palette stack
/// rendered above the bubble cluster in the design.
class _AccentNeighborStrip extends StatelessWidget {
  const _AccentNeighborStrip({required this.current, required this.onPick});

  final PlannerAccentPalette current;
  final ValueChanged<PlannerAccentPalette> onPick;

  @override
  Widget build(BuildContext context) {
    final all = PlannerAccentPalette.values;
    final i = all.indexOf(current);
    PlannerAccentPalette neighbor(int offset) {
      final idx = (i + offset) % all.length;
      return all[idx < 0 ? idx + all.length : idx];
    }

    final entries = [
      neighbor(-2),
      neighbor(-1),
      current,
      neighbor(1),
      neighbor(2),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final entry in entries)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: GestureDetector(
              onTap: () => onPick(entry),
              child: Container(
                width: entry == current ? 18 : 14,
                height: entry == current ? 18 : 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: entry.color,
                    width: entry == current ? 2.4 : 1.6,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// A semi-deterministic scatter of bubbles around the active accent. We use a
/// stable seed (the palette's enum index) so the cluster never reshuffles
/// between rebuilds — the user sees the same layout each time, just with the
/// center bubble swapping color when they pick a new accent.
class _ScatterBubbleCluster extends StatelessWidget {
  const _ScatterBubbleCluster({
    required this.palettes,
    required this.current,
    required this.themeMode,
    required this.onPick,
  });

  final List<PlannerAccentPalette> palettes;
  final PlannerAccentPalette current;
  final PlannerThemeMode themeMode;
  final ValueChanged<PlannerAccentPalette> onPick;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final cx = w / 2;
        final cy = h / 2;

        // Center bubble (active accent).
        final centerSize = 64.0;
        final children = <Widget>[
          Positioned(
            left: cx - centerSize / 2,
            top: cy - centerSize / 2,
            child: _ThemeBubble(
              color: current.color,
              selected: true,
              size: centerSize,
              onTap: () {},
            ),
          ),
        ];

        // The other palette entries scattered in two loose rings around the
        // center. Sizes vary slightly so the cluster feels organic.
        final others = palettes.where((p) => p != current).toList();
        for (var i = 0; i < others.length; i++) {
          final p = others[i];
          // Deterministic pseudo-random offsets based on enum index.
          final seed = p.index * 9173 + 17;
          final ringIndex = i % 2 == 0 ? 0 : 1; // alternate inner/outer ring
          final ringRadius = ringIndex == 0 ? 58.0 : 96.0;
          final angle = ((i * 137.508) % 360) * math.pi / 180;
          final jitterR = ((seed % 17) - 8) * 0.9;
          final jitterAng = ((seed % 31) - 15) * 0.012;
          final r = ringRadius + jitterR;
          final a = angle + jitterAng;
          final size = ringIndex == 0
              ? (22.0 + (seed % 5))
              : (16.0 + (seed % 7));
          final x = cx + r * math.cos(a) - size / 2;
          final y = cy + r * math.sin(a) * 0.78 - size / 2; // squash vertically

          if (x < -size || x > w || y < -size || y > h) continue;
          children.add(
            Positioned(
              left: x,
              top: y,
              child: _ThemeBubble(
                color: p.color,
                selected: false,
                size: size,
                onTap: () => onPick(p),
              ),
            ),
          );
        }

        return Stack(children: children);
      },
    );
  }
}

// ─── Smart Alerts ─────────────────────────────────────────────────────────────

class _SmartAlertsSurface extends ConsumerWidget {
  const _SmartAlertsSurface();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs =
        ref.watch(appPreferencesControllerProvider).asData?.value ??
        AppPreferences.defaults();
    final notifier = ref.read(appPreferencesControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _ComingSoonBanner(
          message:
              'Toggles are saved. Weather-based delivery and push scheduling arrive in v1.1.',
        ),
        // 5-icon grid matching the design
        Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.0,
            children: [
              _AlertTypeCard(
                icon: Icons.umbrella_rounded,
                label: 'Rain Alerts',
                color: AppColors.teal,
                enabled: prefs.rainAlerts,
                onTap: () => notifier.setBoolPreference(
                  PreferenceKeys.rainAlerts,
                  !prefs.rainAlerts,
                ),
              ),
              _AlertTypeCard(
                icon: Icons.wb_sunny_rounded,
                label: 'Daily Briefing',
                color: AppColors.gold,
                enabled: prefs.dailyBriefing,
                onTap: () => notifier.setBoolPreference(
                  PreferenceKeys.dailyBriefing,
                  !prefs.dailyBriefing,
                ),
              ),
              _AlertTypeCard(
                icon: Icons.people_alt_rounded,
                label: 'Follow Ups',
                color: AppColors.lilac,
                enabled: false,
                onTap: () {},
              ),
              _AlertTypeCard(
                icon: Icons.directions_run_rounded,
                label: 'Time to Leave',
                color: AppColors.coral,
                enabled: prefs.travelAlerts,
                onTap: () => notifier.setBoolPreference(
                  PreferenceKeys.travelAlerts,
                  !prefs.travelAlerts,
                ),
              ),
              _AlertTypeCard(
                icon: Icons.watch_later_rounded,
                label: 'Upcoming',
                color: AppColors.sage,
                enabled: prefs.upcomingReminders,
                onTap: () => notifier.setBoolPreference(
                  PreferenceKeys.upcomingReminders,
                  !prefs.upcomingReminders,
                ),
              ),
            ],
          ),
        ),
        _SettingsGroup(
          title: 'Rain Alerts',
          children: [
            _SwitchRow(
              title: 'Rain alerts',
              value: prefs.rainAlerts,
              note: 'Notify for any rain',
              onChanged: (v) =>
                  notifier.setBoolPreference(PreferenceKeys.rainAlerts, v),
            ),
            for (final mode in ['Any rain', 'Only heavy rain', 'Alert off'])
              _ChoiceRow(
                title: mode,
                selected: prefs.rainAlertMode == mode,
                onTap: () => notifier.setStringPreference(
                  PreferenceKeys.rainAlertMode,
                  mode,
                ),
              ),
            for (final minutes in [5, 15, 30, 45, 60])
              _ChoiceRow(
                title: '$minutes minutes notice',
                selected: prefs.rainNoticeMinutes == minutes,
                onTap: () => notifier.setIntPreference(
                  PreferenceKeys.rainNoticeMinutes,
                  minutes,
                ),
              ),
            _SwitchRow(
              title: 'Severe alerts',
              value: prefs.severeWeatherAlerts,
              onChanged: (v) => notifier.setBoolPreference(
                PreferenceKeys.severeWeatherAlerts,
                v,
              ),
            ),
          ],
        ),
        _SettingsGroup(
          title: 'Daily Briefing',
          children: [
            _SwitchRow(
              title: 'Daily briefing',
              value: prefs.dailyBriefing,
              note:
                  '${_formatBriefingTime(prefs.dailyBriefingHour, prefs.dailyBriefingMinute)} every day',
              onChanged: (v) =>
                  notifier.setBoolPreference(PreferenceKeys.dailyBriefing, v),
            ),
            for (final hour in [6, 7, 8])
              _ChoiceRow(
                title: _formatBriefingTime(hour, 0),
                selected:
                    prefs.dailyBriefingHour == hour &&
                    prefs.dailyBriefingMinute == 0,
                onTap: () {
                  notifier.setIntPreference(
                    PreferenceKeys.dailyBriefingHour,
                    hour,
                  );
                  notifier.setIntPreference(
                    PreferenceKeys.dailyBriefingMinute,
                    0,
                  );
                },
              ),
            _ChoiceRow(
              title: _formatBriefingTime(8, 30),
              selected:
                  prefs.dailyBriefingHour == 8 &&
                  prefs.dailyBriefingMinute == 30,
              onTap: () {
                notifier.setIntPreference(PreferenceKeys.dailyBriefingHour, 8);
                notifier.setIntPreference(
                  PreferenceKeys.dailyBriefingMinute,
                  30,
                );
              },
            ),
          ],
        ),
        _SettingsGroup(
          title: 'Upcoming',
          children: [
            _SwitchRow(
              title: 'Upcoming reminders',
              value: prefs.upcomingReminders,
              note: '15 minutes before',
              onChanged: (v) => notifier.setBoolPreference(
                PreferenceKeys.upcomingReminders,
                v,
              ),
            ),
          ],
        ),
        FutureBuilder<PushNotificationSnapshot>(
          future: PushNotificationService.instance.snapshot(),
          builder: (context, snapshot) {
            final value = snapshot.data;
            final token = value?.fcmToken ?? '';
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SettingsGroup(
                  title: 'Status',
                  children: [
                    _InfoRow(
                      title: 'Push notifications',
                      value: value?.enabled == true
                          ? 'Ready'
                          : 'Not configured',
                    ),
                    _InfoRow(
                      title: 'Permission',
                      value: value?.permissionStatus ?? 'Unknown',
                    ),
                    _InfoRow(
                      title: 'Device token',
                      value: token.isEmpty ? 'Waiting' : _shortToken(token),
                    ),
                    if (value?.lastTitle.isNotEmpty == true)
                      _InfoRow(title: 'Last message', value: value!.lastTitle),
                    if (value?.error.isNotEmpty == true)
                      _InfoRow(
                        title: 'Setup note',
                        value: 'Needs Firebase config',
                      ),
                  ],
                ),
                _SettingsGroup(
                  title: 'Test',
                  children: [
                    _ActionSettingRow(
                      title: 'Send test notification',
                      value: 'Fire now',
                      onTap: () async {
                        await PushNotificationService.instance
                            .sendTestLocalNotification();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Test notification sent'),
                            ),
                          );
                        }
                      },
                    ),
                    _ActionSettingRow(
                      title: 'Copy device token',
                      value: token.isEmpty ? 'Waiting' : 'Copy',
                      onTap: () async {
                        if (token.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Token not ready yet — reopen this screen in a moment',
                              ),
                            ),
                          );
                          return;
                        }
                        await Clipboard.setData(ClipboardData(text: token));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('FCM token copied to clipboard'),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  String _shortToken(String token) {
    if (token.length <= 12) {
      return token;
    }
    return '${token.substring(0, 6)}…${token.substring(token.length - 4)}';
  }

  String _formatBriefingTime(int hour, int minute) {
    final suffix = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final displayMinute = minute.toString().padLeft(2, '0');
    return '$displayHour:$displayMinute $suffix';
  }
}

class _AlertTypeCard extends StatelessWidget {
  const _AlertTypeCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: enabled
              ? color.withValues(alpha: 0.18)
              : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: enabled
                ? color.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: enabled ? color : Colors.white38, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: enabled ? Colors.white : Colors.white38,
                fontSize: 10,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Text Size ────────────────────────────────────────────────────────────────

class _TextSizeSurface extends ConsumerStatefulWidget {
  const _TextSizeSurface();

  @override
  ConsumerState<_TextSizeSurface> createState() => _TextSizeSurfaceState();
}

class _TextSizeSurfaceState extends ConsumerState<_TextSizeSurface> {
  static const _scales = [0.8, 0.85, 0.9, 0.95, 1.0, 1.05, 1.1, 1.15, 1.2, 1.3];
  int _selectedIndex = 4; // default 1.0

  @override
  void initState() {
    super.initState();
    final prefs = ref.read(appPreferencesControllerProvider).asData?.value;
    if (prefs != null) {
      final closest = _scales.indexed.reduce(
        (a, b) =>
            (a.$2 - prefs.textScale).abs() < (b.$2 - prefs.textScale).abs()
            ? a
            : b,
      );
      _selectedIndex = closest.$1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scale = _scales[_selectedIndex];
    final notifier = ref.read(appPreferencesControllerProvider.notifier);
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Big Aa preview card
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: textTheme.displayLarge!.copyWith(
                  color: Colors.white,
                  fontSize: 80 * scale,
                  fontWeight: FontWeight.w700,
                ),
                child: const Text('Aa'),
              ),
              const SizedBox(height: 12),
              Text(
                'May 10 · Today',
                style: textTheme.bodyLarge?.copyWith(
                  color: Colors.white60,
                  fontSize: 16 * scale,
                ),
              ),
            ],
          ),
        ),
        // Dot indicator row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_scales.length, (i) {
            final isSelected = i == _selectedIndex;
            return GestureDetector(
              onTap: () {
                setState(() => _selectedIndex = i);
                notifier.setTextScale(_scales[i]);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: isSelected ? 20 : 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.gold : Colors.white30,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 24),
        const _SettingsGroup(
          title: 'Dynamic Type',
          children: [_SwitchRow(title: 'Use device text size', value: true)],
        ),
        _SettingsGroup(
          title: 'Preview',
          children: [
            _InfoRow(
              title: 'Current scale',
              value: '${(scale * 100).round()}%',
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Travel ───────────────────────────────────────────────────────────────────

class _TravelSurface extends ConsumerStatefulWidget {
  const _TravelSurface();

  @override
  ConsumerState<_TravelSurface> createState() => _TravelSurfaceState();
}

class _TravelSurfaceState extends ConsumerState<_TravelSurface> {
  static const _travelModes = ['Driving', 'Walking', 'Bicycling', 'Transit'];
  static const _directionsApps = ['Google Maps', 'Waze', 'System default'];

  @override
  Widget build(BuildContext context) {
    final prefs =
        ref.watch(appPreferencesControllerProvider).asData?.value ??
        AppPreferences.defaults();
    final notifier = ref.read(appPreferencesControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _ComingSoonBanner(
          message:
              'Preferences are saved. Live directions and time-to-leave alerts require map integration in v1.1.',
        ),
        const _HeroPanel(
          title: 'Time to leave',
          body:
              'Set your preferred travel mode and directions app. Time-to-leave alerts will use these when you add a location to an event.',
          icon: Icons.route_rounded,
          iconColor: AppColors.coral,
        ),
        _SettingsGroup(
          title: 'Default Travel Mode',
          children: [
            for (final mode in _travelModes)
              _ChoiceRow(
                title: mode,
                selected: prefs.travelMode == mode,
                onTap: () => notifier.setStringPreference(
                  PreferenceKeys.travelMode,
                  mode,
                ),
              ),
          ],
        ),
        _SettingsGroup(
          title: 'Directions App',
          children: [
            for (final app in _directionsApps)
              _ChoiceRow(
                title: app,
                selected: prefs.directionsApp == app,
                onTap: () => notifier.setStringPreference(
                  PreferenceKeys.directionsApp,
                  app,
                ),
              ),
          ],
        ),
        _SettingsGroup(
          title: 'Time-to-Leave',
          children: [
            _SwitchRow(
              title: 'Advanced travel modes',
              value: prefs.travelAlerts,
              note: 'Cycling, ferry, rideshare',
              onChanged: (value) => notifier.setBoolPreference(
                PreferenceKeys.travelAlerts,
                value,
              ),
            ),
            const _InfoRow(
              title: 'Travel icons',
              value: 'Car, bus, walk, bike',
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Account ─────────────────────────────────────────────────────────────────

class _AccountSurface extends ConsumerWidget {
  const _AccountSurface({required this.storageMode});

  final StorageMode? storageMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account =
        ref.watch(localAccountControllerProvider).asData?.value ??
        LocalAccountState.defaults();
    final accountController = ref.read(localAccountControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HeroPanel(
          title: account.isSignedIn
              ? 'Hello ${account.displayName.isEmpty ? 'there' : account.displayName}'
              : 'Your planner account',
          body:
              'Storage mode: ${storageMode?.label ?? 'Not selected'}. ${account.isSignedIn ? account.email : 'This local profile is saved only on this device for now.'}',
          icon: Icons.person_rounded,
          iconColor: AppColors.lilac,
        ),
        _SettingsGroup(
          title: 'Profile',
          children: [
            _InfoRow(
              title: 'Status',
              value: account.isSignedIn ? 'Signed in locally' : 'Guest mode',
            ),
            _InfoRow(
              title: 'Communication',
              value: account.communicationOptIn ? 'Opted in' : 'Not subscribed',
            ),
          ],
        ),
        _SettingsGroup(
          title: 'Membership',
          children: [
            _InfoRow(
              title: 'Status',
              value: account.hasPremiumPreview
                  ? 'Premium preview'
                  : 'Free plan',
            ),
            _InfoRow(
              title: 'Trial',
              value: '${account.remainingTrialDays} days remaining',
            ),
            _InfoRow(title: 'Selected plan', value: account.selectedPlan),
            _InfoRow(
              title: 'Redeemed codes',
              value: account.redeemedCodes.isEmpty
                  ? 'None'
                  : '${account.redeemedCodes.length}',
            ),
          ],
        ),
        _PrimaryAction(
          label: 'View Membership',
          icon: Icons.workspace_premium_rounded,
          destination: PlannerMenuDestination.paywall,
          storageMode: storageMode,
        ),
        const SizedBox(height: 12),
        _PrimaryAction(
          label: account.isSignedIn ? 'Edit Profile' : 'Sign In',
          icon: Icons.login_rounded,
          destination: PlannerMenuDestination.signIn,
        ),
        const SizedBox(height: 12),
        if (account.isSignedIn)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: accountController.signOut,
              style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
              child: const Text('Sign Out'),
            ),
          ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete account?'),
                  content: const Text(
                    'This permanently deletes all your events, calendars, and account credentials. This cannot be undone.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text(
                        'Delete',
                        style: TextStyle(color: Color(0xFFFF7070)),
                      ),
                    ),
                  ],
                ),
              );
              if (confirmed != true) return;

              // Delete cloud data + Firebase account if in cloud sync mode
              if (storageMode == StorageMode.cloudSync) {
                try {
                  final client = ref.read(apiClientProvider);
                  await client.delete('/v1/auth/user');
                  await ref.read(firebaseAuthServiceProvider).signOut();
                } catch (_) {}
              }

              await accountController.deleteLocalAccount();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Account deleted.')),
                );
              }
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFFF7070),
            ),
            child: const Text('Delete Account'),
          ),
        ),
        const SizedBox(height: 18),
        const _SettingsGroup(
          title: 'Account Safety',
          children: [
            _InfoRow(title: 'Privacy Policy', value: 'Required before release'),
            _InfoRow(
              title: 'Terms of Service',
              value: 'Required before release',
            ),
            _InfoRow(title: 'Delete account', value: 'Flow scaffolded'),
          ],
        ),
      ],
    );
  }
}

// ─── Paywall ─────────────────────────────────────────────────────────────────

class _PaywallSurface extends ConsumerWidget {
  const _PaywallSurface();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account =
        ref.watch(localAccountControllerProvider).asData?.value ??
        LocalAccountState.defaults();
    final controller = ref.read(localAccountControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _HeroPanel(
          title: 'Plan beautifully',
          body:
              'Unlock all themes, smart alerts, and cloud sync. A Play Billing / RevenueCat membership screen matching the premium screens in the designs.',
          icon: Icons.workspace_premium_rounded,
          iconColor: AppColors.gold,
        ),
        _PriceCard(
          title: 'Monthly',
          price: '\$1.99',
          subtext: 'per month',
          selected: account.selectedPlan == 'Monthly',
          onTap: () => controller.selectPlan('Monthly'),
        ),
        _PriceCard(
          title: 'Yearly',
          price: '\$11.99',
          subtext: 'per year  ·  Save 50%',
          selected: account.selectedPlan == 'Yearly',
          badge: 'Best value',
          onTap: () => controller.selectPlan('Yearly'),
        ),
        const SizedBox(height: 4),
        _SettingsGroup(
          title: 'Includes',
          children: [
            const _InfoRow(title: 'All themes & palettes', value: '✓'),
            const _InfoRow(title: 'Smart alerts', value: '✓'),
            const _InfoRow(title: 'Cloud sync', value: 'Neon-backed'),
            const _InfoRow(title: 'Restore purchases', value: 'Ready'),
            const _InfoRow(title: 'Cross-platform access', value: '✓'),
          ],
        ),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () async {
              await controller.startTrial();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Started local ${account.selectedPlan.toLowerCase()} trial preview.',
                    ),
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: AppColors.charcoal,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: Text(
              account.trialStartedAt == null
                  ? 'Start 7-Day Free Trial'
                  : 'Trial Active  ·  ${account.remainingTrialDays} days left',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _RedeemCodeCard(onRedeem: controller.redeemCode),
      ],
    );
  }
}

// ─── Sign In ──────────────────────────────────────────────────────────────────

class _SignInSurface extends ConsumerStatefulWidget {
  const _SignInSurface();

  @override
  ConsumerState<_SignInSurface> createState() => _SignInSurfaceState();
}

class _SignInSurfaceState extends ConsumerState<_SignInSurface> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSignUp = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Email and password are required.');
      return;
    }

    setState(() { _loading = true; _error = null; });
    try {
      final auth = ref.read(firebaseAuthServiceProvider);
      if (_isSignUp) {
        await auth.signUpWithEmail(email, password);
      } else {
        await auth.signInWithEmail(email, password);
      }
      if (mounted) Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() { _error = _friendlyError(e.code); _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _error = 'Something went wrong. Try again.'; _loading = false; });
    }
  }

  Future<void> _googleSignIn() async {
    setState(() { _loading = true; _error = null; });
    try {
      final auth = ref.read(firebaseAuthServiceProvider);
      final result = await auth.signInWithGoogle();
      if (result == null && mounted) setState(() => _loading = false);
      if (result != null && mounted) Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() { _error = _friendlyError(e.code); _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _error = 'Google sign-in failed. Try again.'; _loading = false; });
    }
  }

  String _friendlyError(String code) {
    switch (code) {
      case 'email-already-in-use': return 'That email is already registered. Try signing in.';
      case 'user-not-found':       return 'No account with that email. Try signing up.';
      case 'wrong-password':       return 'Incorrect password.';
      case 'invalid-email':        return 'Enter a valid email address.';
      case 'weak-password':        return 'Password must be at least 6 characters.';
      case 'too-many-requests':    return 'Too many attempts. Wait a moment and try again.';
      default:                     return 'Auth error ($code). Try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final firebaseUser = ref.watch(firebaseUserProvider).asData?.value;
    final panelTheme = _lightPanelTheme(context);

    // Already signed in — show signed-in state
    if (firebaseUser != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LightCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Signed in', style: panelTheme.textTheme.headlineMedium),
                const SizedBox(height: 6),
                Text(
                  firebaseUser.email ?? firebaseUser.uid,
                  style: panelTheme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () async {
                      await ref.read(firebaseAuthServiceProvider).signOut();
                    },
                    child: const Text('Sign Out'),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _LightCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isSignUp ? 'Create account' : 'Sign in',
                style: panelTheme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 6),
              Text(
                _isSignUp
                    ? 'Your events sync across devices via the cloud.'
                    : 'Welcome back — sign in to access your planner.',
                style: panelTheme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 18),
              Theme(
                data: panelTheme,
                child: Column(
                  children: [
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(hintText: 'Email address'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: _isSignUp ? 'Password (min. 6 characters)' : 'Password',
                      ),
                    ),
                  ],
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(
                  _error!,
                  style: panelTheme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFFD05A5A),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _loading ? null : _submit,
                child: _InlineButton(
                  label: _loading
                      ? 'Please wait…'
                      : _isSignUp ? 'Create Account' : 'Sign In',
                  icon: Icons.arrow_forward_rounded,
                ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _loading ? null : _googleSignIn,
                child: const _InlineButton(
                  label: 'Continue with Google',
                  icon: Icons.g_mobiledata_rounded,
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: _loading
                    ? null
                    : () => setState(() { _isSignUp = !_isSignUp; _error = null; }),
                child: Text(
                  _isSignUp
                      ? 'Already have an account? Sign in'
                      : "Don't have an account? Sign up",
                ),
              ),
              if (!_isSignUp) ...[
                TextButton(
                  onPressed: _loading
                      ? null
                      : () => _showResetPassword(context),
                  child: const Text('Forgot password?'),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showResetPassword(BuildContext context) {
    final ctrl = TextEditingController(text: _emailController.text);
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(ctx).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 18, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Reset Password', style: Theme.of(ctx).textTheme.headlineMedium),
                const SizedBox(height: 14),
                TextField(
                  controller: ctrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(hintText: 'Email address'),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      final email = ctrl.text.trim();
                      if (email.isEmpty) return;
                      await ref.read(firebaseAuthServiceProvider).sendPasswordResetEmail(email);
                      if (ctx.mounted) Navigator.of(ctx).pop();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Password reset email sent.')),
                        );
                      }
                    },
                    child: const Text('Send Reset Email'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).whenComplete(ctrl.dispose);
  }
}

// ─── Support ──────────────────────────────────────────────────────────────────

class _SupportSurface extends ConsumerStatefulWidget {
  const _SupportSurface();

  @override
  ConsumerState<_SupportSurface> createState() => _SupportSurfaceState();
}

class _SupportSurfaceState extends ConsumerState<_SupportSurface> {
  // Which section is expanded: null = none, 'contact', 'feature', 'faq'
  String? _expanded;

  static const _faqItems = [
    (
      'What can I do with the local plan?',
      'Create unlimited events, calendars and reminders — all stored on your device.',
    ),
    (
      'How do I add people to an event?',
      'Open any event, tap Edit, and type names in the People field separated by commas.',
    ),
    (
      'Can I sync across devices?',
      'Cloud sync is coming in v1.0 — select the Cloud Sync storage mode when prompted.',
    ),
    (
      'How do I change my theme?',
      'Go to Themes in the menu and pick any of the 29 accent palettes or choose Mono, Vivid, Muted, or Dark mode.',
    ),
    (
      'How do I reset preferences?',
      'Go to Preferences → General and tap Reset All Preferences.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final entries =
        ref.watch(localSupportControllerProvider).asData?.value ??
        const <LocalSupportEntry>[];
    final controller = ref.read(localSupportControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Link-style main items
        _SettingsGroup(
          title: 'Help',
          children: [
            _SupportLinkRow(
              icon: Icons.support_agent_rounded,
              label: 'Contact Support',
              color: AppColors.teal,
              expanded: _expanded == 'contact',
              onTap: () => setState(
                () => _expanded = _expanded == 'contact' ? null : 'contact',
              ),
            ),
            if (_expanded == 'contact')
              _SupportComposerInline(
                hint: 'Tell us what went wrong or what you need.',
                onSubmit: (msg) async {
                  await controller.submit(
                    type: SupportEntryType.contact,
                    message: msg,
                  );
                  if (mounted) setState(() => _expanded = null);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Message saved locally.')),
                    );
                  }
                },
              ),
            _SupportLinkRow(
              icon: Icons.lightbulb_outline_rounded,
              label: 'Feature Request',
              color: AppColors.coral,
              expanded: _expanded == 'feature',
              onTap: () => setState(
                () => _expanded = _expanded == 'feature' ? null : 'feature',
              ),
            ),
            if (_expanded == 'feature')
              _SupportComposerInline(
                hint: 'Describe a feature you would love to see.',
                onSubmit: (msg) async {
                  await controller.submit(
                    type: SupportEntryType.featureRequest,
                    message: msg,
                  );
                  if (mounted) setState(() => _expanded = null);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Request saved locally.')),
                    );
                  }
                },
              ),
            const _SupportLinkRow(
              icon: Icons.play_circle_outline_rounded,
              label: 'How To…',
              color: AppColors.lilac,
            ),
            _SupportLinkRow(
              icon: Icons.quiz_rounded,
              label: 'FAQ',
              color: AppColors.gold,
              expanded: _expanded == 'faq',
              onTap: () =>
                  setState(() => _expanded = _expanded == 'faq' ? null : 'faq'),
            ),
            if (_expanded == 'faq')
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Theme(
                  data: _lightPanelTheme(context),
                  child: Column(
                    children: [
                      for (final item in _faqItems) ...[
                        _FaqItem(question: item.$1, answer: item.$2),
                        if (item != _faqItems.last) const Divider(height: 20),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
        _PrimaryAction(
          label: "What's New",
          icon: Icons.new_releases_rounded,
          destination: PlannerMenuDestination.whatsNew,
        ),
        if (entries.isNotEmpty) ...[
          const SizedBox(height: 16),
          _SettingsGroup(
            title: 'Queued (${entries.length})',
            children: [
              for (final entry in entries.take(5))
                _InfoRow(
                  title: entry.type.label,
                  value: _relativeDate(entry.createdAt),
                ),
              _ActionSettingRow(
                title: 'Clear all',
                value: '${entries.length}',
                onTap: controller.clearAll,
              ),
            ],
          ),
        ],
      ],
    );
  }

  String _relativeDate(DateTime value) {
    final d = DateTime.now().difference(value);
    if (d.inMinutes < 1) return 'Just now';
    if (d.inHours < 1) return '${d.inMinutes}m ago';
    if (d.inDays < 1) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }
}

class _SupportLinkRow extends StatelessWidget {
  const _SupportLinkRow({
    required this.icon,
    required this.label,
    required this.color,
    this.expanded = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool expanded;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final panelTheme = _lightPanelTheme(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Theme(
          data: _lightPanelTheme(context),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(label, style: panelTheme.textTheme.bodyLarge),
              ),
              Icon(
                expanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_right_rounded,
                color: _lightPanelMutedInk,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SupportComposerInline extends StatefulWidget {
  const _SupportComposerInline({required this.hint, required this.onSubmit});

  final String hint;
  final Future<void> Function(String message) onSubmit;

  @override
  State<_SupportComposerInline> createState() => _SupportComposerInlineState();
}

class _SupportComposerInlineState extends State<_SupportComposerInline> {
  final _controller = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final panelTheme = _lightPanelTheme(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Theme(
        data: panelTheme,
        child: Column(
          children: [
            TextField(
              controller: _controller,
              minLines: 3,
              maxLines: 5,
              style: panelTheme.textTheme.bodyMedium?.copyWith(
                color: _lightPanelInk,
              ),
              decoration: InputDecoration(
                hintText: widget.hint,
                border: InputBorder.none,
                isDense: true,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving
                    ? null
                    : () async {
                        final msg = _controller.text.trim();
                        if (msg.isEmpty) return;
                        setState(() => _saving = true);
                        await widget.onSubmit(msg);
                        if (mounted) {
                          _controller.clear();
                          setState(() => _saving = false);
                        }
                      },
                child: Text(_saving ? 'Saving…' : 'Send'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FaqItem extends StatefulWidget {
  const _FaqItem({required this.question, required this.answer});
  final String question;
  final String answer;

  @override
  State<_FaqItem> createState() => _FaqItemState();
}

class _FaqItemState extends State<_FaqItem> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _open = !_open),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.question,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Icon(
                _open ? Icons.remove_rounded : Icons.add_rounded,
                size: 16,
                color: AppColors.mutedInk,
              ),
            ],
          ),
          if (_open) ...[
            const SizedBox(height: 6),
            Text(widget.answer, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}

// ─── Search ───────────────────────────────────────────────────────────────────

class _SearchSurface extends ConsumerStatefulWidget {
  const _SearchSurface();

  @override
  ConsumerState<_SearchSurface> createState() => _SearchSurfaceState();
}

class _SearchSurfaceState extends ConsumerState<_SearchSurface> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';
  String _scope = 'Future';

  static const _scopes = ['Future', 'Past', 'All time'];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final plannerState = ref.watch(plannerControllerProvider).asData?.value;
    final allEvents = plannerState?.events ?? const <PlannerEvent>[];
    final now = DateTime.now();

    final scopedEvents = allEvents.where((e) {
      switch (_scope) {
        case 'Future':
          return e.startAt.isAfter(now);
        case 'Past':
          return e.startAt.isBefore(now);
        default:
          return true;
      }
    }).toList();

    final normalized = _query.trim().toLowerCase();
    final results = normalized.isEmpty
        ? scopedEvents.take(6).toList()
        : scopedEvents.where((event) {
            return [
              event.title,
              event.location,
              event.note,
              event.url,
              event.attendees.join(' '),
            ].join(' ').toLowerCase().contains(normalized);
          }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          autofocus: true,
          onChanged: (value) => setState(() => _query = value),
          decoration: const InputDecoration(
            hintText: 'Search events, people, places',
            prefixIcon: Icon(Icons.search_rounded),
          ),
        ),
        const SizedBox(height: 16),
        _SettingsGroup(
          title: 'Scope',
          children: [
            for (final scope in _scopes)
              _ChoiceRow(
                title: scope,
                selected: _scope == scope,
                onTap: () => setState(() => _scope = scope),
              ),
          ],
        ),
        _SettingsGroup(
          title: normalized.isEmpty
              ? 'Recent Events (${results.length})'
              : 'Results (${results.length})',
          children: [
            if (results.isEmpty)
              const _InfoRow(title: 'No matches', value: 'Try another term')
            else
              for (final event in results)
                _EventResultRow(
                  event: event,
                  calendar: plannerState?.calendarById(event.calendarId),
                ),
          ],
        ),
      ],
    );
  }
}

// ─── RSVP ─────────────────────────────────────────────────────────────────────

class _RsvpSurface extends ConsumerWidget {
  const _RsvpSurface();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events =
        ref.watch(plannerControllerProvider).asData?.value.events ??
        const <PlannerEvent>[];
    final responses =
        ref.watch(localRsvpControllerProvider).asData?.value ??
        const <String, LocalRsvpStatus>{};
    final rsvpController = ref.read(localRsvpControllerProvider.notifier);
    final invitedEvents = events
        .where((event) => event.attendees.isNotEmpty)
        .toList();
    final acceptedCount = invitedEvents
        .where((event) => responses[event.id] == LocalRsvpStatus.accepted)
        .length;
    final maybeCount = invitedEvents
        .where((event) => responses[event.id] == LocalRsvpStatus.maybe)
        .length;
    final declinedCount = invitedEvents
        .where((event) => responses[event.id] == LocalRsvpStatus.declined)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _HeroPanel(
          title: 'RSVP inbox',
          body:
              'Invitee-based event lists and attendee responses. Add people to events to populate this list.',
          icon: Icons.mark_email_read_rounded,
          iconColor: AppColors.teal,
        ),
        _SettingsGroup(
          title: 'Invites',
          children: [
            _InfoRow(
              title: 'Awaiting response',
              value:
                  '${invitedEvents.length - acceptedCount - maybeCount - declinedCount}',
            ),
            _InfoRow(title: 'Accepted', value: '$acceptedCount'),
            _InfoRow(title: 'Maybe', value: '$maybeCount'),
            _InfoRow(title: 'Declined', value: '$declinedCount'),
          ],
        ),
        if (invitedEvents.isNotEmpty)
          _SettingsGroup(
            title: 'Events with People',
            children: [
              for (final event in invitedEvents.take(8))
                _RsvpEventRow(
                  event: event,
                  status: responses[event.id] ?? LocalRsvpStatus.awaiting,
                  onStatusChanged: (status) =>
                      rsvpController.setStatus(event.id, status),
                ),
            ],
          )
        else
          const _SettingsGroup(
            title: 'No invitees yet',
            children: [
              _InfoRow(
                title: 'How to add people',
                value: 'Open an event and tap People',
              ),
            ],
          ),
      ],
    );
  }
}

class _RsvpEventRow extends StatelessWidget {
  const _RsvpEventRow({
    required this.event,
    required this.status,
    required this.onStatusChanged,
  });

  final PlannerEvent event;
  final LocalRsvpStatus status;
  final ValueChanged<LocalRsvpStatus> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final panelTheme = _lightPanelTheme(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(event.title, style: panelTheme.textTheme.bodyLarge),
              ),
              Text(
                status.label,
                style: panelTheme.textTheme.bodyMedium?.copyWith(
                  color: _statusColor(status),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            event.attendees.length == 1
                ? event.attendees.first
                : event.attendees.join(', '),
            style: panelTheme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in LocalRsvpStatus.values)
                ChoiceChip(
                  label: Text(option.label),
                  selected: status == option,
                  onSelected: (_) => onStatusChanged(option),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Color _statusColor(LocalRsvpStatus value) {
    return switch (value) {
      LocalRsvpStatus.accepted => AppColors.sage,
      LocalRsvpStatus.maybe => AppColors.gold,
      LocalRsvpStatus.declined => const Color(0xFFD05A5A),
      LocalRsvpStatus.awaiting => AppColors.mutedInk,
    };
  }
}

// ─── What's New ───────────────────────────────────────────────────────────────

class _WhatsNewSurface extends StatelessWidget {
  const _WhatsNewSurface();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _HeroPanel(
          title: "What's new in Vertical Planner",
          body: 'Local-first planner — every feature works fully offline.',
          icon: Icons.new_releases_rounded,
          iconColor: AppColors.gold,
        ),
        _WhatsNewCard(
          version: '0.9',
          label: 'Latest',
          color: AppColors.teal,
          items: const [
            'Brightened color palette across all screens',
            'Countdown display on event detail',
            'Bottom bar day navigation arrows',
            'Today ring highlight in month overview',
            'Biweekly and yearly repeat rules',
            'More reminder options (10 min, 2 hours, 1 week)',
            'Event dot heatmap in month grid',
            'Functional search scope (past / future / all)',
            'Functional travel mode selection',
            'App icon customization preview',
          ],
        ),
        _WhatsNewCard(
          version: '0.8',
          label: 'Previous',
          color: AppColors.lilac,
          items: const [
            'Theme palette and mode persist across restarts',
            'Dynamic text sizing preference',
            'Functional event search',
            'RSVP attendee summary from event invitees',
            'Smart alert and travel preference toggles',
            'Local account, profile, and membership preview',
            'Local support and feedback queue',
            'Default calendar persistence',
            'All-day event support',
          ],
        ),
        _WhatsNewCard(
          version: '0.7',
          label: 'Foundation',
          color: AppColors.coral,
          items: const [
            'SQLite-backed local repository',
            'Month heatmap overview',
            'Calendar filtering',
            'Event detail inspect sheet',
            'Reminder and repeat rule foundations',
            'People / invitees on events',
            'URL and notes on events',
            'Storage mode selection (local / cloud)',
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Text(
            'Cloud sync, live auth, and notification scheduling are coming in v1.0.',
            style: textTheme.bodyMedium?.copyWith(color: Colors.white54),
          ),
        ),
      ],
    );
  }
}

class _WhatsNewCard extends StatelessWidget {
  const _WhatsNewCard({
    required this.version,
    required this.label,
    required this.color,
    required this.items,
  });

  final String version;
  final String label;
  final Color color;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: color.withValues(alpha: 0.4)),
                ),
                child: Text(
                  'v$version',
                  style: textTheme.labelLarge?.copyWith(
                    color: color,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: textTheme.labelLarge?.copyWith(
                  color: Colors.white38,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (final item in items) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(top: 6, right: 10),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Text(
                    item,
                    style: textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
          ],
        ],
      ),
    );
  }
}

// ─── App Icon ─────────────────────────────────────────────────────────────────

class _AppIconSurface extends ConsumerWidget {
  const _AppIconSurface();

  static const _iconColors = [
    ('Charcoal', AppColors.charcoal),
    ('Teal', AppColors.teal),
    ('Coral', AppColors.coral),
    ('Lilac', AppColors.lilac),
    ('Sage', AppColors.sage),
    ('Gold', AppColors.gold),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs =
        ref.watch(appPreferencesControllerProvider).asData?.value ??
        AppPreferences.defaults();
    final notifier = ref.read(appPreferencesControllerProvider.notifier);
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _HeroPanel(
          title: 'Customize your icon',
          body:
              'Pick a color theme for the home screen icon. Dynamic icon switching requires a production build.',
          icon: Icons.grid_view_rounded,
          iconColor: AppColors.lilac,
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset(
                'assets/icons/app_icon.png',
                width: 96,
                height: 96,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        _SettingsGroup(
          title: 'Icon Color',
          children: [
            for (final entry in _iconColors)
              _CalendarRow(
                title: entry.$1,
                color: entry.$2,
                selected: prefs.accentPalette.color == entry.$2,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${entry.$1} icon preview — live switching requires a production build.',
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
        _SettingsGroup(
          title: 'Theme Match',
          children: [
            _InfoRow(title: 'Current accent', value: prefs.accentPalette.label),
            _SwitchRow(
              title: 'Match theme',
              value: prefs.appIconMatchTheme,
              onChanged: (v) => notifier.setBoolPreference(
                PreferenceKeys.appIconMatchTheme,
                v,
              ),
            ),
            for (final badge in [
              'None',
              'Events Remaining Today',
              "Today's Date",
            ])
              _ChoiceRow(
                title: badge,
                selected: prefs.appIconBadge == badge,
                onTap: () => notifier.setStringPreference(
                  PreferenceKeys.appIconBadge,
                  badge,
                ),
              ),
            _InfoRow(title: 'Badge', value: prefs.appIconBadge),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Text(
            'App icon customization will apply on the next app install or update.',
            style: textTheme.bodyMedium?.copyWith(color: Colors.white38),
          ),
        ),
      ],
    );
  }
}

// ─── Coming Soon Banner ───────────────────────────────────────────────────────

class _ComingSoonBanner extends StatelessWidget {
  const _ComingSoonBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          const Icon(Icons.construction_rounded, color: AppColors.gold, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared UI components ─────────────────────────────────────────────────────

class _SegmentHeader extends StatelessWidget {
  const _SegmentHeader({
    required this.primary,
    required this.secondary,
    this.selectedSecond = false,
  });

  final String primary;
  final String secondary;
  final bool selectedSecond;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _SegmentChip(label: primary, selected: !selectedSecond),
        const SizedBox(width: 8),
        _SegmentChip(label: secondary, selected: selectedSecond),
      ],
    );
  }
}

const _lightPanelInk = Color(0xFF1A1814);
const _lightPanelMutedInk = Color(0xFF6F6B63);

ThemeData _lightPanelTheme(BuildContext context) {
  final theme = Theme.of(context);
  final textTheme = theme.textTheme;

  return theme.copyWith(
    textTheme: textTheme.copyWith(
      headlineMedium: textTheme.headlineMedium?.copyWith(color: _lightPanelInk),
      titleMedium: textTheme.titleMedium?.copyWith(color: _lightPanelInk),
      bodyLarge: textTheme.bodyLarge?.copyWith(color: _lightPanelInk),
      bodyMedium: textTheme.bodyMedium?.copyWith(color: _lightPanelMutedInk),
      labelLarge: textTheme.labelLarge?.copyWith(color: _lightPanelInk),
      labelSmall: textTheme.labelSmall?.copyWith(color: _lightPanelMutedInk),
    ),
    iconTheme: theme.iconTheme.copyWith(color: _lightPanelInk),
    inputDecorationTheme: theme.inputDecorationTheme.copyWith(
      hintStyle: textTheme.bodyMedium?.copyWith(color: _lightPanelMutedInk),
    ),
  );
}

class _SegmentChip extends StatelessWidget {
  const _SegmentChip({required this.label, required this.selected});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: selected
            ? Colors.white.withValues(alpha: 0.22)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: selected
              ? Colors.white.withValues(alpha: 0.18)
              : Colors.transparent,
        ),
      ),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: selected ? Colors.white : Colors.white38,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10, left: 4),
            child: Text(
              title.toUpperCase(),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Colors.white38,
                fontSize: 10,
                letterSpacing: 1.2,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.title,
    required this.value,
    this.note,
    this.onChanged,
  });

  final String title;
  final bool value;
  final String? note;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return _SettingTile(
      title: title,
      subtitle: note,
      trailing: Switch.adaptive(
        value: value,
        activeThumbColor: Colors.white,
        activeTrackColor: AppColors.teal,
        onChanged: onChanged,
      ),
    );
  }
}

class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({required this.title, required this.selected, this.onTap});

  final String title;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: _SettingTile(
        title: title,
        trailing: Icon(
          selected
              ? Icons.check_circle_rounded
              : Icons.radio_button_unchecked_rounded,
          color: selected ? accent : _lightPanelMutedInk,
          size: 20,
        ),
      ),
    );
  }
}

class _CalendarRow extends StatelessWidget {
  const _CalendarRow({
    required this.title,
    required this.color,
    required this.selected,
    this.onTap,
  });

  final String title;
  final Color color;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: _SettingTile(
        title: title,
        leading: Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        trailing: Icon(
          selected ? Icons.check_rounded : Icons.add_rounded,
          color: selected ? accent : _lightPanelMutedInk,
          size: 20,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final panelTheme = _lightPanelTheme(context);
    return _SettingTile(
      title: title,
      trailing: Text(
        value,
        style: panelTheme.textTheme.bodyMedium?.copyWith(
          color: _lightPanelMutedInk,
        ),
      ),
    );
  }
}

class _ActionSettingRow extends StatelessWidget {
  const _ActionSettingRow({
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
      borderRadius: BorderRadius.circular(14),
      child: _SettingTile(
        title: title,
        trailing: Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.teal,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _EventResultRow extends StatelessWidget {
  const _EventResultRow({required this.event, required this.calendar});

  final PlannerEvent event;
  final PlannerCalendar? calendar;

  @override
  Widget build(BuildContext context) {
    return _SettingTile(
      title: event.title,
      subtitle: [
        event.timeRange,
        if (event.location.isNotEmpty) event.location,
        if (event.attendees.isNotEmpty) event.attendees.join(', '),
      ].join('  ·  '),
      leading: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: calendar?.color ?? AppColors.teal,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final panelTheme = _lightPanelTheme(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          ...?(leading == null ? null : [leading!, const SizedBox(width: 10)]),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: panelTheme.textTheme.bodyLarge),
                if (subtitle != null)
                  Text(subtitle!, style: panelTheme.textTheme.bodyMedium),
              ],
            ),
          ),
          ...?(trailing == null ? null : [const SizedBox(width: 8), trailing!]),
        ],
      ),
    );
  }
}

class _ThemeBubble extends StatelessWidget {
  const _ThemeBubble({
    required this.color,
    required this.selected,
    required this.size,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Light swatches need a dark check + a hairline outline so they don't
    // disappear against the charcoal backdrop.
    final lum = 0.299 * color.r + 0.587 * color.g + 0.114 * color.b;
    final isLight = lum > 0.72;
    final checkColor = isLight ? const Color(0xFF1A1814) : Colors.white;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isLight
              ? Border.all(
                  color: Colors.white.withValues(alpha: 0.18),
                  width: 1,
                )
              : null,
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.55),
                    blurRadius: 14,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: selected
            ? Icon(Icons.check_rounded, color: checkColor, size: size * 0.42)
            : null,
      ),
    );
  }
}

class _PaletteRow extends StatelessWidget {
  const _PaletteRow({
    required this.title,
    required this.color,
    this.selected = false,
    this.accent,
    this.onTap,
  });

  final String title;
  final Color color;
  final bool selected;
  final Color? accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: _SettingTile(
        title: title,
        leading: Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.18),
              width: 0.8,
            ),
          ),
        ),
        trailing: selected
            ? Icon(
                Icons.check_rounded,
                color: accent ?? AppColors.gold,
                size: 18,
              )
            : null,
      ),
    );
  }
}

class _ThemeModeSelector extends StatelessWidget {
  const _ThemeModeSelector({
    required this.selectedMode,
    required this.accent,
    required this.onSelected,
  });

  final PlannerThemeMode selectedMode;
  final Color accent;
  final ValueChanged<PlannerThemeMode> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          for (final mode in PlannerThemeMode.values)
            Expanded(
              child: GestureDetector(
                onTap: () => onSelected(mode),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: mode == selectedMode
                        ? accent.withValues(alpha: 0.22)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    border: mode == selectedMode
                        ? Border.all(
                            color: accent.withValues(alpha: 0.55),
                            width: 1,
                          )
                        : null,
                  ),
                  child: Text(
                    mode.label.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: mode == selectedMode
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.42),
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TinyToolbar extends ConsumerWidget {
  const _TinyToolbar({required this.title});

  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent =
        (ref.watch(appPreferencesControllerProvider).asData?.value ??
                AppPreferences.defaults())
            .accentPalette
            .color;
    return Row(
      children: [
        Icon(Icons.arrow_back_rounded, color: accent, size: 18),
        const Spacer(),
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(color: Colors.white),
        ),
        const Spacer(),
        Icon(
          Icons.text_fields_rounded,
          color: Colors.white.withValues(alpha: 0.38),
          size: 18,
        ),
      ],
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({
    required this.title,
    required this.body,
    required this.icon,
    this.iconColor,
  });

  final String title;
  final String body;
  final IconData icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? AppColors.teal;
    final panelTheme = _lightPanelTheme(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 16),
          Text(title, style: panelTheme.textTheme.headlineMedium),
          const SizedBox(height: 6),
          Text(body, style: panelTheme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _PriceCard extends StatelessWidget {
  const _PriceCard({
    required this.title,
    required this.price,
    required this.subtext,
    required this.selected,
    this.badge,
    this.onTap,
  });

  final String title;
  final String price;
  final String subtext;
  final bool selected;
  final String? badge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = _lightPanelTheme(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFD2F0ED) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? AppColors.teal : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: textTheme.titleMedium),
                  if (badge != null)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        badge!,
                        style: textTheme.labelLarge?.copyWith(
                          color: AppColors.gold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  const SizedBox(height: 2),
                  Text(subtext, style: textTheme.bodyMedium),
                ],
              ),
            ),
            Text(price, style: textTheme.displayMedium?.copyWith(fontSize: 24)),
          ],
        ),
      ),
    );
  }
}

class _RedeemCodeCard extends StatefulWidget {
  const _RedeemCodeCard({required this.onRedeem});

  final Future<bool> Function(String code) onRedeem;

  @override
  State<_RedeemCodeCard> createState() => _RedeemCodeCardState();
}

class _RedeemCodeCardState extends State<_RedeemCodeCard> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final panelTheme = _lightPanelTheme(context);
    return _LightCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Redeem Code', style: panelTheme.textTheme.headlineMedium),
          const SizedBox(height: 10),
          TextField(
            controller: _controller,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(hintText: 'ENTER-CODE-HERE'),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final success = await widget.onRedeem(_controller.text);
                if (!mounted) return;
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Code redeemed — premium preview active.'
                          : 'That code could not be redeemed.',
                    ),
                  ),
                );
                if (success) _controller.clear();
              },
              child: const Text('Redeem'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryAction extends StatelessWidget {
  const _PrimaryAction({
    required this.label,
    required this.icon,
    required this.destination,
    this.storageMode,
  });

  final String label;
  final IconData icon;
  final PlannerMenuDestination destination;
  final StorageMode? storageMode;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () => openPlannerMenuDestination(
          context,
          destination,
          storageMode: storageMode,
        ),
        style: FilledButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.ink,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: Icon(icon, size: 18),
        label: Text(label),
      ),
    );
  }
}

class _LightCard extends StatelessWidget {
  const _LightCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Theme(data: _lightPanelTheme(context), child: child),
    );
  }
}

class _InlineButton extends StatelessWidget {
  const _InlineButton({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.teal,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Welcome / Onboarding ─────────────────────────────────────────────────────

class _WelcomeSurface extends StatefulWidget {
  const _WelcomeSurface();

  @override
  State<_WelcomeSurface> createState() => _WelcomeSurfaceState();
}

class _WelcomeSurfaceState extends State<_WelcomeSurface> {
  final _controller = PageController();
  int _page = 0;

  static const _slides = [
    _WelcomeSlide(
      icon: Icons.view_day_rounded,
      iconColor: AppColors.teal,
      title: 'Day Timeline',
      body: 'The timeline shows your schedule for the week ahead and beyond.',
    ),
    _WelcomeSlide(
      icon: Icons.calendar_view_month_rounded,
      iconColor: AppColors.coral,
      title: 'Month Heatmap',
      body: 'The month view heatmap highlights the days when you\'re busiest.',
    ),
    _WelcomeSlide(
      icon: Icons.palette_rounded,
      iconColor: AppColors.gold,
      title: 'Themes',
      body:
          'Choose from Mono, Vivid, Muted, or Dark mode with a full accent palette.',
    ),
    _WelcomeSlide(
      icon: Icons.notifications_active_rounded,
      iconColor: AppColors.lilac,
      title: 'Smart Alerts',
      body: 'Get rain alerts, daily briefings, and upcoming event reminders.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < _slides.length) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isLast = _page == _slides.length;
    final totalPages = _slides.length + 1;

    return Column(
      children: [
        Expanded(
          child: PageView(
            controller: _controller,
            onPageChanged: (i) => setState(() => _page = i),
            children: [
              ..._slides.map((slide) => _WelcomeFeaturePage(slide: slide)),
              // Thank you page
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.favorite_rounded,
                          color: AppColors.gold,
                          size: 36,
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'Thank You.',
                        style: textTheme.displayMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'We hope you enjoy Vertical Planner!',
                        style: textTheme.bodyLarge?.copyWith(
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // Dot indicators + Next button
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int i = 0; i < totalPages; i++) ...[
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: i == _page ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == _page
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                if (i < totalPages - 1) const SizedBox(width: 6),
              ],
              if (!isLast) ...[
                const Spacer(),
                TextButton(
                  onPressed: _next,
                  style: TextButton.styleFrom(foregroundColor: Colors.white70),
                  child: const Text('Next'),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _WelcomeSlide {
  const _WelcomeSlide({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;
}

class _WelcomeFeaturePage extends StatelessWidget {
  const _WelcomeFeaturePage({required this.slide});

  final _WelcomeSlide slide;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: double.infinity,
            height: 260,
            decoration: BoxDecoration(
              color: slide.iconColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: slide.iconColor.withValues(alpha: 0.2)),
            ),
            child: Icon(
              slide.icon,
              size: 72,
              color: slide.iconColor.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 36),
          Text(
            slide.title,
            style: textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            slide.body,
            style: textTheme.bodyLarge?.copyWith(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
