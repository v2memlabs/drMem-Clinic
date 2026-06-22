/// Muayene listesi — boş durum metinleri.
abstract final class ClinicalEncounterListStateMessages {
  static const String emptyDbTitle = 'Henüz muayene kaydı yok';
  static const String emptySearchTitle = 'Muayene kaydı bulunamadı';
  static const String emptyFilterTitle = 'Muayene kaydı bulunamadı';

  static String emptyTitle({
    required String search,
    required bool hasVisitFilter,
    required bool hasStatusFilter,
    required bool hasRegionFilter,
    required bool hasPatientFilter,
    required bool emptySourceList,
  }) {
    if (search.trim().isNotEmpty) return emptySearchTitle;
    if (hasVisitFilter ||
        hasStatusFilter ||
        hasRegionFilter ||
        hasPatientFilter) {
      return emptyFilterTitle;
    }
    if (emptySourceList) return emptyDbTitle;
    return emptyFilterTitle;
  }

  static String emptyDescription({
    required String search,
    required bool hasVisitFilter,
    required bool hasStatusFilter,
    required bool hasRegionFilter,
    required bool hasPatientFilter,
    required bool emptySourceList,
  }) {
    if (search.trim().isNotEmpty) {
      return 'Arama kriterlerinizi değiştirerek tekrar deneyin.';
    }
    if (hasVisitFilter ||
        hasStatusFilter ||
        hasRegionFilter ||
        hasPatientFilter) {
      return 'Filtre kriterlerinizi değiştirerek tekrar deneyin.';
    }
    if (emptySourceList) {
      return 'Yeni muayene kaydı oluşturarak başlayabilirsiniz.';
    }
    return 'Arama veya filtre kriterlerinizi değiştirin.';
  }
}
