import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/storage/storage_mode.dart';
import '../application/app_bootstrap_controller.dart';

class StorageModeScreen extends ConsumerWidget {
  const StorageModeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(selectedStorageModeProvider.notifier);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.charcoal,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 36, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo area
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.calendar_today_rounded,
                  color: AppColors.gold,
                  size: 28,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'VERTICAL\nPLANNER',
                style: textTheme.displayLarge?.copyWith(
                  color: Colors.white,
                  fontSize: 38,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'How should your planner store data?',
                style: textTheme.bodyLarge?.copyWith(color: Colors.white60),
              ),
              const SizedBox(height: 36),
              _StorageModeCard(
                mode: StorageMode.localSqlite,
                icon: Icons.phone_android_rounded,
                accent: AppColors.sage,
                description: 'Fully offline. All data stays on this device in SQLite.',
                onTap: () => controller.choose(StorageMode.localSqlite),
              ),
              const SizedBox(height: 14),
              _StorageModeCard(
                mode: StorageMode.cloudSync,
                icon: Icons.cloud_outlined,
                accent: AppColors.teal,
                description: 'Sync across devices via the Neon-backed cloud API.',
                onTap: () => controller.choose(StorageMode.cloudSync),
              ),
              const Spacer(),
              Text(
                'You can change your storage mode later from My Account in the menu.',
                style: textTheme.bodyMedium?.copyWith(color: Colors.white38),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StorageModeCard extends StatelessWidget {
  const _StorageModeCard({
    required this.mode,
    required this.icon,
    required this.accent,
    required this.description,
    required this.onTap,
  });

  final StorageMode mode;
  final IconData icon;
  final Color accent;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(26),
      child: Ink(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: accent, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(mode.label, style: textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(description, style: textTheme.bodyMedium),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_forward_rounded,
                color: accent,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
