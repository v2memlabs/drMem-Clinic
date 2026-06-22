import '../models/clinical_report.dart';

abstract final class ClinicalReportIstirahatBodyTemplate {
  static const String defaultRestrictionNotes =
      'Ağır aktivite ve uzun süre ayakta kalma kısıtlanmalıdır.';

  static String compose({
    required String diagnosis,
    required ClinicalReportTreatmentApproach treatmentApproach,
    required DateTime startDate,
    required DateTime endDate,
    required int restDays,
    String? restrictionNotes,
  }) {
    final dx = diagnosis.trim().isEmpty ? '…' : diagnosis.trim();
    final treatment = treatmentApproachLabel(treatmentApproach);
    final start = _formatDate(startDate);
    final end = _formatDate(endDate);
    final restriction = (restrictionNotes ?? defaultRestrictionNotes).trim();

    final main =
        '$dx tanısıyla $treatment tedavi ile takip edilen hastanın '
        '$start – $end tarihleri arasında $restDays gün istirahati uygundur.';

    if (restriction.isEmpty) return main;
    return '$main\n$restriction';
  }

  static int? restDaysBetween(DateTime start, DateTime end) {
    final s = _dateOnly(start);
    final e = _dateOnly(end);
    if (e.isBefore(s)) return null;
    return e.difference(s).inDays + 1;
  }

  static DateTime? endDateFromStartAndDays(DateTime start, int days) {
    if (days < 1) return null;
    final s = _dateOnly(start);
    return s.add(Duration(days: days - 1));
  }

  /// İstirahat bitiş tarihinin ertesi günü.
  static DateTime? returnToWorkDate(DateTime endDate) {
    return _dateOnly(endDate).add(const Duration(days: 1));
  }

  static String returnToWorkDateLabel(DateTime endDate) {
    final date = returnToWorkDate(endDate);
    if (date == null) return '';
    return 'İşe başlama tarihi: ${_formatDate(date)}';
  }

  static String _formatDate(DateTime date) {
    final local = date.toLocal();
    final d = local.day.toString().padLeft(2, '0');
    final m = local.month.toString().padLeft(2, '0');
    return '$d.$m.${local.year}';
  }

  static DateTime _dateOnly(DateTime date) {
    final local = date.toLocal();
    return DateTime(local.year, local.month, local.day);
  }
}
