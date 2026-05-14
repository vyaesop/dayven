import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'theme/app_theme.dart';
import '../features/bootstrap/application/app_bootstrap_controller.dart';
import '../features/bootstrap/presentation/storage_mode_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/preferences/application/app_preferences_controller.dart';

class VerticalPlannerApp extends ConsumerWidget {
  const VerticalPlannerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storageMode = ref.watch(selectedStorageModeProvider);
    final preferences =
        ref.watch(appPreferencesControllerProvider).asData?.value ??
        AppPreferences.defaults();

    return MaterialApp(
      title: 'Vertical Planner',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(preferences),
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: TextScaler.linear(preferences.textScale),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: storageMode.when(
        data: (mode) {
          if (mode == null) {
            return const StorageModeScreen();
          }

          return const HomeScreen();
        },
        loading: () => const _BootstrapLoadingScreen(),
        error: (_, _) => const StorageModeScreen(),
      ),
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
