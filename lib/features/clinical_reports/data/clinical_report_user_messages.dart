import 'clinical_report_repository_failure.dart';

abstract final class ClinicalReportUserMessages {
  static const genericLoadFailure = 'Klinik raporlar yüklenemedi.';
  static const genericSaveFailure = 'Klinik rapor kaydedilemedi.';
  static const notFound = 'Klinik rapor bulunamadı.';

  static String forFailure(ClinicalReportRepositoryFailure reason) {
    switch (reason) {
      case ClinicalReportRepositoryFailure.notConfigured:
      case ClinicalReportRepositoryFailure.noActiveTenant:
        return 'Klinik raporlar için uzak bağlantı hazır değil.';
      case ClinicalReportRepositoryFailure.forbidden:
        return 'Klinik raporlara erişim yetkiniz yok.';
      case ClinicalReportRepositoryFailure.notFound:
        return notFound;
      case ClinicalReportRepositoryFailure.network:
        return 'Bağlantı sorunu nedeniyle klinik raporlar yüklenemedi.';
      case ClinicalReportRepositoryFailure.invalidRow:
        return 'Klinik rapor verisi beklenen formatta değil.';
      case ClinicalReportRepositoryFailure.unknown:
        return genericLoadFailure;
    }
  }
}
