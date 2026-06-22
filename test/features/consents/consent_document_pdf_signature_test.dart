import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/consents/data/mock_consent_templates.dart';
import 'package:v2mem_clinic/features/consents/services/consent_document_pdf_generator.dart';
import 'package:v2mem_clinic/features/patients/models/patient.dart';

void main() {
  test('generate supports optional patientSignaturePng parameter', () async {
    final template = mockConsentTemplates.first;
    final patient = Patient(
      id: 'p1',
      fileNumber: 'H-001',
      firstName: 'Ayşe',
      lastName: 'Yılmaz',
      phone: '555',
      birthDate: DateTime(1990, 1, 1),
      lastVisitDate: DateTime(2026, 1, 1),
      primaryComplaint: '',
      bodyRegion: '',
    );

    final result = await ConsentDocumentPdfGenerator.generate(
      template: template,
      patient: patient,
      recordId: 'c-test',
      preparedBy: 'Dr Test',
      preparedAt: DateTime(2026, 6, 21),
      patientSignaturePng: null,
    );

    expect(result.bytes, isNotEmpty);
  });
}
