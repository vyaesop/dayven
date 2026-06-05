import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'theme/app_theme.dart';
import '../features/bootstrap/application/app_bootstrap_controller.dart';
import '../features/bootstrap/presentation/storage_mode_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/preferences/application/app_preferences_controller.dart';

class DayvenApp extends ConsumerWidget {
  const DayvenApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storageMode = ref.watch(selectedStorageModeProvider);
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
