import 'package:flutter/material.dart';

import '../../payments/models/payment_staff_notification.dart';

/// Dashboard uyarı özeti — kategorize bildirimler.
class DashboardNotificationSummary {
  final List<DashboardNotificationCategory> categories;

  const DashboardNotificationSummary({this.categories = const []});

  int get totalCount =>
      categories.fold(0, (sum, category) => sum + category.count);

  bool get hasAlerts => totalCount > 0;

  DashboardNotificationSummary withoutEntry(String entryId) {
    final nextCategories = <DashboardNotificationCategory>[];
    for (final category in categories) {
      final nextEntries =
          category.entries.where((entry) => entry.id != entryId).toList();
      if (nextEntries.isEmpty) continue;
      nextCategories.add(
        DashboardNotificationCategory(
          id: category.id,
          title: category.title,
          icon: category.icon,
          entries: nextEntries,
        ),
      );
    }
    return DashboardNotificationSummary(categories: nextCategories);
  }

  DashboardNotificationSummary withoutEntries(Iterable<String> entryIds) {
    final ids = entryIds.toSet();
    final nextCategories = <DashboardNotificationCategory>[];
    for (final category in categories) {
      final nextEntries =
          category.entries.where((entry) => !ids.contains(entry.id)).toList();
      if (nextEntries.isEmpty) continue;
      nextCategories.add(
        DashboardNotificationCategory(
          id: category.id,
          title: category.title,
          icon: category.icon,
          entries: nextEntries,
        ),
      );
    }
    return DashboardNotificationSummary(categories: nextCategories);
  }

  Iterable<String> get entryIds =>
      categories.expand((category) => category.entries.map((entry) => entry.id));
}

class DashboardNotificationCategory {
  final String id;
  final String title;
  final IconData icon;
  final List<DashboardNotificationEntry> entries;

  const DashboardNotificationCategory({
    required this.id,
    required this.title,
    required this.icon,
    required this.entries,
  });

  int get count => entries.fold(0, (sum, entry) => sum + entry.count);
}

class DashboardNotificationEntry {
  final String id;
  final String title;
  final String? subtitle;
  final String? route;
  final int count;
  final PaymentStaffNotification? paymentNotification;
  final bool opensCalendar;

  const DashboardNotificationEntry({
    required this.id,
    required this.title,
    this.subtitle,
    this.route,
    this.count = 1,
    this.paymentNotification,
    this.opensCalendar = false,
  });
}
