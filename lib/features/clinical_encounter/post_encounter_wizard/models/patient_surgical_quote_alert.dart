import 'surgical_quote_currency.dart';

/// Hasta düzeyinde cerrahi teklif uyarısı — ödeme kaydına yazılmaz.
class PatientSurgicalQuoteAlert {
  final String id;
  final String patientId;
  final String patientName;
  final String clinicalEncounterId;
  final String procedureNote;
  final double? quotedAmount;
  final SurgicalQuoteCurrency currency;
  final DateTime createdAt;
  final String createdByDisplay;
  final DateTime? dismissedAt;
  final String? dismissedByDisplay;

  const PatientSurgicalQuoteAlert({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.clinicalEncounterId,
    required this.procedureNote,
    this.quotedAmount,
    this.currency = SurgicalQuoteCurrency.try_,
    required this.createdAt,
    required this.createdByDisplay,
    this.dismissedAt,
    this.dismissedByDisplay,
  });

  bool get isDismissed => dismissedAt != null;

  bool get hasQuotedAmount =>
      quotedAmount != null && quotedAmount! > 0;

  PatientSurgicalQuoteAlert dismiss({
    required DateTime at,
    required String dismissedBy,
  }) {
    return PatientSurgicalQuoteAlert(
      id: id,
      patientId: patientId,
      patientName: patientName,
      clinicalEncounterId: clinicalEncounterId,
      procedureNote: procedureNote,
      quotedAmount: quotedAmount,
      currency: currency,
      createdAt: createdAt,
      createdByDisplay: createdByDisplay,
      dismissedAt: at,
      dismissedByDisplay: dismissedBy,
    );
  }
}
