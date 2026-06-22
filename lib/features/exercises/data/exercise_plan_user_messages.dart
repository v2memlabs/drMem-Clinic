import 'exercise_plan_repository_failure.dart';

abstract final class ExercisePlanUserMessages {
  static const genericLoadFailure = 'Egzersiz programları yüklenemedi.';
  static const genericSaveFailure = 'Egzersiz programı kaydedilemedi.';
  static const notFound = 'Egzersiz programı bulunamadı.';

  static String forFailure(ExercisePlanRepositoryFailure reason) {
    switch (reason) {
      case ExercisePlanRepositoryFailure.notConfigured:
      case ExercisePlanRepositoryFailure.noActiveTenant:
        return 'Egzersiz programları için uzak bağlantı hazır değil.';
      case ExercisePlanRepositoryFailure.forbidden:
        return 'Egzersiz programlarına erişim yetkiniz yok.';
      case ExercisePlanRepositoryFailure.notFound:
        return notFound;
      case ExercisePlanRepositoryFailure.network:
        return 'Bağlantı sorunu nedeniyle egzersiz programları yüklenemedi.';
      case ExercisePlanRepositoryFailure.invalidRow:
        return 'Egzersiz programı verisi beklenen formatta değil.';
      case ExercisePlanRepositoryFailure.unknown:
        return genericLoadFailure;
    }
  }
}
