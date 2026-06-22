import '../../settings/models/patient_registration_settings.dart';

/// Tenant içi dosya numarası üretimi — client-side MVP (prod öncesi RPC önerilir).
abstract final class PatientFileNumberHelper {
  /// Mevcut numaralardan tenant formatına göre sıradaki değeri üretir.
  static String nextFromExisting(
    Iterable<String> fileNumbers, {
    PatientRegistrationSettings settings = const PatientRegistrationSettings(),
    int? year,
  }) {
    final effective = settings.validate() == null
        ? settings
        : const PatientRegistrationSettings();

    final y = year ?? DateTime.now().year;
    final template = effective.fileNumberFormat.trim();
    final regex = _matcherForTemplate(template);
    var maxSeq = 0;

    for (final raw in fileNumbers) {
      final fn = raw.trim();
      if (fn.isEmpty) continue;
      final match = regex.firstMatch(fn);
      if (match == null) continue;
      if (template.contains('{year}')) {
        final matchedYear = match.namedGroup('year');
        if (matchedYear != null && int.tryParse(matchedYear) != y) {
          continue;
        }
      }
      final seq = int.tryParse(match.namedGroup('seq') ?? '');
      if (seq != null && seq > maxSeq) maxSeq = seq;
    }

    final seqStr = (maxSeq + 1).toString().padLeft(effective.seqPadding, '0');
    return template
        .replaceAll('{year}', y.toString())
        .replaceAll('{seq}', seqStr);
  }

  static RegExp _matcherForTemplate(String template) {
    var pattern = RegExp.escape(template);
    pattern = pattern.replaceAll(RegExp.escape('{year}'), r'(?<year>\d{4})');
    pattern = pattern.replaceAll(RegExp.escape('{seq}'), r'(?<seq>\d+)');
    return RegExp('^$pattern\$');
  }
}
