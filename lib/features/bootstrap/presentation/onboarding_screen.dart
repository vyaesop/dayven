import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/analytics/analytics_service.dart';
import '../../../core/auth/firebase_auth_service.dart';

/// First-run gate for the cloud-only planner: the user must sign in (or create
/// an account) so their planner can sync. Once authenticated, Firebase persists
/// the session - including offline - so this screen is only seen once.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
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
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final auth = ref.read(firebaseAuthServiceProvider);
      final analytics = ref.read(analyticsServiceProvider);
      if (_isSignUp) {
        await auth.signUpWithEmail(email, password);
        await analytics.logSignUp('password');
      } else {
        await auth.signInWithEmail(email, password);
        await analytics.logLogin('password');
      }
      // The auth state stream drives navigation; nothing else to do here.
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          _error = _friendly(e.code);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Something went wrong. Please try again.';
          _loading = false;
        });
      }
    }
  }

  Future<void> _googleSignIn() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result =
          await ref.read(firebaseAuthServiceProvider).signInWithGoogle();
      if (result != null) {
        final isNew = result.additionalUserInfo?.isNewUser ?? false;
        final analytics = ref.read(analyticsServiceProvider);
        await (isNew
            ? analytics.logSignUp('google')
            : analytics.logLogin('google'));
      }
      if (result == null && mounted) setState(() => _loading = false);
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Google sign-in failed.';
          _loading = false;
        });
      }
    }
  }

  String _friendly(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Already registered - try signing in.';
      case 'user-not-found':
        return 'No account found - try signing up.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'invalid-email':
        return 'That email address looks invalid.';
      case 'network-request-failed':
        return 'No connection. Check your network and try again.';
      default:
        return 'Auth error ($code).';
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: AppColors.charcoal,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            24,
            36,
            24,
            MediaQuery.of(context).viewInsets.bottom + 28,
          ),
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
                child: const Icon(
                  Icons.calendar_today_rounded,
                  color: AppColors.gold,
                  size: 28,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'DAYVEN',
                style: textTheme.displayLarge?.copyWith(
                  color: Colors.white,
                  fontSize: 38,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _isSignUp
                    ? 'Create your account to sync your planner securely across all your devices.'
                    : 'Welcome back. Sign in to pick up your planner where you left off.',
                style: textTheme.bodyLarge?.copyWith(color: Colors.white60),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(hintText: 'Email address'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordCtrl,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                onSubmitted: (_) => _loading ? null : _submit(),
                decoration: InputDecoration(
                  hintText:
                      _isSignUp ? 'Password (min. 6 characters)' : 'Password',
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(
                  _error!,
                  style: textTheme.bodySmall?.copyWith(
                    color: const Color(0xFFE88A8A),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _loading ? null : _submit,
                  child: Text(
                    _loading
                        ? 'Please wait…'
                        : _isSignUp
                            ? 'Create Account'
                            : 'Sign In',
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _loading ? null : _googleSignIn,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.24),
                    ),
                  ),
                  icon: const Icon(Icons.g_mobiledata_rounded),
                  label: const Text('Continue with Google'),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: _loading
                      ? null
                      : () => setState(() {
                            _isSignUp = !_isSignUp;
                            _error = null;
                          }),
                  child: Text(
                    _isSignUp
                        ? 'Already have an account? Sign in'
                        : "Don't have an account? Sign up",
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
