import 'package:flutter/material.dart';

enum TimeFormatKind {
  hour24,
  hour12;

  static TimeFormatKind fromStorage(String? value) {
    return TimeFormatKind.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TimeFormatKind.hour24,
    );
  }

  bool get use24Hour => this == TimeFormatKind.hour24;

  String get label {
    switch (this) {
      case TimeFormatKind.hour24:
        return '24 saat';
      case TimeFormatKind.hour12:
        return '12 saat (AM/PM)';
    }
  }
}

enum DateTimeFormatKind {
  shortTurkish,
  longTurkish,
  iso;

  static DateTimeFormatKind fromStorage(String? value) {
    return DateTimeFormatKind.values.firstWhere(
      (e) => e.name == value,
      orElse: () => DateTimeFormatKind.shortTurkish,
    );
  }

  String get label {
    switch (this) {
      case DateTimeFormatKind.shortTurkish:
        return '20.05.2026 · 14:32';
      case DateTimeFormatKind.longTurkish:
        return '20 Mayıs 2026, Çarşamba · 14:32';
      case DateTimeFormatKind.iso:
        return '2026-05-20 · 14:32';
    }
  }
}

enum AutoLockDurationKind {
  min5,
  min15,
  min30,
  untilClose;

  static AutoLockDurationKind fromStorage(String? value) {
    return AutoLockDurationKind.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AutoLockDurationKind.min15,
    );
  }

  String get label {
    switch (this) {
      case AutoLockDurationKind.min5:
        return '5 dakika';
      case AutoLockDurationKind.min15:
        return '15 dakika';
      case AutoLockDurationKind.min30:
        return '30 dakika';
      case AutoLockDurationKind.untilClose:
        return 'Uygulama kapanana kadar';
    }
  }

  /// Hareketsizlik sonrası otomatik kilit süresi; `null` = devre dışı.
  Duration? get idleTimeout {
    switch (this) {
      case AutoLockDurationKind.min5:
        return const Duration(minutes: 5);
      case AutoLockDurationKind.min15:
        return const Duration(minutes: 15);
      case AutoLockDurationKind.min30:
        return const Duration(minutes: 30);
      case AutoLockDurationKind.untilClose:
        return null;
    }
  }
}

enum AppThemeModeKind {
  light,
  dark,
  system;

  static AppThemeModeKind fromStorage(String? value) {
    return AppThemeModeKind.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AppThemeModeKind.light,
    );
  }

  ThemeMode get flutterThemeMode {
    switch (this) {
      case AppThemeModeKind.light:
        return ThemeMode.light;
      case AppThemeModeKind.dark:
        return ThemeMode.dark;
      case AppThemeModeKind.system:
        return ThemeMode.system;
    }
  }

  String get label {
    switch (this) {
      case AppThemeModeKind.light:
        return 'Açık';
      case AppThemeModeKind.dark:
        return 'Koyu';
      case AppThemeModeKind.system:
        return 'Sistem';
    }
  }
}

class AppSettings {
  final String clinicName;
  final String specialty;
  final String address;
  final String phone;
  final String email;
  final String website;
  final DateTimeFormatKind dateTimeFormat;
  final TimeFormatKind timeFormat;
  final AutoLockDurationKind autoLockDuration;
  final AppThemeModeKind themeMode;
  final String languageCode;
  final bool appointmentReminderEnabled;
  final bool controlReminderEnabled;
  final bool requireConsentBeforeMessaging;

  const AppSettings({
    required this.clinicName,
    required this.specialty,
    required this.address,
    required this.phone,
    required this.email,
    required this.website,
    required this.dateTimeFormat,
    required this.timeFormat,
    required this.autoLockDuration,
    required this.themeMode,
    required this.languageCode,
    required this.appointmentReminderEnabled,
    required this.controlReminderEnabled,
    required this.requireConsentBeforeMessaging,
  });

  factory AppSettings.defaults() {
    return const AppSettings(
      clinicName: 'Dr. Mehmet Yalçınozan',
      specialty: 'Ortopedi ve Travmatoloji Uzmanı',
      address: 'Bağdat Caddesi, İstanbul',
      phone: '',
      email: '',
      website: '',
      dateTimeFormat: DateTimeFormatKind.shortTurkish,
      timeFormat: TimeFormatKind.hour24,
      autoLockDuration: AutoLockDurationKind.min15,
      themeMode: AppThemeModeKind.light,
      languageCode: 'tr',
      appointmentReminderEnabled: true,
      controlReminderEnabled: true,
      requireConsentBeforeMessaging: true,
    );
  }

  AppSettings copyWith({
    String? clinicName,
    String? specialty,
    String? address,
    String? phone,
    String? email,
    String? website,
    DateTimeFormatKind? dateTimeFormat,
    TimeFormatKind? timeFormat,
    AutoLockDurationKind? autoLockDuration,
    AppThemeModeKind? themeMode,
    String? languageCode,
    bool? appointmentReminderEnabled,
    bool? controlReminderEnabled,
    bool? requireConsentBeforeMessaging,
  }) {
    return AppSettings(
      clinicName: clinicName ?? this.clinicName,
      specialty: specialty ?? this.specialty,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      website: website ?? this.website,
      dateTimeFormat: dateTimeFormat ?? this.dateTimeFormat,
      timeFormat: timeFormat ?? this.timeFormat,
      autoLockDuration: autoLockDuration ?? this.autoLockDuration,
      themeMode: themeMode ?? this.themeMode,
      languageCode: languageCode ?? this.languageCode,
      appointmentReminderEnabled:
          appointmentReminderEnabled ?? this.appointmentReminderEnabled,
      controlReminderEnabled: controlReminderEnabled ?? this.controlReminderEnabled,
      requireConsentBeforeMessaging:
          requireConsentBeforeMessaging ?? this.requireConsentBeforeMessaging,
    );
  }

  /// Yalnızca saat — randevu gün listesi (tarih takvim şeridinde).
  static String formatTime(
    DateTime dateTime,
    DateTimeFormatKind format, {
    TimeFormatKind timeFormat = TimeFormatKind.hour24,
  }) {
    return formatTimePart(dateTime, timeFormat);
  }

  static String formatTimePart(DateTime dateTime, TimeFormatKind timeFormat) {
    final minute = dateTime.minute.toString().padLeft(2, '0');
    switch (timeFormat) {
      case TimeFormatKind.hour24:
        final hour = dateTime.hour.toString().padLeft(2, '0');
        return '$hour:$minute';
      case TimeFormatKind.hour12:
        final period = dateTime.hour >= 12 ? 'PM' : 'AM';
        final hour12 = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
        return '$hour12:$minute $period';
    }
  }

  static String formatTimeOfDay(TimeOfDay time, TimeFormatKind timeFormat) {
    return formatTimePart(
      DateTime(2000, 1, 1, time.hour, time.minute),
      timeFormat,
    );
  }

  /// Tenant `settings_json` veya yerel tercihlerden gelen format ile gösterim.
  static String formatDateTime(
    DateTime dateTime,
    DateTimeFormatKind format, {
    TimeFormatKind timeFormat = TimeFormatKind.hour24,
  }) {
    final timePart = formatTimePart(dateTime, timeFormat);

    switch (format) {
      case DateTimeFormatKind.shortTurkish:
        final day = dateTime.day.toString().padLeft(2, '0');
        final month = dateTime.month.toString().padLeft(2, '0');
        return '$day.$month.${dateTime.year} · $timePart';
      case DateTimeFormatKind.longTurkish:
        const months = [
          'Ocak',
          'Şubat',
          'Mart',
          'Nisan',
          'Mayıs',
          'Haziran',
          'Temmuz',
          'Ağustos',
          'Eylül',
          'Ekim',
          'Kasım',
          'Aralık',
        ];
        const weekdays = [
          'Pazartesi',
          'Salı',
          'Çarşamba',
          'Perşembe',
          'Cuma',
          'Cumartesi',
          'Pazar',
        ];
        final monthName = months[dateTime.month - 1];
        final weekday = weekdays[dateTime.weekday - 1];
        return '${dateTime.day} $monthName ${dateTime.year}, $weekday · $timePart';
      case DateTimeFormatKind.iso:
        final month = dateTime.month.toString().padLeft(2, '0');
        final day = dateTime.day.toString().padLeft(2, '0');
        return '${dateTime.year}-$month-$day · $timePart';
    }
  }
}
