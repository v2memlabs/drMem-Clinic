import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/clinical_reports/models/clinical_report.dart';
import 'package:v2mem_clinic/features/clinical_reports/services/clinical_report_pdf_generator.dart';
import 'package:v2mem_clinic/features/prescriptions/models/prescription.dart';
import 'package:v2mem_clinic/features/prescriptions/services/prescription_pdf_generator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('prescription PDF generator returns non-empty bytes', () async {
    final prescription = Prescription(
      id: 'rx-test',
      patientId: 'p1',
      patientName: 'Test Hasta',
      createdAt: DateTime(2026, 6, 7),
      createdBy: 'Dr. Test',
      status: PrescriptionStatus.taslak,
      diagnosis: 'Test tanı',
      medications: const [
        PrescriptionMedication(
          name: 'Parasetamol',
          dose: '500 mg',
          frequency: 'Günde 2',
          duration: '5 gün',
        ),
      ],
    );

    final result = await PrescriptionPdfGenerator.instance.generate(
      prescription: prescription,
      patientFileNumber: 'D001',
    );

    expect(result.bytes.isNotEmpty, isTrue);
    expect(result.fileName.endsWith('.pdf'), isTrue);
  });

  test('clinical report PDF generator returns non-empty bytes', () async {
    final report = ClinicalReport(
      id: 'cr-test',
      patientId: 'p1',
      patientName: 'Test Hasta',
      createdAt: DateTime(2026, 6, 7),
      createdBy: 'Dr. Test',
      status: ClinicalReportStatus.taslak,
      reportType: ClinicalReportType.istirahat,
      diagnosis: 'Test tanı',
      bodyText: 'Hasta istirahat önerilmiştir.',
      restDays: 5,
    );

    final result = await ClinicalReportPdfGenerator.instance.generate(
      report: report,
      patientIdentityNumber: '12345678901',
    );

    expect(result.bytes.isNotEmpty, isTrue);
    expect(result.fileName.contains('rapor_'), isTrue);
  });
}
