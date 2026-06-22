/// PostgREST RPC yanıtını allowlist DTO satır listesine çevirir.
abstract final class ClinicalSummaryRpcResponseParser {
  static List<Map<String, dynamic>> coerceRowList(dynamic response) {
    if (response == null) return const [];

    if (response is List) {
      return response
          .map(_coerceRow)
          .whereType<Map<String, dynamic>>()
          .toList();
    }

    final single = _coerceRow(response);
    if (single != null) return [single];
    return const [];
  }

  static Map<String, dynamic>? coerceSingleRow(dynamic response) {
    final rows = coerceRowList(response);
    if (rows.isEmpty) return null;
    return rows.first;
  }

  static Map<String, dynamic>? _coerceRow(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    return null;
  }
}
