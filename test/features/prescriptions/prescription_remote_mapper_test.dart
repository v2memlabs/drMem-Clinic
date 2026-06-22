import 'package:flutter_test/flutter_test.dart';

import 'package:v2mem_clinic/features/prescriptions/data/prescription_remote_mapper.dart';
import 'package:v2mem_clinic/features/prescriptions/models/prescription.dart';

void main() {
  group('PrescriptionRemoteMapper', () {
    test('fromRow maps medications and patient name', () {
      final row = {
        'id': 'rx-1',
        'patient_id': 'p-1',
        'clinical_encounter_id': 'e-1',
        'status': 'taslak',
        'diagnosis': 'Gonartroz',
        'medications': [
          {
            'name': 'Parol',
            'dose': '500 mg',
            'frequency': '2x1',
            'duration': '5 gün',
            'boxCount': 1,
          },
        ],
        'additional_notes': 'Aç karnına',
        'created_by_display': 'Dr. Test',
        'created_at': '2026-06-21T10:00:00.000Z',
        'updated_at': null,
        'patients': {'first_name': 'Ayşe', 'last_name': 'Yılmaz'},
      };

      final prescription = PrescriptionRemoteMapper.fromRow(row);

      expect(prescription.id, 'rx-1');
      expect(prescription.patientName, 'Ayşe Yılmaz');
      expect(prescription.status, PrescriptionStatus.taslak);
      expect(prescription.medications, hasLength(1));
      expect(prescription.medications.first.name, 'Parol');
      expect(prescription.medications.first.boxCount, 1);
      expect(prescription.additionalNotes, 'Aç karnına');
    });

    test('toInsertRow omits empty optional fields', () {
      final prescription = Prescription(
        id: '',
        patientId: 'p-1',
        patientName: 'Hasta',
        createdAt: DateTime(2026, 6, 21),
        createdBy: 'Dr. Test',
        status: PrescriptionStatus.hazirlandi,
        diagnosis: 'Tanı',
        medications: const [
          PrescriptionMedication(
            name: 'İlaç',
            dose: '1',
            frequency: '1',
            duration: '1',
          ),
        ],
      );

      final row = PrescriptionRemoteMapper.toInsertRow(
        tenantId: 't-1',
        prescription: prescription,
        createdByDisplay: 'Dr. Test',
      );

      expect(row['tenant_id'], 't-1');
      expect(row['patient_id'], 'p-1');
      expect(row['status'], 'hazirlandi');
      expect(row.containsKey('clinical_encounter_id'), isFalse);
      expect(row.containsKey('additional_notes'), isFalse);
      expect(row['medications'], isA<List>());
    });
  });
}
