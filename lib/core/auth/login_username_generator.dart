/// Görünen addan giriş kullanıcı adı önerisi üretir.
abstract final class LoginUsernameGenerator {
  static const _turkishMap = {
    'ç': 'c',
    'Ç': 'c',
    'ğ': 'g',
    'Ğ': 'g',
    'ı': 'i',
    'İ': 'i',
    'ö': 'o',
    'Ö': 'o',
    'ş': 's',
    'Ş': 's',
    'ü': 'u',
    'Ü': 'u',
  };

  static String suggestFromDisplayName(String displayName) {
    final parts = displayName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '';

    final first = _normalizeToken(parts.first);
    final last = parts.length > 1 ? _normalizeToken(parts.last) : '';

    if (first.isEmpty && last.isEmpty) return '';
    if (last.isEmpty) return first.length >= 3 ? first : '';
    if (first.isEmpty) return last.length >= 3 ? last : '';

    final initial = first[0];
    final candidate = '$initial$last';
    return normalize(candidate);
  }

  static String normalize(String raw) {
    final transliterated = StringBuffer();
    for (final ch in raw.runes) {
      final char = String.fromCharCode(ch);
      transliterated.write(_turkishMap[char] ?? char);
    }
    return transliterated
        .toString()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9._]'), '');
  }

  static bool isValid(String username) {
    final normalized = normalize(username);
    return normalized.length >= 3 && normalized.length <= 32;
  }

  static String _normalizeToken(String token) {
    return normalize(token);
  }
}
