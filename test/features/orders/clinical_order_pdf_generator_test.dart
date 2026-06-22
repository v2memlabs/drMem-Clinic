import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/lab_orders/models/lab_order.dart';
import 'package:v2mem_clinic/features/lab_orders/models/lab_test_catalog.dart';
import 'package:v2mem_clinic/features/lab_orders/services/lab_order_pdf_generator.dart';
import 'package:v2mem_clinic/features/radiology_orders/models/radiology_order.dart';
import 'package:v2mem_clinic/features/radiology_orders/services/radiology_order_pdf_generator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('radiology order PDF generator returns bytes', () async {
    final order = RadiologyOrder(
      id: 'ro-test',
      patientId: 'p1',
      patientName: 'Test Hasta',
      createdAt: DateTime(2026, 6, 7),
      createdBy: 'Dr. Test',
      status: RadiologyOrderStatus.istendi,
      diagnosis: 'Diz ağrısı',
      lines: const [
        RadiologyOrderLine(
          modality: RadiologyModality.mri,
          bodyRegion: 'Diz',
          side: RadiologySide.sag,
          clinicalIndication: 'Menisküs',
        ),
      ],
    );

    final result = await RadiologyOrderPdfGenerator.instance.generate(
      order: order,
      patientFileNumber: 'D001',
    );
    expect(result.bytes.isNotEmpty, isTrue);
  });

  test('radiology order PDF includes protocol number from snapshot', () async {
    final order = RadiologyOrder(
      id: 'ro-protocol',
      patientId: 'p1',
      patientName: 'Test Hasta',
      clinicalEncounterProtocolNumber: 'M-2026-00042',
      createdAt: DateTime(2026, 6, 7),
      createdBy: 'Dr. Test',
      status: RadiologyOrderStatus.istendi,
      diagnosis: 'Diz ağrısı',
      lines: const [
        RadiologyOrderLine(
          modality: RadiologyModality.mri,
          bodyRegion: 'Diz',
          side: RadiologySide.sag,
          clinicalIndication: 'Menisküs',
        ),
      ],
    );

    final result = await RadiologyOrderPdfGenerator.instance.generate(
      order: order,
      patientFileNumber: 'D001',
    );
    expect(result.bytes.isNotEmpty, isTrue);
  });

  test('lab order PDF generator returns bytes', () async {
    final order = LabOrder(
      id: 'lo-test',
      patientId: 'p1',
      patientName: 'Test Hasta',
      createdAt: DateTime(2026, 6, 7),
      createdBy: 'Hemşire',
      status: LabOrderStatus.istendi,
      diagnosis: 'Septik artrit şüphesi',
      selectedTests: const [LabTestCode.crp, LabTestCode.ekg],
      infectionContext: InfectionContext.septikArtrit,
    );

    final result = await LabOrderPdfGenerator.instance.generate(
      order: order,
      patientFileNumber: 'D001',
    );
    expect(result.bytes.isNotEmpty, isTrue);
  });

  test('lab order PDF includes protocol number from snapshot', () async {
    final order = LabOrder(
      id: 'lo-protocol',
      patientId: 'p1',
      patientName: 'Test Hasta',
      clinicalEncounterProtocolNumber: 'M-2026-00042',
      createdAt: DateTime(2026, 6, 7),
      createdBy: 'Hemşire',
      status: LabOrderStatus.istendi,
      diagnosis: 'Preoperatif',
      selectedTests: const [LabTestCode.hemogram],
    );

    final result = await LabOrderPdfGenerator.instance.generate(
      order: order,
      patientFileNumber: 'D001',
    );
    expect(result.bytes.isNotEmpty, isTrue);
  });
}
