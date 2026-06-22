/// Muayene protokol numarası — tenant içi yıllık sıra (ör. `M-2026-00001`).
abstract final class ClinicalEncounterProtocolNumberHelper {
  static const String defaultTemplate = 'M-{year}-{seq}';
  static const int defaultSeqPadding = 5;

  static String nextFromExisting(
    Iterable<String> protocolNumbers, {
    String template = defaultTemplate,
    int seqPadding = defaultSeqPadding,
    int? year,
  }) {
    final y = year ?? DateTime.now().year;
    final regex = _matcherForTemplate(template);
    var maxSeq = 0;

    for (final raw in protocolNumbers) {
      final value = raw.trim();
      if (value.isEmpty) continue;
      final match = regex.firstMatch(value);
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

    final seqStr = (maxSeq + 1).toString().padLeft(seqPadding, '0');
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
