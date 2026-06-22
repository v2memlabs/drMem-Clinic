/// Aktif tenant abonelik ve kullanım özeti (salt okunur).
class TenantSubscriptionSummary {
  final String planKey;
  final String planLabel;
  final String status;
  final String statusLabel;
  final DateTime? periodEnd;
  final int seatUsed;
  final int? seatLimit;
  final int patientCount;
  final int? patientLimit;
  final bool fromRemoteRecord;

  const TenantSubscriptionSummary({
    required this.planKey,
    required this.planLabel,
    required this.status,
    required this.statusLabel,
    this.periodEnd,
    required this.seatUsed,
    this.seatLimit,
    required this.patientCount,
    this.patientLimit,
    this.fromRemoteRecord = false,
  });

  String? get renewalLabel {
    final end = periodEnd;
    if (end == null) return null;
    final local = end.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    return '$day.$month.${local.year}';
  }

  String formatUsage({required int used, int? limit}) {
    if (limit == null) return used.toString();
    return '$used / $limit';
  }
}
