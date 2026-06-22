/// Randevu listesi — boş durum metinleri.
abstract final class AppointmentListStateMessages {
  static const String emptyDayTitle = 'Bu gün randevu yok';
  static const String emptySearchTitle = 'Randevu bulunamadı';
  static const String emptyFilterTitle = 'Randevu bulunamadı';

  static String emptyTitle({
    required String search,
    required bool hasStatusFilter,
    required bool hasPatientFilter,
    required bool emptySourceList,
  }) {
    if (search.trim().isNotEmpty) return emptySearchTitle;
    if (hasStatusFilter || hasPatientFilter) return emptyFilterTitle;
    if (emptySourceList) return emptyDayTitle;
    return emptyFilterTitle;
  }

  static String emptyDescription({
    required String search,
    required bool hasStatusFilter,
    required bool hasPatientFilter,
    required bool emptySourceList,
  }) {
    if (search.trim().isNotEmpty) {
      return 'Arama kriterlerinizi değiştirerek tekrar deneyin.';
    }
    if (hasStatusFilter || hasPatientFilter) {
      return 'Filtre kriterlerinizi değiştirerek tekrar deneyin.';
    }
    if (emptySourceList) {
      return 'Başka bir gün seçin veya yeni randevu oluşturun.';
    }
    return 'Arama veya filtre kriterlerinizi değiştirin.';
  }
}
