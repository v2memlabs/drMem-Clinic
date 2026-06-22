import '../models/consent_record.dart';
import '../models/consent_signature_mode.dart';

/// Onam kaydının imza kanıtı ile tamamlandı sayılması.
abstract final class ConsentCompletionRules {
  static bool isFullyCompleted(ConsentRecord record) {
    return record.status == ConsentStatus.alindi &&
        record.signatureMode != ConsentSignatureMode.pending;
  }

  static bool needsSignature(ConsentRecord record) {
    return record.signatureMode == ConsentSignatureMode.pending &&
        record.status != ConsentStatus.reddedildi &&
        record.status != ConsentStatus.iptalEdildi;
  }
}
