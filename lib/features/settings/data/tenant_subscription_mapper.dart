import '../models/tenant_subscription_summary.dart';
import 'saas_plan_labels.dart';

abstract final class TenantSubscriptionMapper {
  static TenantSubscriptionSummary fromParts({
    required Map<String, dynamic>? subscriptionRow,
    required List<Map<String, dynamic>> usageLimitRows,
    required int seatUsed,
    required int patientCount,
    bool fromRemoteRecord = true,
  }) {
    final planKey =
        subscriptionRow?['plan_key']?.toString().trim().isNotEmpty == true
            ? subscriptionRow!['plan_key'].toString().trim()
            : 'demo';
    final status =
        subscriptionRow?['status']?.toString().trim().isNotEmpty == true
            ? subscriptionRow!['status'].toString().trim()
            : 'active';
    final periodEnd = _parseDateTime(subscriptionRow?['current_period_end']);

    int? patientLimit;
    int? seatLimit;
    for (final row in usageLimitRows) {
      final key = row['metric_key']?.toString().trim();
      final value = _parseInt(row['limit_value']);
      if (key == 'patient_records') {
        patientLimit = value;
      } else if (key == 'seats') {
        seatLimit = value;
      }
    }

    seatLimit ??= SaasPlanLabels.defaultSeatLimitForPlan(planKey);

    return TenantSubscriptionSummary(
      planKey: planKey,
      planLabel: SaasPlanLabels.planLabel(planKey),
      status: status,
      statusLabel: SaasPlanLabels.statusLabel(status),
      periodEnd: periodEnd,
      seatUsed: seatUsed,
      seatLimit: seatLimit,
      patientCount: patientCount,
      patientLimit: patientLimit,
      fromRemoteRecord: fromRemoteRecord,
    );
  }

  static DateTime? _parseDateTime(Object? raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw.toLocal();
    return DateTime.tryParse(raw.toString())?.toLocal();
  }

  static int? _parseInt(Object? raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString() ?? '');
  }
}
