import 'ethiopian_calendar.dart';
import 'native_calendars.dart';

/// An optional second calendar shown alongside the Gregorian date.
enum SecondaryCalendar { none, ethiopian, hijri, hebrew, persian, buddhist }

extension SecondaryCalendarX on SecondaryCalendar {
  String get storageValue => name;

  /// Title shown in the settings list.
  String get label => switch (this) {
        SecondaryCalendar.none => 'Off',
        SecondaryCalendar.ethiopian => 'Ethiopian (Geʼez)',
        SecondaryCalendar.hijri => 'Hijri (Islamic)',
        SecondaryCalendar.hebrew => 'Hebrew',
        SecondaryCalendar.persian => 'Persian (Solar Hijri)',
        SecondaryCalendar.buddhist => 'Buddhist (Thai)',
      };

  /// One-line explanation shown under the option.
  String get description => switch (this) {
        SecondaryCalendar.none => 'Show only the standard (Gregorian) date.',
        SecondaryCalendar.ethiopian =>
          'Also show the Ethiopian (Geʼez) date, e.g. Megabit 20.',
        SecondaryCalendar.hijri =>
          'Also show the Islamic (tabular) date, e.g. Ramadan 12.',
        SecondaryCalendar.hebrew =>
          'Also show the Hebrew date, e.g. 23 Tevet.',
        SecondaryCalendar.persian =>
          'Also show the Persian (Jalali) date, e.g. Farvardin 1.',
        SecondaryCalendar.buddhist =>
          'Also show the Thai Buddhist date (year + 543).',
      };

  /// True when this option actually renders a secondary date.
  bool get isEnabled => this != SecondaryCalendar.none;

  /// The secondary-calendar label for [date], or `null` when disabled.
  String? labelFor(DateTime date) => switch (this) {
        SecondaryCalendar.none => null,
        SecondaryCalendar.ethiopian =>
          EthiopianDate.fromGregorian(date).formatted,
        SecondaryCalendar.hijri => HijriDate.fromGregorian(date).formatted,
        SecondaryCalendar.hebrew => HebrewDate.fromGregorian(date).formatted,
        SecondaryCalendar.persian => PersianDate.fromGregorian(date).formatted,
        SecondaryCalendar.buddhist =>
          BuddhistDate.fromGregorian(date).formatted,
      };
}

SecondaryCalendar secondaryCalendarFromStorage(String? value) =>
    SecondaryCalendar.values.firstWhere(
      (c) => c.storageValue == value,
      orElse: () => SecondaryCalendar.none,
    );
