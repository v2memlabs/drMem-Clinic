import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/clinical_reports/data/clinical_report_remote_mapper.dart';
import 'package:v2mem_clinic/features/clinical_reports/models/clinical_report.dart';

void main() {
  group('ClinicalReportRemoteMapper', () {
    test('fromRow maps type_payload fields and patient name', () {
      final row = {
        'id': 'cr-1',
        'patient_id': 'p-1',
        'clinical_encounter_id': 'e-1',
        'clinical_encounter_protocol_number': 'M-2026-00001',
        'report_number': 'R-2026-00001',
        'document_date_source': 'belgeTarihi',
        'status': 'hazirlandi',
        'report_type': 'istirahat',
        'diagnosis': 'Gonartroz',
        'body_text': 'Rapor metni',
        'type_payload': {
          'startDate': '2026-06-01',
          'endDate': '2026-06-10',
          'restDays': 10,
          'treatmentApproach': 'konservatif',
          'restrictionNotes': 'Not',
        },
        'created_by_display': 'Dr. Test',
        'created_at': '2026-06-21T10:00:00.000Z',
        'updated_at': null,
        'patients': {'first_name': 'Ayşe', 'last_name': 'Yılmaz'},
      };

      final report = ClinicalReportRemoteMapper.fromRow(row);

      expect(report.id, 'cr-1');
      expect(report.patientName, 'Ayşe Yılmaz');
      expect(report.reportType, ClinicalReportType.istirahat);
      expect(report.displayReportNumber, 'R-2026-00001');
      expect(report.restDays, 10);
      expect(report.treatmentApproach, ClinicalReportTreatmentApproach.konservatif);
      expect(report.restrictionNotes, 'Not');
    });

    test('toTypePayload round-trips ucabilir fields', () {
      final report = ClinicalReport(
        id: '',
        patientId: 'p-1',
        patientName: 'Hasta',
        createdAt: DateTime(2026, 6, 21),
        createdBy: 'Dr. Test',
        status: ClinicalReportStatus.taslak,
        reportType: ClinicalReportType.ucabilir,
        diagnosis: 'Tanı',
        bodyText: 'Metin',
        treatmentApproach: ClinicalReportTreatmentApproach.konservatif,
        flightDecision: ClinicalReportFlightDecision.kosullu,
        flightNotes: 'Basınçlı bot',
      );

      final payload = ClinicalReportRemoteMapper.toTypePayload(report);

      expect(payload['treatmentApproach'], 'konservatif');
      expect(payload['flightDecision'], 'kosullu');
      expect(payload['flightNotes'], 'Basınçlı bot');
      expect(payload.containsKey('startDate'), isFalse);
    });
  });
}
