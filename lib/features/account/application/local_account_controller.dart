import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalAccountState {
  const LocalAccountState({
    required this.isSignedIn,
    required this.displayName,
    required this.email,
    required this.communicationOptIn,
    required this.selectedPlan,
    required this.trialStartedAt,
    required this.redeemedCodes,
    required this.localPasscode,
  });

  factory LocalAccountState.defaults() {
    return const LocalAccountState(
      isSignedIn: false,
      displayName: '',
      email: '',
      communicationOptIn: false,
      selectedPlan: 'Yearly',
      trialStartedAt: null,
      redeemedCodes: [],
      localPasscode: '',
    );
  }

  final bool isSignedIn;
  final String displayName;
  final String email;
  final bool communicationOptIn;
  final String selectedPlan;
  final DateTime? trialStartedAt;
  final List<String> redeemedCodes;
  final String localPasscode;

  bool get hasPremiumPreview =>
      trialStartedAt != null || redeemedCodes.isNotEmpty;
  bool get hasLocalPasscode => localPasscode.isNotEmpty;

  int get remainingTrialDays {
    final started = trialStartedAt;
    if (started == null) {
      return 7;
    }

    final elapsed = DateTime.now().difference(started).inDays;
    final remaining = 7 - elapsed;
    return remaining < 0 ? 0 : remaining;
  }

  String get initials {
    if (displayName.trim().isEmpty) {
      return 'TP';
    }

    final parts = displayName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return 'TP';
    }

    final first = parts.first.substring(0, 1);
    final last = parts.length > 1 ? parts.last.substring(0, 1) : '';
    return '$first$last'.toUpperCase();
  }

  LocalAccountState copyWith({
    bool? isSignedIn,
    String? displayName,
    String? email,
    bool? communicationOptIn,
    String? selectedPlan,
    DateTime? trialStartedAt,
    List<String>? redeemedCodes,
    String? localPasscode,
    bool clearTrialStartedAt = false,
  }) {
    return LocalAccountState(
      isSignedIn: isSignedIn ?? this.isSignedIn,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      communicationOptIn: communicationOptIn ?? this.communicationOptIn,
      selectedPlan: selectedPlan ?? this.selectedPlan,
      trialStartedAt: clearTrialStartedAt
          ? null
          : trialStartedAt ?? this.trialStartedAt,
      redeemedCodes: redeemedCodes ?? this.redeemedCodes,
      localPasscode: localPasscode ?? this.localPasscode,
    );
  }
}

final localAccountControllerProvider =
    AsyncNotifierProvider<LocalAccountController, LocalAccountState>(
      LocalAccountController.new,
    );

class LocalAccountController extends AsyncNotifier<LocalAccountState> {
  static const _isSignedInKey = 'account_is_signed_in';
  static const _displayNameKey = 'account_display_name';
  static const _emailKey = 'account_email';
  static const _communicationOptInKey = 'account_communication_opt_in';
  static const _selectedPlanKey = 'account_selected_plan';
  static const _trialStartedAtKey = 'account_trial_started_at';
  static const _redeemedCodesKey = 'account_redeemed_codes';
  static const _localPasscodeKey = 'account_local_passcode';

  @override
  Future<LocalAccountState> build() async {
    final prefs = await SharedPreferences.getInstance();
    final defaults = LocalAccountState.defaults();

    return LocalAccountState(
      isSignedIn: prefs.getBool(_isSignedInKey) ?? defaults.isSignedIn,
      displayName: prefs.getString(_displayNameKey) ?? defaults.displayName,
      email: prefs.getString(_emailKey) ?? defaults.email,
      communicationOptIn:
          prefs.getBool(_communicationOptInKey) ?? defaults.communicationOptIn,
      selectedPlan: prefs.getString(_selectedPlanKey) ?? defaults.selectedPlan,
      trialStartedAt: _parseDateTime(prefs.getString(_trialStartedAtKey)),
      redeemedCodes:
          prefs.getStringList(_redeemedCodesKey) ?? defaults.redeemedCodes,
      localPasscode:
          prefs.getString(_localPasscodeKey) ?? defaults.localPasscode,
    );
  }

  Future<void> signIn({
    required String displayName,
    required String email,
    required bool communicationOptIn,
    String? localPasscode,
  }) {
    return _update(
      (current) => current.copyWith(
        isSignedIn: true,
        displayName: displayName.trim(),
        email: email.trim(),
        communicationOptIn: communicationOptIn,
        localPasscode: localPasscode?.trim().isEmpty ?? true
            ? current.localPasscode
            : _hashLocalPasscode(email, localPasscode!),
      ),
    );
  }

  Future<bool> unlock({
    required String email,
    required String localPasscode,
  }) async {
    final current = state.asData?.value ?? LocalAccountState.defaults();
    final emailMatches =
        current.email.trim().toLowerCase() == email.trim().toLowerCase();
    final passcodeMatches =
        current.localPasscode == _hashLocalPasscode(email, localPasscode) ||
        current.localPasscode == localPasscode.trim();
    if (!current.hasLocalPasscode || !emailMatches || !passcodeMatches) {
      return false;
    }

    await _update((value) => value.copyWith(isSignedIn: true));
    return true;
  }

  Future<bool> resetLocalPasscode({
    required String email,
    required String localPasscode,
  }) async {
    final current = state.asData?.value ?? LocalAccountState.defaults();
    final hasEmail = current.email.trim().isNotEmpty;
    final emailMatches =
        current.email.trim().toLowerCase() == email.trim().toLowerCase();
    if (hasEmail && !emailMatches) {
      return false;
    }

    await _update(
      (value) => value.copyWith(
        email: email.trim(),
        localPasscode: _hashLocalPasscode(email, localPasscode),
      ),
    );
    return true;
  }

  Future<void> signOut() {
    return _update((current) => current.copyWith(isSignedIn: false));
  }

  Future<void> updateCommunicationOptIn(bool value) {
    return _update((current) => current.copyWith(communicationOptIn: value));
  }

  Future<void> selectPlan(String value) {
    return _update((current) => current.copyWith(selectedPlan: value));
  }

  Future<void> startTrial() {
    return _update((current) {
      if (current.trialStartedAt != null) {
        return current;
      }

      return current.copyWith(trialStartedAt: DateTime.now());
    });
  }

  Future<bool> redeemCode(String code) async {
    final normalized = code.trim().toUpperCase();
    if (normalized.length < 4) {
      return false;
    }

    final current = state.asData?.value ?? LocalAccountState.defaults();
    if (current.redeemedCodes.contains(normalized)) {
      return false;
    }

    await _update(
      (value) =>
          value.copyWith(redeemedCodes: [...value.redeemedCodes, normalized]),
    );
    return true;
  }

  Future<void> deleteLocalAccount() async {
    final defaults = LocalAccountState.defaults();
    state = AsyncData(defaults);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_isSignedInKey);
    await prefs.remove(_displayNameKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_communicationOptInKey);
    await prefs.remove(_selectedPlanKey);
    await prefs.remove(_trialStartedAtKey);
    await prefs.remove(_redeemedCodesKey);
    await prefs.remove(_localPasscodeKey);
  }

  Future<void> _update(
    LocalAccountState Function(LocalAccountState current) next,
  ) async {
    final current = state.asData?.value ?? LocalAccountState.defaults();
    final updated = next(current);
    state = AsyncData(updated);
    await _save(updated);
  }

  Future<void> _save(LocalAccountState value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isSignedInKey, value.isSignedIn);
    await prefs.setString(_displayNameKey, value.displayName);
    await prefs.setString(_emailKey, value.email);
    await prefs.setBool(_communicationOptInKey, value.communicationOptIn);
    await prefs.setString(_selectedPlanKey, value.selectedPlan);
    await prefs.setString(_localPasscodeKey, value.localPasscode);

    final trialStartedAt = value.trialStartedAt;
    if (trialStartedAt == null) {
      await prefs.remove(_trialStartedAtKey);
    } else {
      await prefs.setString(
        _trialStartedAtKey,
        trialStartedAt.toIso8601String(),
      );
    }

    await prefs.setStringList(_redeemedCodesKey, value.redeemedCodes);
  }

  DateTime? _parseDateTime(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    return DateTime.tryParse(value);
  }

  String _hashLocalPasscode(String email, String passcode) {
    final input = '${email.trim().toLowerCase()}:${passcode.trim()}';
    var hash = 0x811c9dc5;
    for (final unit in input.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return 'fnv1a:${hash.toRadixString(16).padLeft(8, '0')}';
  }
}
