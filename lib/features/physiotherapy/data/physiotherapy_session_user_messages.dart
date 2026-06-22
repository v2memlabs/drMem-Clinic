import 'physiotherapy_session_repository_failure.dart';

abstract final class PhysiotherapySessionListUserMessages {
  static const String loading = 'Seans notları yükleniyor…';
  static const String errorTitle = 'Seans notları yüklenemedi';
  static const String genericLoadFailure =
      'Seans notları yüklenemedi. Lütfen tekrar deneyin.';

  static String forFailure(PhysiotherapySessionRepositoryFailure reason) {
    switch (reason) {
      case PhysiotherapySessionRepositoryFailure.forbidden:
        return 'Fizyoterapi seans notlarına erişim yetkiniz bulunmuyor.';
      case PhysiotherapySessionRepositoryFailure.noActiveTenant:
        return 'Seans notları için aktif klinik oturumu gerekli.';
      case PhysiotherapySessionRepositoryFailure.notConfigured:
        return 'Seans notları şu anda görüntülenemiyor.';
      case PhysiotherapySessionRepositoryFailure.network:
        return 'Seans notları yüklenemedi. Bağlantınızı kontrol edip tekrar deneyin.';
      case PhysiotherapySessionRepositoryFailure.notFound:
      case PhysiotherapySessionRepositoryFailure.invalidRow:
      case PhysiotherapySessionRepositoryFailure.validation:
      case PhysiotherapySessionRepositoryFailure.unknown:
        return genericLoadFailure;
    }
  }
}

abstract final class PhysiotherapySessionDetailUserMessages {
  static const String loading = 'Seans notu yükleniyor…';
  static const String notFoundTitle = 'Seans notu bulunamadı';
  static const String notFoundDescription =
      'İstenen fizyoterapi seans notu bulunamadı veya erişim yok.';
  static const String errorTitle = 'Seans notu yüklenemedi';

  static String forFailure(PhysiotherapySessionRepositoryFailure reason) {
    return PhysiotherapySessionListUserMessages.forFailure(reason);
  }
}

abstract final class PhysiotherapySessionFormUserMessages {
  static const String saveSuccess = 'Seans kaydedildi.';
  static const String saveFailure =
      'Seans kaydedilemedi. Lütfen tekrar deneyin.';
  static const String patientRequired = 'Lütfen hasta seçin.';
  static const String referralRequired =
      'Seans kaydı için bağlı bir fizyoterapi yönlendirmesi gerekli.';
  static const String invalidSessionDate =
      'Seans tarihi YYYY-MM-DD formatında olmalı.';

  static String forFailure(PhysiotherapySessionRepositoryFailure reason) {
    switch (reason) {
      case PhysiotherapySessionRepositoryFailure.validation:
        return 'Seans kaydı geçersiz. Yönlendirme ve hasta bilgilerini kontrol edin.';
      case PhysiotherapySessionRepositoryFailure.forbidden:
        return 'Seans notu oluşturma yetkiniz bulunmuyor.';
      default:
        return PhysiotherapySessionListUserMessages.forFailure(reason);
    }
  }
}
