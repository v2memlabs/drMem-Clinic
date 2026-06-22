import 'physiotherapy_referral_repository_failure.dart';

abstract final class PhysiotherapyReferralListUserMessages {
  static const String loading = 'Fizyoterapi yönlendirmeleri yükleniyor…';
  static const String errorTitle = 'Yönlendirmeler yüklenemedi';
  static const String genericLoadFailure =
      'Yönlendirmeler yüklenemedi. Lütfen tekrar deneyin.';

  static String forFailure(PhysiotherapyReferralRepositoryFailure reason) {
    switch (reason) {
      case PhysiotherapyReferralRepositoryFailure.forbidden:
        return 'Fizyoterapi yönlendirmelerine erişim yetkiniz bulunmuyor.';
      case PhysiotherapyReferralRepositoryFailure.noActiveTenant:
        return 'Yönlendirmeler için aktif klinik oturumu gerekli.';
      case PhysiotherapyReferralRepositoryFailure.notConfigured:
        return 'Yönlendirmeler şu anda görüntülenemiyor.';
      case PhysiotherapyReferralRepositoryFailure.network:
        return 'Yönlendirmeler yüklenemedi. Bağlantınızı kontrol edip tekrar deneyin.';
      case PhysiotherapyReferralRepositoryFailure.notFound:
      case PhysiotherapyReferralRepositoryFailure.invalidRow:
      case PhysiotherapyReferralRepositoryFailure.unknown:
        return genericLoadFailure;
    }
  }
}

abstract final class PhysiotherapyReferralDetailUserMessages {
  static const String loading = 'Yönlendirme yükleniyor…';
  static const String notFoundTitle = 'Yönlendirme bulunamadı';
  static const String notFoundDescription =
      'İstenen fizyoterapi yönlendirmesi bulunamadı veya erişim yok.';
  static const String errorTitle = 'Yönlendirme yüklenemedi';
  static const String saveSuccess = 'Yönlendirme güncellendi.';
  static const String saveFailure =
      'Yönlendirme güncellenemedi. Lütfen tekrar deneyin.';

  static String forFailure(PhysiotherapyReferralRepositoryFailure reason) {
    return PhysiotherapyReferralListUserMessages.forFailure(reason);
  }
}

abstract final class PhysiotherapyReferralLookupUserMessages {
  static const String sessionLinkedBanner =
      'Kaynak yönlendirme ile bağlantılı seans';
  static const String exerciseLinkedBanner =
      'FTR yönlendirmesi ile ilişkilendirildi';
}

abstract final class PhysiotherapyReferralFormUserMessages {
  static const String loadingEncounter = 'Muayene özeti yükleniyor…';
  static const String encounterLoadFailure =
      'Muayene özeti yüklenemedi. Alanları manuel doldurabilirsiniz.';
  static const String saveSuccess = 'Fizyoterapi yönlendirmesi oluşturuldu.';
  static const String saveFailure =
      'Yönlendirme kaydedilemedi. Lütfen tekrar deneyin.';
  static const String patientRequired = 'Lütfen hasta seçin.';
  static const String invalidReturnDate =
      'Spora dönüş hedef tarihi YYYY-MM-DD formatında olmalı.';

  static String forFailure(PhysiotherapyReferralRepositoryFailure reason) {
    return PhysiotherapyReferralListUserMessages.forFailure(reason);
  }
}
