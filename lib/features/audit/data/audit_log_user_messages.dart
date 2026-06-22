import 'audit_log_repository_failure.dart';

abstract final class AuditLogUserMessages {
  static const genericLoadFailure = 'İşlem geçmişi yüklenemedi.';
  static const notFound = 'İşlem kaydı bulunamadı.';
  static const notConfigured =
      'İşlem geçmişi için uzak bağlantı hazır değil. Oturumunuzu kontrol edin.';
  static const filterNoMatch = 'Filtreye uygun işlem kaydı yok';
  static const filterNoMatchDescription =
      'Arama veya filtre kriterlerinizi değiştirerek tekrar deneyebilirsiniz.';

  static String forFailure(AuditLogRepositoryFailure reason) {
    switch (reason) {
      case AuditLogRepositoryFailure.notConfigured:
      case AuditLogRepositoryFailure.noActiveTenant:
        return notConfigured;
      case AuditLogRepositoryFailure.forbidden:
        return 'İşlem geçmişine erişim yetkiniz yok.';
      case AuditLogRepositoryFailure.notFound:
        return notFound;
      case AuditLogRepositoryFailure.network:
        return 'Bağlantı sorunu nedeniyle işlem geçmişi yüklenemedi.';
      case AuditLogRepositoryFailure.invalidRow:
        return 'İşlem kaydı verisi beklenen formatta değil.';
      case AuditLogRepositoryFailure.unknown:
        return genericLoadFailure;
    }
  }
}
