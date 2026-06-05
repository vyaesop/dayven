import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/auth/firebase_auth_service.dart';
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
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.calendar_today_rounded, color: AppColors.gold, size: 28),
              ),
              const SizedBox(height: 28),
              Text(
                'DAYVEN',
                style: textTheme.displayLarge?.copyWith(
                  color: Colors.white, fontSize: 38, height: 1.05,
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
                description: 'Sync across devices. Requires a free account.',
                onTap: () => _handleCloudSync(context, ref, controller),
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

  Future<void> _handleCloudSync(
    BuildContext context,
    WidgetRef ref,
    dynamic controller,
  ) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      controller.choose(StorageMode.cloudSync);
      return;
    }

    final signedIn = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AuthSheet(ref: ref),
    );

    if (signedIn == true && context.mounted) {
      controller.choose(StorageMode.cloudSync);
    }
  }
}

class _AuthSheet extends ConsumerStatefulWidget {
  const _AuthSheet({required this.ref});

  final WidgetRef ref;

  @override
  ConsumerState<_AuthSheet> createState() => _AuthSheetState();
}

class _AuthSheetState extends ConsumerState<_AuthSheet> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _isSignUp = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
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
      if (mounted) Navigator.of(context).pop(true);
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() { _error = _friendly(e.code); _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _error = 'Something went wrong.'; _loading = false; });
    }
  }

  Future<void> _googleSignIn() async {
    setState(() { _loading = true; _error = null; });
    try {
      final result = await ref.read(firebaseAuthServiceProvider).signInWithGoogle();
      if (result != null && mounted) Navigator.of(context).pop(true);
      if (result == null && mounted) setState(() => _loading = false);
    } catch (_) {
      if (mounted) setState(() { _error = 'Google sign-in failed.'; _loading = false; });
    }
  }

  String _friendly(String code) {
    switch (code) {
      case 'email-already-in-use': return 'Already registered — try signing in.';
      case 'user-not-found':       return 'No account found — try signing up.';
      case 'wrong-password':       return 'Incorrect password.';
      case 'weak-password':        return 'Password must be at least 6 characters.';
      default:                     return 'Auth error ($code).';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _isSignUp ? 'Create account' : 'Sign in',
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'Required to sync your planner across devices.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(hintText: 'Email address'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordCtrl,
            obscureText: true,
            decoration: InputDecoration(
              hintText: _isSignUp ? 'Password (min. 6 characters)' : 'Password',
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFFD05A5A))),
          ],
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _loading ? null : _submit,
              child: Text(_loading ? 'Please wait…' : _isSignUp ? 'Create Account' : 'Sign In'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _loading ? null : _googleSignIn,
              icon: const Icon(Icons.g_mobiledata_rounded),
              label: const Text('Continue with Google'),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: _loading ? null : () => setState(() { _isSignUp = !_isSignUp; _error = null; }),
              child: Text(_isSignUp ? 'Already have an account? Sign in' : "Don't have an account? Sign up"),
            ),
          ),
        ],
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
              width: 52, height: 52,
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
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.arrow_forward_rounded, color: accent, size: 16),
            ),
          ],
        ),
      ),
    );
  }
}
