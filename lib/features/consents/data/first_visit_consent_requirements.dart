import '../models/consent_record.dart';

/// İlk ziyaret / onboarding için zorunlu onam tipleri.
abstract final class FirstVisitConsentRequirements {
  static const List<ConsentType> requiredTypes = [
    ConsentType.kvkkAydinlatma,
    ConsentType.whatsappIzin,
    ConsentType.emailIzin,
    ConsentType.smsIzin,
  ];
}
