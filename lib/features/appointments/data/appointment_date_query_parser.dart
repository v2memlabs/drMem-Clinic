/// Route `date` query → takvim günü (create prefill only).
///
/// Biçim: `yyyy-MM-dd` (ör. `2026-06-07`).
abstract final class AppointmentDateQueryParser {
  static String toQuery(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final dayStr = d.day.toString().padLeft(2, '0');
    return '$y-$m-$dayStr';
  }

  static DateTime? fromQuery(String? raw) {
    final q = raw?.trim();
    if (q == null || q.isEmpty) return null;

    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(q);
    if (match == null) return null;

    final y = int.tryParse(match.group(1)!);
    final m = int.tryParse(match.group(2)!);
    final d = int.tryParse(match.group(3)!);
    if (y == null || m == null || d == null) return null;
    if (m < 1 || m > 12 || d < 1 || d > 31) return null;

    final date = DateTime(y, m, d);
    if (date.year != y || date.month != m || date.day != d) return null;
    return date;
  }
}
