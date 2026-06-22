import 'package:flutter_test/flutter_test.dart';

import 'package:v2mem_clinic/features/clinical_encounter/post_encounter_wizard/data/mock_patient_surgical_quote_alerts.dart';
import 'package:v2mem_clinic/features/clinical_encounter/post_encounter_wizard/data/patient_surgical_quote_alert_repository.dart';
import 'package:v2mem_clinic/features/clinical_encounter/post_encounter_wizard/models/post_encounter_document_kind.dart';
import 'package:v2mem_clinic/features/clinical_encounter/post_encounter_wizard/models/patient_surgical_quote_alert.dart';
import 'package:v2mem_clinic/features/clinical_encounter/post_encounter_wizard/models/surgical_quote_currency.dart';
import 'package:v2mem_clinic/features/clinical_encounter/post_encounter_wizard/post_encounter_wizard_navigation.dart';

void main() {
  setUp(() {
    mockPatientSurgicalQuoteAlerts.clear();
  });

  test('wizard navigation appends encounterWizard query', () {
    final path = PostEncounterWizardNavigation.buildDocumentFormPath(
      kind: PostEncounterDocumentKind.lab,
      patientId: 'p1',
      clinicalEncounterId: 'e1',
    );

    expect(path, contains('encounterWizard=1'));
    expect(path, contains('patientId=p1'));
    expect(path, contains('clinicalEncounterId=e1'));
  });

  test('active surgical quote alert returns latest non-dismissed', () {
    final repo = PatientSurgicalQuoteAlertRepository.instance;

    repo.add(
      PatientSurgicalQuoteAlert(
        id: 'a1',
        patientId: 'p1',
        patientName: 'Hasta',
        clinicalEncounterId: 'e1',
        procedureNote: 'Diz artroskopi',
        createdAt: DateTime(2026, 1, 1),
        createdByDisplay: 'Dr',
      ),
    );

    repo.dismiss('a1', dismissedBy: 'Dr', at: DateTime(2026, 1, 2));

    repo.add(
      PatientSurgicalQuoteAlert(
        id: 'a2',
        patientId: 'p1',
        patientName: 'Hasta',
        clinicalEncounterId: 'e2',
        procedureNote: 'Omuz',
        quotedAmount: 1500,
        currency: SurgicalQuoteCurrency.usd,
        createdAt: DateTime(2026, 2, 1),
        createdByDisplay: 'Dr',
      ),
    );

    final active = repo.activeForPatient('p1');
    expect(active?.id, 'a2');
    expect(active?.quotedAmount, 1500);
    expect(active?.currency, SurgicalQuoteCurrency.usd);
  });
}
