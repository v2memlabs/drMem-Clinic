import 'package:flutter/material.dart';

enum SpecialDayCategory {
  national,
  islamic,
  christian,
}

class SpecialDay {
  final DateTime date;
  final String title;
  final SpecialDayCategory category;

  const SpecialDay({
    required this.date,
    required this.title,
    required this.category,
  });

  DateTime get calendarDate =>
      DateTime(date.year, date.month, date.day);
}

/// Türkiye milli, İslami (Diyanet) ve Hristiyan özel günleri.
abstract final class TurkishSpecialDays {
  static const _monthNames = [
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

  static String monthLabel(int month) => _monthNames[month - 1];

  static List<SpecialDay> forYear(int year) {
    final days = <SpecialDay>[
      ..._fixedNational(year),
      ..._religiousForYear(year),
    ];
    days.sort((a, b) => a.calendarDate.compareTo(b.calendarDate));
    return days;
  }

  static List<SpecialDay> forMonth(int year, int month) {
    return forYear(year)
        .where((d) => d.date.month == month)
        .toList(growable: false);
  }

  static List<SpecialDay> onDate(DateTime date) {
    final key = DateTime(date.year, date.month, date.day);
    return forYear(date.year)
        .where((d) => d.calendarDate == key)
        .toList(growable: false);
  }

  static List<SpecialDay> upcoming({int withinDays = 14}) {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final end = start.add(Duration(days: withinDays));
    final years = {start.year, end.year};
    final all = years.expand(forYear).toList();
    return all
        .where((d) {
          final day = d.calendarDate;
          return !day.isBefore(start) && !day.isAfter(end);
        })
        .toList(growable: false);
  }

  static Color categoryColor(SpecialDayCategory category) {
    switch (category) {
      case SpecialDayCategory.national:
        return const Color(0xFF1B4D89);
      case SpecialDayCategory.islamic:
        return const Color(0xFF0F766E);
      case SpecialDayCategory.christian:
        return const Color(0xFF7C3AED);
    }
  }

  static String categoryLabel(SpecialDayCategory category) {
    switch (category) {
      case SpecialDayCategory.national:
        return 'Milli';
      case SpecialDayCategory.islamic:
        return 'İslami';
      case SpecialDayCategory.christian:
        return 'Hristiyan';
    }
  }

  static List<SpecialDay> _fixedNational(int year) {
    return [
      SpecialDay(
        date: DateTime(year, 1, 1),
        title: 'Yılbaşı',
        category: SpecialDayCategory.national,
      ),
      SpecialDay(
        date: DateTime(year, 4, 23),
        title: 'Ulusal Egemenlik ve Çocuk Bayramı',
        category: SpecialDayCategory.national,
      ),
      SpecialDay(
        date: DateTime(year, 5, 1),
        title: 'Emek ve Dayanışma Günü',
        category: SpecialDayCategory.national,
      ),
      SpecialDay(
        date: DateTime(year, 5, 19),
        title: 'Atatürk\'ü Anma, Gençlik ve Spor Bayramı',
        category: SpecialDayCategory.national,
      ),
      SpecialDay(
        date: DateTime(year, 7, 15),
        title: 'Demokrasi ve Milli Birlik Günü',
        category: SpecialDayCategory.national,
      ),
      SpecialDay(
        date: DateTime(year, 8, 30),
        title: 'Zafer Bayramı',
        category: SpecialDayCategory.national,
      ),
      SpecialDay(
        date: DateTime(year, 10, 29),
        title: 'Cumhuriyet Bayramı',
        category: SpecialDayCategory.national,
      ),
      SpecialDay(
        date: DateTime(year, 11, 10),
        title: 'Atatürk\'ü Anma Günü',
        category: SpecialDayCategory.national,
      ),
    ];
  }

  static List<SpecialDay> _religiousForYear(int year) {
    switch (year) {
      case 2025:
        return [
          SpecialDay(
            date: DateTime(2025, 3, 29),
            title: 'Ramazan Bayramı Arefesi',
            category: SpecialDayCategory.islamic,
          ),
          SpecialDay(
            date: DateTime(2025, 3, 30),
            title: 'Ramazan Bayramı (1. gün)',
            category: SpecialDayCategory.islamic,
          ),
          SpecialDay(
            date: DateTime(2025, 3, 31),
            title: 'Ramazan Bayramı (2. gün)',
            category: SpecialDayCategory.islamic,
          ),
          SpecialDay(
            date: DateTime(2025, 4, 1),
            title: 'Ramazan Bayramı (3. gün)',
            category: SpecialDayCategory.islamic,
          ),
          SpecialDay(
            date: DateTime(2025, 4, 18),
            title: 'Kutsal Cuma',
            category: SpecialDayCategory.christian,
          ),
          SpecialDay(
            date: DateTime(2025, 4, 20),
            title: 'Paskalya',
            category: SpecialDayCategory.christian,
          ),
          SpecialDay(
            date: DateTime(2025, 6, 5),
            title: 'Kurban Bayramı Arefesi',
            category: SpecialDayCategory.islamic,
          ),
          SpecialDay(
            date: DateTime(2025, 6, 6),
            title: 'Kurban Bayramı (1. gün)',
            category: SpecialDayCategory.islamic,
          ),
          SpecialDay(
            date: DateTime(2025, 6, 7),
            title: 'Kurban Bayramı (2. gün)',
            category: SpecialDayCategory.islamic,
          ),
          SpecialDay(
            date: DateTime(2025, 6, 8),
            title: 'Kurban Bayramı (3. gün)',
            category: SpecialDayCategory.islamic,
          ),
          SpecialDay(
            date: DateTime(2025, 6, 9),
            title: 'Kurban Bayramı (4. gün)',
            category: SpecialDayCategory.islamic,
          ),
          SpecialDay(
            date: DateTime(2025, 12, 25),
            title: 'Noel',
            category: SpecialDayCategory.christian,
          ),
        ];
      case 2026:
        return [
          SpecialDay(
            date: DateTime(2026, 3, 18),
            title: 'Ramazan Bayramı Arefesi',
            category: SpecialDayCategory.islamic,
          ),
          SpecialDay(
            date: DateTime(2026, 3, 19),
            title: 'Ramazan Bayramı (1. gün)',
            category: SpecialDayCategory.islamic,
          ),
          SpecialDay(
            date: DateTime(2026, 3, 20),
            title: 'Ramazan Bayramı (2. gün)',
            category: SpecialDayCategory.islamic,
          ),
          SpecialDay(
            date: DateTime(2026, 3, 21),
            title: 'Ramazan Bayramı (3. gün)',
            category: SpecialDayCategory.islamic,
          ),
          SpecialDay(
            date: DateTime(2026, 4, 3),
            title: 'Kutsal Cuma',
            category: SpecialDayCategory.christian,
          ),
          SpecialDay(
            date: DateTime(2026, 4, 5),
            title: 'Paskalya',
            category: SpecialDayCategory.christian,
          ),
          SpecialDay(
            date: DateTime(2026, 5, 26),
            title: 'Kurban Bayramı Arefesi',
            category: SpecialDayCategory.islamic,
          ),
          SpecialDay(
            date: DateTime(2026, 5, 27),
            title: 'Kurban Bayramı (1. gün)',
            category: SpecialDayCategory.islamic,
          ),
          SpecialDay(
            date: DateTime(2026, 5, 28),
            title: 'Kurban Bayramı (2. gün)',
            category: SpecialDayCategory.islamic,
          ),
          SpecialDay(
            date: DateTime(2026, 5, 29),
            title: 'Kurban Bayramı (3. gün)',
            category: SpecialDayCategory.islamic,
          ),
          SpecialDay(
            date: DateTime(2026, 5, 30),
            title: 'Kurban Bayramı (4. gün)',
            category: SpecialDayCategory.islamic,
          ),
          SpecialDay(
            date: DateTime(2026, 12, 25),
            title: 'Noel',
            category: SpecialDayCategory.christian,
          ),
        ];
      case 2027:
        return [
          SpecialDay(
            date: DateTime(2027, 3, 7),
            title: 'Ramazan Bayramı Arefesi',
            category: SpecialDayCategory.islamic,
          ),
          SpecialDay(
            date: DateTime(2027, 3, 8),
            title: 'Ramazan Bayramı (1. gün)',
            category: SpecialDayCategory.islamic,
          ),
          SpecialDay(
            date: DateTime(2027, 3, 9),
            title: 'Ramazan Bayramı (2. gün)',
            category: SpecialDayCategory.islamic,
          ),
          SpecialDay(
            date: DateTime(2027, 3, 10),
            title: 'Ramazan Bayramı (3. gün)',
            category: SpecialDayCategory.islamic,
          ),
          SpecialDay(
            date: DateTime(2027, 3, 26),
            title: 'Kutsal Cuma',
            category: SpecialDayCategory.christian,
          ),
          SpecialDay(
            date: DateTime(2027, 3, 28),
            title: 'Paskalya',
            category: SpecialDayCategory.christian,
          ),
          SpecialDay(
            date: DateTime(2027, 5, 15),
            title: 'Kurban Bayramı Arefesi',
            category: SpecialDayCategory.islamic,
          ),
          SpecialDay(
            date: DateTime(2027, 5, 16),
            title: 'Kurban Bayramı (1. gün)',
            category: SpecialDayCategory.islamic,
          ),
          SpecialDay(
            date: DateTime(2027, 5, 17),
            title: 'Kurban Bayramı (2. gün)',
            category: SpecialDayCategory.islamic,
          ),
          SpecialDay(
            date: DateTime(2027, 5, 18),
            title: 'Kurban Bayramı (3. gün)',
            category: SpecialDayCategory.islamic,
          ),
          SpecialDay(
            date: DateTime(2027, 5, 19),
            title: 'Kurban Bayramı (4. gün)',
            category: SpecialDayCategory.islamic,
          ),
          SpecialDay(
            date: DateTime(2027, 12, 25),
            title: 'Noel',
            category: SpecialDayCategory.christian,
          ),
        ];
      default:
        return [
          SpecialDay(
            date: DateTime(year, 12, 25),
            title: 'Noel',
            category: SpecialDayCategory.christian,
          ),
        ];
    }
  }
}
