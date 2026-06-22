import 'package:flutter/material.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/constants/app_roles.dart';
import '../../../core/calendar/turkish_special_days.dart';
import '../../../core/tenant/tenant_financial_feature_gate.dart';
import '../../payments/data/payment_notification_data_source.dart';
import '../../payments/data/payment_outstanding_alerts_data_source.dart';
import '../../payments/data/payment_staff_notification_repository_backend_gate.dart';
import '../../payments/models/payment_outstanding_patient_alert.dart';
import '../../payments/widgets/payment_ui_helpers.dart';
import '../../exercises/data/exercise_plan_pending_approval_data_source.dart';
import '../../settings/data/staff_leave_request_repository_provider.dart';
import '../data/dashboard_workbench_snapshot.dart';
import 'dashboard_notification_dismissals.dart';
import 'dashboard_notification_models.dart';

/// Rol ve workbench özetine göre dashboard uyarılarını toplar.
abstract final class DashboardNotificationAggregator {
  static Future<DashboardNotificationSummary> load(
    DashboardWorkbenchSnapshot? snapshot,
  ) async {
    final categories = <DashboardNotificationCategory>[];

    final paymentCategory = await _paymentCategory();
    if (paymentCategory != null) categories.add(paymentCategory);

    final staffPaymentCategory =
        await _assistantFinanceNotificationCategory();
    if (staffPaymentCategory != null) categories.add(staffPaymentCategory);

    final consentCategory = _consentCategory(snapshot);
    if (consentCategory != null) categories.add(consentCategory);

    final inventoryCategory = _inventoryCategory(snapshot);
    if (inventoryCategory != null) categories.add(inventoryCategory);

    final ftrCategory = _ftrCategory(snapshot);
    if (ftrCategory != null) categories.add(ftrCategory);

    final rehabPlanCategory = await _rehabPlanApprovalCategory();
    if (rehabPlanCategory != null) categories.add(rehabPlanCategory);

    final leaveCategory = await _leaveRequestCategory();
    if (leaveCategory != null) categories.add(leaveCategory);

    final holidayCategory = _holidayCategory();
    if (holidayCategory != null) categories.add(holidayCategory);

    return _filterDismissed(DashboardNotificationSummary(categories: categories));
  }

  static DashboardNotificationSummary _filterDismissed(
    DashboardNotificationSummary summary,
  ) {
    final categories = <DashboardNotificationCategory>[];
    for (final category in summary.categories) {
      final entries = category.entries
          .where((entry) => DashboardNotificationDismissals.isActive(entry.id))
          .toList();
      if (entries.isEmpty) continue;
      categories.add(
        DashboardNotificationCategory(
          id: category.id,
          title: category.title,
          icon: category.icon,
          entries: entries,
        ),
      );
    }
    return DashboardNotificationSummary(categories: categories);
  }

  static Future<DashboardNotificationCategory?> _leaveRequestCategory() async {
    if (!AuthSession.canApproveStaffLeave) return null;

    try {
      final count =
          await StaffLeaveRequestRepositoryProvider.repository.countPending();
      if (count <= 0) return null;

      return DashboardNotificationCategory(
        id: 'leave_requests',
        title: 'Personel İzin',
        icon: Icons.beach_access_outlined,
        entries: [
          DashboardNotificationEntry(
            id: 'leave:pending',
            title: 'Onay bekleyen izin talebi',
            subtitle: '$count talep doktor onayı bekliyor',
            route: '/staff-leave-requests',
            count: count,
          ),
        ],
      );
    } catch (_) {
      return null;
    }
  }

  static DashboardNotificationCategory? _holidayCategory() {
    final upcoming = TurkishSpecialDays.upcoming(withinDays: 14);
    if (upcoming.isEmpty) return null;

    return DashboardNotificationCategory(
      id: 'special_days',
      title: 'Özel Günler',
      icon: Icons.celebration_outlined,
      entries: upcoming
          .map(
            (day) => DashboardNotificationEntry(
              id: 'holiday:${day.date.year}-${day.date.month}-${day.date.day}',
              title: day.title,
              subtitle:
                  '${day.date.day} ${TurkishSpecialDays.monthLabel(day.date.month)} · ${TurkishSpecialDays.categoryLabel(day.category)}',
              opensCalendar: true,
            ),
          )
          .toList(growable: false),
    );
  }

  static Future<DashboardNotificationCategory?>
      _assistantFinanceNotificationCategory() async {
    if (!TenantFinancialFeatureGate.assistantFinanceNotificationsEnabled) {
      return null;
    }
    if (!PaymentStaffNotificationRepositoryBackendGate.isAssistantRole(
      AuthSession.currentUser?.role,
    )) {
      return null;
    }

    final items = await PaymentNotificationDataSource.listUnread();
    if (items.isEmpty) return null;

    return DashboardNotificationCategory(
      id: 'payment_staff',
      title: 'Ödeme bildirimleri',
      icon: Icons.notifications_active_outlined,
      entries: items
          .map(
            (n) => DashboardNotificationEntry(
              id: 'payment:${n.id}',
              title: n.title,
              subtitle: '${n.patientName} · ${n.createdByDisplay}',
              route: n.paymentId.isNotEmpty ? '/payments/${n.paymentId}' : null,
              paymentNotification: n,
            ),
          )
          .toList(growable: false),
    );
  }

  static Future<DashboardNotificationCategory?> _paymentCategory() async {
    if (!AuthSession.canViewPayments ||
        !TenantFinancialFeatureGate.paymentRecordsEnabled) {
      return null;
    }

    List<PaymentOutstandingPatientAlert> alerts;
    try {
      alerts = await PaymentOutstandingAlertsDataSource.loadAlerts();
    } catch (_) {
      return null;
    }
    if (alerts.isEmpty) return null;

    return DashboardNotificationCategory(
      id: 'payment',
      title: 'Açık Bakiye',
      icon: Icons.payments_outlined,
      entries: alerts
          .map(
            (alert) => DashboardNotificationEntry(
              id: 'outstanding:${alert.patientId}',
              title: alert.patientName,
              subtitle:
                  '${formatPaymentAmount(alert.totalRemaining)} · '
                  '${alert.openRecordCount} kayıt',
              route: '/payments?patientId=${alert.patientId}',
              count: alert.openRecordCount,
            ),
          )
          .toList(growable: false),
    );
  }

  static DashboardNotificationCategory? _consentCategory(
    DashboardWorkbenchSnapshot? snapshot,
  ) {
    if (!AuthSession.canViewConsents || snapshot == null) return null;
    final count = snapshot.pendingConsentCount;
    if (count == null || count <= 0) return null;

    return DashboardNotificationCategory(
      id: 'consent',
      title: 'KVKK / Onam',
      icon: Icons.shield_outlined,
      entries: [
        DashboardNotificationEntry(
          id: 'consent:pending',
          title: 'Bekleyen onam',
          subtitle: '$count kayıt inceleme bekliyor',
          route: '/consents',
          count: count,
        ),
      ],
    );
  }

  static DashboardNotificationCategory? _inventoryCategory(
    DashboardWorkbenchSnapshot? snapshot,
  ) {
    if (!AuthSession.canViewInventory || snapshot == null) return null;
    if (snapshot.inventoryUnavailable) return null;

    final entries = <DashboardNotificationEntry>[];
    final low = snapshot.lowStockCount ?? 0;
    final expiring = snapshot.expiringSoonCount ?? 0;
    final expired = snapshot.expiredStockCount ?? 0;

    if (low > 0) {
      entries.add(
        DashboardNotificationEntry(
          id: 'inventory:low',
          title: 'Düşük stok',
          subtitle: '$low kalem kritik seviyede',
          route: '/inventory',
          count: low,
        ),
      );
    }
    if (expiring > 0) {
      entries.add(
        DashboardNotificationEntry(
          id: 'inventory:expiring',
          title: 'SKT yaklaşan',
          subtitle: '$expiring kalem',
          route: '/inventory',
          count: expiring,
        ),
      );
    }
    if (expired > 0) {
      entries.add(
        DashboardNotificationEntry(
          id: 'inventory:expired',
          title: 'SKT geçmiş',
          subtitle: '$expired kalem',
          route: '/inventory',
          count: expired,
        ),
      );
    }

    if (entries.isEmpty) return null;

    return DashboardNotificationCategory(
      id: 'inventory',
      title: 'Stok / Sarf',
      icon: Icons.inventory_2_outlined,
      entries: entries,
    );
  }

  static DashboardNotificationCategory? _ftrCategory(
    DashboardWorkbenchSnapshot? snapshot,
  ) {
    if (!AuthSession.canViewPhysiotherapy || snapshot == null) return null;
    if (snapshot.physiotherapyReferralsUnavailable) return null;

    final count = snapshot.newPhysiotherapyReferralCount;
    if (count == null || count <= 0) return null;

    return DashboardNotificationCategory(
      id: 'ftr',
      title: 'Rehabilitasyon',
      icon: Icons.accessibility_new_outlined,
      entries: [
        DashboardNotificationEntry(
          id: 'ftr:new',
          title: 'Rehabilitasyon hastası var',
          subtitle: '$count hasta randevu bekliyor',
          route: '/physiotherapy/referrals/pending',
          count: count,
        ),
      ],
    );
  }

  static Future<DashboardNotificationCategory?> _rehabPlanApprovalCategory() async {
    if (!AuthSession.canApproveExercisePlans) return null;

    try {
      final count = await ExercisePlanPendingApprovalDataSource.countPending();
      if (count <= 0) return null;

      return DashboardNotificationCategory(
        id: 'rehab_plan_approval',
        title: 'Rehabilitasyon Onayı',
        icon: Icons.fact_check_outlined,
        entries: [
          DashboardNotificationEntry(
            id: 'rehab:pending_approval',
            title: 'Onay bekleyen rehabilitasyon planı',
            subtitle: '$count plan doktor onayı bekliyor',
            route: '/exercise-plans?approvedByDoctor=false',
            count: count,
          ),
        ],
      );
    } catch (_) {
      return null;
    }
  }
}
