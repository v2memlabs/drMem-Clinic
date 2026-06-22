/// Hasta listesi — boş durum metinleri.
abstract final class PatientListStateMessages {
  static const String emptyDbTitle = 'Henüz hasta kaydı yok';
  static const String emptySearchTitle = 'Hasta bulunamadı';

  static String emptyDescription({required String query}) {
  if (query.trim().isEmpty) {
      return 'Yeni hasta kaydı oluşturarak başlayabilirsiniz.';
    }
    return 'Arama kriterlerinizi değiştirerek tekrar deneyin.';
  }

  static String emptyTitle({required String query}) {
    return query.trim().isEmpty ? emptyDbTitle : emptySearchTitle;
  }
}
