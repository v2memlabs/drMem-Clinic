import 'pdf_output_repository_failure.dart';

/// PDF çıktı listesi — kullanıcı mesajları.
abstract final class PdfOutputListUserMessages {
  static const String loading = 'PDF çıktıları yükleniyor…';
  static const String emptyGeneric = 'PDF çıktı kaydı bulunamadı';
  static const String emptyDescription =
      'Arama veya filtre kriterlerinizi değiştirerek tekrar deneyebilirsiniz.';
  static const String genericLoadFailure =
      'PDF çıktıları yüklenemedi. Lütfen tekrar deneyin.';

  static String forFailure(PdfOutputRepositoryFailure reason) {
    switch (reason) {
      case PdfOutputRepositoryFailure.forbidden:
        return 'Bu PDF çıktılarını görüntüleme yetkiniz bulunmuyor.';
      case PdfOutputRepositoryFailure.noActiveTenant:
        return 'PDF çıktıları için aktif klinik oturumu gerekli.';
      case PdfOutputRepositoryFailure.notConfigured:
        return 'PDF çıktı altyapısı henüz aktif değil.';
      case PdfOutputRepositoryFailure.network:
        return genericLoadFailure;
      case PdfOutputRepositoryFailure.notFound:
      case PdfOutputRepositoryFailure.invalidRow:
      case PdfOutputRepositoryFailure.unknown:
        return genericLoadFailure;
    }
  }
}
