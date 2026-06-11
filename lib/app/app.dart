import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'theme/app_theme.dart';
import '../core/auth/firebase_auth_service.dart';
import '../features/bootstrap/presentation/onboarding_screen.dart';
import '../features/home/application/planner_controller.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/preferences/application/app_preferences_controller.dart';

class DayvenApp extends ConsumerWidget {
  const DayvenApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    final preferences =
        ref.watch(appPreferencesControllerProvider).asData?.value ??
        AppPreferences.defaults();

    return MaterialApp(
      title: 'Dayven',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(preferences),
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        // Honour the device's accessibility text size, then apply the in-app
        // preference on top of it, clamped so layouts never break at extremes.
        final osScale = mediaQuery.textScaler.scale(1);
        final combined = (osScale * preferences.textScale).clamp(0.8, 1.6);
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: TextScaler.linear(combined),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: _Gate(requireAuth: config.hasRemoteBackend),
    );
  }
}

/// Decides between the sign-in onboarding and the planner home.
///
/// In cloud-only mode the planner requires a signed-in account; Firebase
/// persists the session (even offline), so a returning user lands straight on
/// [HomeScreen]. When no backend is configured (local dev/preview), auth is
/// bypassed so the demo data is explorable.
class _Gate extends ConsumerWidget {
  const _Gate({required this.requireAuth});

  final bool requireAuth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!requireAuth) {
      return const HomeScreen();
    }

    final auth = ref.watch(firebaseUserProvider);
    return auth.when(
      data: (user) =>
          user == null ? const OnboardingScreen() : const HomeScreen(),
      loading: () => const _BootstrapLoadingScreen(),
      error: (_, _) => const OnboardingScreen(),
    );
  }
}

class _BootstrapLoadingScreen extends StatelessWidget {
  const _BootstrapLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator(color: Colors.black54)),
    );
  }
}
