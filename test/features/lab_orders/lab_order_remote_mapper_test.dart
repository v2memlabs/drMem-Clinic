import 'package:flutter_test/flutter_test.dart';

import 'package:v2mem_clinic/features/lab_orders/data/lab_order_remote_mapper.dart';
import 'package:v2mem_clinic/features/lab_orders/models/lab_order.dart';
import 'package:v2mem_clinic/features/lab_orders/models/lab_test_catalog.dart';

void main() {
  group('LabOrderRemoteMapper', () {
    test('fromRow maps enums, tests and patient name', () {
      final row = {
        'id': 'lo-1',
        'patient_id': 'p-1',
        'clinical_encounter_id': 'e-1',
        'clinical_encounter_protocol_number': 'M-2026-00001',
        'status': 'istendi',
        'diagnosis': 'Gonartroz',
        'order_reason': 'preoperatifHazirlik',
        'selected_tests': ['hemogram', 'ekg'],
        'selected_custom_test_ids': ['custom-1'],
        'infection_context': 'yok',
        'infection_notes': null,
        'preoperative_notes': 'Preop',
        'ekg_notes': null,
        'additional_notes': null,
        'template_id': 'lot-1',
        'template_name': 'Preoperatif standart panel',
        'created_by_display': 'Dr. Test',
        'created_at': '2026-06-21T10:00:00.000Z',
        'updated_at': null,
        'patients': {'first_name': 'Ayşe', 'last_name': 'Yılmaz'},
      };

      final order = LabOrderRemoteMapper.fromRow(row);

      expect(order.id, 'lo-1');
      expect(order.patientName, 'Ayşe Yılmaz');
      expect(order.clinicalEncounterProtocolNumber, 'M-2026-00001');
      expect(order.status, LabOrderStatus.istendi);
      expect(order.orderReason, LabOrderReason.preoperatifHazirlik);
      expect(order.selectedTests, [LabTestCode.hemogram, LabTestCode.ekg]);
      expect(order.selectedCustomTestIds, ['custom-1']);
      expect(order.templateId, 'lot-1');
      expect(order.templateName, 'Preoperatif standart panel');
    });

    test('toInsertRow omits empty optional fields', () {
      final order = LabOrder(
        id: '',
        patientId: 'p-1',
        patientName: 'Hasta',
        createdAt: DateTime(2026, 6, 21),
        createdBy: 'Dr. Test',
        status: LabOrderStatus.taslak,
        diagnosis: 'Tanı',
        selectedTests: const [LabTestCode.hemogram],
      );

      final row = LabOrderRemoteMapper.toInsertRow(
        tenantId: 't-1',
        order: order,
        createdByDisplay: 'Dr. Test',
      );

      expect(row['tenant_id'], 't-1');
      expect(row['patient_id'], 'p-1');
      expect(row['status'], 'taslak');
      expect(row['selected_tests'], ['hemogram']);
      expect(row.containsKey('clinical_encounter_id'), isFalse);
      expect(row.containsKey('template_id'), isFalse);
    });

    test('toArchiveRow sets deleted_at', () {
      final at = DateTime.utc(2026, 6, 21, 12);
      final row = LabOrderRemoteMapper.toArchiveRow(at: at);
      expect(row['deleted_at'], at.toIso8601String());
    });
  });
}
