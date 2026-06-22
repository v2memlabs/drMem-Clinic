/// FTR klinik özet listesi — boş durum başlık/açıklama.
abstract final class PhysiotherapistClinicalSummaryListStateMessages {
  static const String emptySearchTitle = 'FTR klinik özeti bulunamadı';
  static const String emptyFilterTitle = 'FTR klinik özeti bulunamadı';
  static const String emptySourceTitle = 'Henüz FTR klinik özeti yok';

  static String emptyTitle({
    required String search,
    required bool hasPatientFilter,
    required bool hasRegionFilter,
    required bool hasStatusFilter,
    required bool emptySourceList,
  }) {
    if (search.trim().isNotEmpty) return emptySearchTitle;
    if (hasRegionFilter || hasStatusFilter) return emptyFilterTitle;
    if (hasPatientFilter && emptySourceList) return emptySourceTitle;
    if (emptySourceList) return emptySourceTitle;
    return emptyFilterTitle;
  }

  static String emptyDescription({
    required String search,
    required bool hasPatientFilter,
    required bool hasRegionFilter,
    required bool hasStatusFilter,
    required bool emptySourceList,
  }) {
    if (search.trim().isNotEmpty) {
      return 'Arama kriterlerinizi değiştirerek tekrar deneyin.';
    }
    if (hasRegionFilter || hasStatusFilter) {
      return 'Filtre kriterlerinizi değiştirerek tekrar deneyin.';
    }
    if (hasPatientFilter && emptySourceList) {
      return 'Bu hasta için kayıtlı FTR klinik özeti bulunmuyor.';
    }
    if (emptySourceList) {
      return 'Görüntülenebilecek FTR klinik özeti bulunamadı.';
    }
    return 'Arama veya filtre kriterlerinizi değiştirerek tekrar deneyin.';
  }
}
