import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SupportEntryType { contact, featureRequest, feedback }

extension SupportEntryTypeX on SupportEntryType {
  String get label {
    switch (this) {
      case SupportEntryType.contact:
        return 'Contact Support';
      case SupportEntryType.featureRequest:
        return 'Feature Request';
      case SupportEntryType.feedback:
        return 'Feedback';
    }
  }
}

class LocalSupportEntry {
  const LocalSupportEntry({
    required this.type,
    required this.message,
    required this.createdAt,
  });

  final SupportEntryType type;
  final String message;
  final DateTime createdAt;

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'message': message,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory LocalSupportEntry.fromJson(Map<String, dynamic> json) {
    return LocalSupportEntry(
      type: SupportEntryType.values.firstWhere(
        (value) => value.name == json['type'],
        orElse: () => SupportEntryType.feedback,
      ),
      message: json['message'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

final localSupportControllerProvider =
    AsyncNotifierProvider<LocalSupportController, List<LocalSupportEntry>>(
      LocalSupportController.new,
    );

class LocalSupportController extends AsyncNotifier<List<LocalSupportEntry>> {
  static const _entriesKey = 'local_support_entries';

  @override
  Future<List<LocalSupportEntry>> build() async {
    final prefs = await SharedPreferences.getInstance();
    final rawEntries = prefs.getStringList(_entriesKey) ?? const [];
    return rawEntries.map(_decodeEntry).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> submit({
    required SupportEntryType type,
    required String message,
  }) async {
    final trimmed = message.trim();
    if (trimmed.isEmpty) {
      return;
    }

    final current = state.asData?.value ?? const <LocalSupportEntry>[];
    final updated = [
      LocalSupportEntry(
        type: type,
        message: trimmed,
        createdAt: DateTime.now(),
      ),
      ...current,
    ];
    state = AsyncData(updated);
    await _save(updated);
  }

  Future<void> clearAll() async {
    state = const AsyncData([]);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_entriesKey);
  }

  Future<void> _save(List<LocalSupportEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _entriesKey,
      entries.map((entry) => jsonEncode(entry.toJson())).toList(),
    );
  }

  LocalSupportEntry _decodeEntry(String value) {
    try {
      final decoded = jsonDecode(value) as Map<String, dynamic>;
      return LocalSupportEntry.fromJson(decoded);
    } catch (_) {
      return LocalSupportEntry(
        type: SupportEntryType.feedback,
        message: value,
        createdAt: DateTime.now(),
      );
    }
  }
}
