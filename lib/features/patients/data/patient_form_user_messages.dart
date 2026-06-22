import 'patient_repository_failure.dart';

/// Hasta form kayıt — kullanıcı mesajları.
abstract final class PatientFormUserMessages {
  static String forFailure(PatientRepositoryFailure reason, {required bool isEdit}) {
    switch (reason) {
      case PatientRepositoryFailure.duplicateFileNumber:
        return 'Bu dosya numarası zaten kullanılıyor.';
      case PatientRepositoryFailure.forbidden:
        return 'Bu işlem için yetkiniz bulunmuyor.';
      case PatientRepositoryFailure.noActiveTenant:
        return 'Oturum hazır değil. Lütfen tekrar giriş yapın.';
      case PatientRepositoryFailure.network:
        return 'Bağlantı kurulamadı. Lütfen tekrar deneyin.';
      case PatientRepositoryFailure.notConfigured:
        return 'Hasta kayıt altyapısı şu an kullanılamıyor.';
      case PatientRepositoryFailure.notFound:
        return 'Hasta bulunamadı.';
      default:
        return isEdit
            ? 'Hasta bilgileri güncellenemedi.'
            : 'Hasta kaydı oluşturulamadı.';
    }
  }

  static String successMessage({required bool isEdit, required String name}) {
    return isEdit ? '$name güncellendi.' : '$name kaydedildi.';
  }

  static const String loadFailure = 'Form yüklenemedi.';
}
