import 'surgery_procedure_note_repository_failure.dart';

abstract final class SurgeryNoteListUserMessages {
  static const String genericLoadFailure =
      'Ameliyat / girişim notları yüklenemedi.';

  static String forFailure(SurgeryProcedureNoteRepositoryFailure reason) {
    switch (reason) {
      case SurgeryProcedureNoteRepositoryFailure.notConfigured:
      case SurgeryProcedureNoteRepositoryFailure.noActiveTenant:
        return 'Oturum veya klinik bağlamı hazır değil.';
      case SurgeryProcedureNoteRepositoryFailure.forbidden:
        return 'Bu kayıtlara erişim yetkiniz yok.';
      case SurgeryProcedureNoteRepositoryFailure.network:
        return 'Bağlantı hatası. Lütfen tekrar deneyin.';
      case SurgeryProcedureNoteRepositoryFailure.notFound:
      case SurgeryProcedureNoteRepositoryFailure.invalidRow:
      case SurgeryProcedureNoteRepositoryFailure.unknown:
        return genericLoadFailure;
    }
  }
}
