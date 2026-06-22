import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/radiology_orders/data/radiology_order_remote_mapper.dart';
import 'package:v2mem_clinic/features/radiology_orders/models/radiology_order.dart';

void main() {
  group('RadiologyOrderRemoteMapper', () {
    test('fromRow maps lines and patient name', () {
      final row = {
        'id': 'ro-1',
        'patient_id': 'p-1',
        'clinical_encounter_id': 'e-1',
        'clinical_encounter_protocol_number': 'M-2026-00001',
        'status': 'istendi',
        'priority': 'acil',
        'diagnosis': 'Gonartroz',
        'lines': [
          {
            'modality': 'mri',
            'bodyRegion': 'Diz',
            'side': 'sag',
            'clinicalIndication': 'Ağrı',
            'withContrast': true,
            'notes': 'Ek not',
          },
        ],
        'additional_notes': 'Acil',
        'created_by_display': 'Dr. Test',
        'created_at': '2026-06-21T10:00:00.000Z',
        'updated_at': null,
        'patients': {'first_name': 'Ayşe', 'last_name': 'Yılmaz'},
      };

      final order = RadiologyOrderRemoteMapper.fromRow(row);

      expect(order.id, 'ro-1');
      expect(order.patientName, 'Ayşe Yılmaz');
      expect(order.status, RadiologyOrderStatus.istendi);
      expect(order.priority, RadiologyPriority.acil);
      expect(order.displayProtocolNumber, 'M-2026-00001');
      expect(order.lines, hasLength(1));
      expect(order.lines.first.modality, RadiologyModality.mri);
      expect(order.lines.first.withContrast, isTrue);
    });

    test('toInsertRow omits empty optional fields', () {
      final order = RadiologyOrder(
        id: '',
        patientId: 'p-1',
        patientName: 'Hasta',
        createdAt: DateTime(2026, 6, 21),
        createdBy: 'Dr. Test',
        status: RadiologyOrderStatus.taslak,
        diagnosis: 'Tanı',
        lines: const [
          RadiologyOrderLine(
            modality: RadiologyModality.xRay,
            bodyRegion: 'Diz',
            clinicalIndication: 'Endikasyon',
          ),
        ],
      );

      final row = RadiologyOrderRemoteMapper.toInsertRow(
        tenantId: 't-1',
        order: order,
        createdByDisplay: 'Dr. Test',
      );

      expect(row['tenant_id'], 't-1');
      expect(row['patient_id'], 'p-1');
      expect(row['priority'], 'rutin');
      expect(row.containsKey('clinical_encounter_id'), isFalse);
      expect(row.containsKey('additional_notes'), isFalse);
      expect(row['lines'], isA<List>());
    });
  });
}
