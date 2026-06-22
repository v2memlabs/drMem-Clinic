/// Yerel ortopedi ICD subset kaydı (offline autocomplete).
class IcdCode {
  const IcdCode({
    required this.code,
    required this.titleTr,
    this.titleEn,
    this.category,
    this.keywords = const [],
    this.isCommonOrthopedic = false,
  });

  final String code;
  final String titleTr;
  final String? titleEn;
  final String? category;
  final List<String> keywords;
  final bool isCommonOrthopedic;

  factory IcdCode.fromJson(Map<String, dynamic> json) {
    final rawKeywords = json['keywords'];
    return IcdCode(
      code: (json['code'] as String? ?? '').trim(),
      titleTr: (json['titleTr'] as String? ?? '').trim(),
      titleEn: (json['titleEn'] as String?)?.trim(),
      category: (json['category'] as String?)?.trim(),
      keywords: rawKeywords is List
          ? rawKeywords.map((e) => e.toString().trim()).where((s) => s.isNotEmpty).toList()
          : const [],
      isCommonOrthopedic: json['isCommonOrthopedic'] as bool? ?? false,
    );
  }

  String get displayLabel => formatIcdDisplay(code, titleTr);

  String get searchText {
    final parts = <String>[
      code,
      titleTr,
      if (titleEn != null && titleEn!.isNotEmpty) titleEn!,
      if (category != null && category!.isNotEmpty) category!,
      ...keywords,
    ];
    return parts.join(' ');
  }

  bool matches(String query) {
    final q = normalizeIcdSearchText(query);
    if (q.isEmpty) return isCommonOrthopedic;
    final codeNorm = normalizeIcdSearchText(code);
    if (codeNorm.startsWith(q)) return true;
    if (normalizeIcdSearchText(titleTr).contains(q)) return true;
    if (titleEn != null && normalizeIcdSearchText(titleEn!).contains(q)) return true;
    if (category != null && normalizeIcdSearchText(category!).contains(q)) return true;
    for (final kw in keywords) {
      if (normalizeIcdSearchText(kw).contains(q)) return true;
    }
    return false;
  }
}

/// ICD kodu ve başlığı tek satırda gösterim.
String formatIcdDisplay(String code, [String? title]) {
  final c = code.trim();
  if (c.isEmpty) return '';
  final t = (title ?? '').trim();
  if (t.isEmpty) return c;
  return '$c — $t';
}

/// Türkçe karakterler için basit arama normalizasyonu.
String normalizeIcdSearchText(String input) {
  return input
      .toLowerCase()
      .replaceAll('ı', 'i')
      .replaceAll('İ', 'i')
      .replaceAll('ş', 's')
      .replaceAll('Ş', 's')
      .replaceAll('ğ', 'g')
      .replaceAll('Ğ', 'g')
      .replaceAll('ü', 'u')
      .replaceAll('Ü', 'u')
      .replaceAll('ö', 'o')
      .replaceAll('Ö', 'o')
      .replaceAll('ç', 'c')
      .replaceAll('Ç', 'c')
      .trim();
}
