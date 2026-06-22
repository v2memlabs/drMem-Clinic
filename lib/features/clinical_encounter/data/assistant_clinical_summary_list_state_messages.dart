/// Assistant klinik özet listesi — boş durum başlık/açıklama.
abstract final class AssistantClinicalSummaryListStateMessages {
  static const String emptySearchTitle = 'Klinik özet bulunamadı';
  static const String emptyFilterTitle = 'Klinik özet bulunamadı';
  static const String emptySourceTitle = 'Henüz klinik özet yok';

  static String emptyTitle({
    required String search,
    required bool hasPatientFilter,
    required bool emptySourceList,
  }) {
    if (search.trim().isNotEmpty) return emptySearchTitle;
    if (hasPatientFilter && emptySourceList) return emptySourceTitle;
    if (emptySourceList) return emptySourceTitle;
    return emptyFilterTitle;
  }

  static String emptyDescription({
    required String search,
    required bool hasPatientFilter,
    required bool emptySourceList,
  }) {
    if (search.trim().isNotEmpty) {
      return 'Arama kriterlerinizi değiştirerek tekrar deneyin.';
    }
    if (hasPatientFilter && emptySourceList) {
      return 'Bu hasta için kayıtlı güvenli klinik özet bulunmuyor.';
    }
    if (emptySourceList) {
      return 'Görüntülenebilecek klinik özet bulunamadı.';
    }
    return 'Arama kriterlerinizi değiştirerek tekrar deneyin.';
  }
}
