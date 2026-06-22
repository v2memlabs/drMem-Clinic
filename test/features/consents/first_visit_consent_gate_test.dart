import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/consents/data/first_visit_consent_checklist.dart';
import 'package:v2mem_clinic/features/consents/models/consent_record.dart';
import 'package:v2mem_clinic/features/consents/models/consent_signature_mode.dart';

void main() {
  test('checklist complete when all four required consents are signed', () {
    ConsentRecord signed(ConsentType type, String id) => ConsentRecord(
          id: id,
          patientId: 'p1',
          patientName: 'Hasta',
          createdAt: DateTime(2026, 6, 1),
          consentType: type,
          status: ConsentStatus.alindi,
          recordedBy: 'Dr',
          signatureMode: ConsentSignatureMode.pad,
        );

    final checklist = FirstVisitConsentChecklist.evaluate(
      patientId: 'p1',
      consents: [
        signed(ConsentType.kvkkAydinlatma, 'c1'),
        signed(ConsentType.whatsappIzin, 'c2'),
        signed(ConsentType.emailIzin, 'c3'),
        signed(ConsentType.smsIzin, 'c4'),
      ],
    );

    expect(checklist.isComplete, isTrue);
    expect(checklist.incompleteItems, isEmpty);
  });

  test('checklist incomplete when alindi but signature pending', () {
    final checklist = FirstVisitConsentChecklist.evaluate(
      patientId: 'p1',
      consents: [
        ConsentRecord(
          id: 'c1',
          patientId: 'p1',
          patientName: 'Hasta',
          createdAt: DateTime(2026, 6, 1),
          consentType: ConsentType.kvkkAydinlatma,
          status: ConsentStatus.alindi,
          recordedBy: 'Dr',
          signatureMode: ConsentSignatureMode.pending,
        ),
      ],
    );

    expect(checklist.isComplete, isFalse);
    expect(
      checklist.items.firstWhere((i) => i.consentType == ConsentType.kvkkAydinlatma).isComplete,
      isFalse,
    );
  });

  test('checklist incomplete when any required consent missing or bekliyor', () {
    final checklist = FirstVisitConsentChecklist.evaluate(
      patientId: 'p1',
      consents: [
        ConsentRecord(
          id: 'c1',
          patientId: 'p1',
          patientName: 'Hasta',
          createdAt: DateTime(2026, 6, 1),
          consentType: ConsentType.kvkkAydinlatma,
          status: ConsentStatus.alindi,
          recordedBy: 'Dr',
          signatureMode: ConsentSignatureMode.wetUpload,
        ),
        ConsentRecord(
          id: 'c2',
          patientId: 'p1',
          patientName: 'Hasta',
          createdAt: DateTime(2026, 6, 2),
          consentType: ConsentType.smsIzin,
          status: ConsentStatus.bekliyor,
          recordedBy: 'Asistan',
        ),
      ],
    );

    expect(checklist.isComplete, isFalse);
    expect(checklist.incompleteItems.length, 3);
  });
}
