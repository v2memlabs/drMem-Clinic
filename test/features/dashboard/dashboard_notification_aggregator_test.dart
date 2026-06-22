import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/core/data/backend_config.dart';
import 'package:v2mem_clinic/core/data/data_backend.dart';
import 'package:v2mem_clinic/core/tenant/tenant_financial_feature_gate.dart';
import 'package:v2mem_clinic/features/payments/data/payment_staff_notification_repository.dart';
import 'package:v2mem_clinic/features/payments/models/payment_staff_notification.dart';
import 'package:v2mem_clinic/features/dashboard/data/dashboard_workbench_snapshot.dart';
import 'package:v2mem_clinic/features/dashboard/notifications/dashboard_notification_aggregator.dart';
import 'package:v2mem_clinic/features/dashboard/notifications/dashboard_notification_dismissals.dart';
import 'package:v2mem_clinic/features/dashboard/notifications/dashboard_notification_models.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';

void main() {
  tearDown(() {
    AuthSession.clear();
    DashboardNotificationDismissals.reset();
    TenantFinancialFeatureGate.reset();
    AppBackendConfig.activeBackend = DataBackend.mock;
    PaymentStaffNotificationRepository.instance.markAllRead(
      readBy: 'test',
      at: DateTime.now(),
    );
  });

  test('assistant finance notifications appear without payment view permission',
      () async {
    AuthSession.setUser(
      AppUser(
        id: 'u1',
        username: 'asistan',
        displayName: 'Asistan',
        role: AppRoles.assistant,
      ),
    );

    PaymentStaffNotificationRepository.instance.add(
      PaymentStaffNotification(
        id: 'notif-1',
        paymentId: 'pay-1',
        patientId: 'p1',
        patientName: 'Ayşe Yılmaz',
        title: 'Ödeme inceleme bekliyor',
        body: 'Ayşe Yılmaz — Muayene · 500.00 TL',
        createdByRole: AppRoles.doctor,
        createdByDisplay: 'Dr. Test',
        createdAt: DateTime(2026, 6, 1),
      ),
    );

    final summary = await DashboardNotificationAggregator.load(null);

    expect(
      summary.categories.any((category) => category.id == 'payment_staff'),
      isTrue,
    );
    expect(
      summary.categories
          .firstWhere((category) => category.id == 'payment_staff')
          .entries
          .first
          .title,
      'Ödeme inceleme bekliyor',
    );
  });

  test('assistant snapshot aggregates consent and inventory counts', () async {
    AuthSession.setUser(
      AppUser(
        id: 'u1',
        username: 'asistan',
        displayName: 'Asistan',
        role: AppRoles.assistant,
      ),
    );

    const snapshot = DashboardWorkbenchSnapshot(
      pendingConsentCount: 2,
      lowStockCount: 1,
      expiringSoonCount: 3,
    );

    final summary = await DashboardNotificationAggregator.load(snapshot);

    expect(summary.totalCount, greaterThanOrEqualTo(2));
    expect(
      summary.categories.any((category) => category.id == 'consent'),
      isTrue,
    );
  });

  test('dismissed entries are excluded from dashboard summary', () async {
    AuthSession.setUser(
      AppUser(
        id: 'u1',
        username: 'asistan',
        displayName: 'Asistan',
        role: AppRoles.assistant,
      ),
    );

    DashboardNotificationDismissals.dismiss('consent:pending');

    const snapshot = DashboardWorkbenchSnapshot(
      pendingConsentCount: 2,
      lowStockCount: 1,
    );

    final summary = await DashboardNotificationAggregator.load(snapshot);

    expect(
      summary.categories.any((category) => category.id == 'consent'),
      isFalse,
    );
  });

  test('summary withoutEntry removes one alert from count', () {
    const summary = DashboardNotificationSummary(
      categories: [
        DashboardNotificationCategory(
          id: 'inventory',
          title: 'Stok',
          icon: Icons.inventory_2_outlined,
          entries: [
            DashboardNotificationEntry(
              id: 'inventory:low',
              title: 'Düşük stok',
              count: 2,
            ),
            DashboardNotificationEntry(
              id: 'inventory:expired',
              title: 'SKT geçmiş',
              count: 1,
            ),
          ],
        ),
      ],
    );

    final next = summary.withoutEntry('inventory:low');

    expect(next.totalCount, 1);
  });
}
