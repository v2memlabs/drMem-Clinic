import '../models/radiology_order.dart';

final List<RadiologyOrder> mockRadiologyOrders = [
  RadiologyOrder(
    id: 'ro1',
    patientId: 'p1',
    patientName: 'Ahmet Yılmaz',
    clinicalEncounterId: 'ce1',
    clinicalEncounterProtocolNumber: 'M-2026-00001',
    createdAt: DateTime.now().subtract(const Duration(hours: 6)),
    createdBy: 'Dr. Mehmet Yalçınozan',
    status: RadiologyOrderStatus.istendi,
    priority: RadiologyPriority.rutin,
    diagnosis: 'Sağ diz medial menisküs yırtığı',
    lines: const [
      RadiologyOrderLine(
        modality: RadiologyModality.mri,
        bodyRegion: 'Diz',
        side: RadiologySide.sag,
        clinicalIndication: 'Menisküs yırtığı şüphesi',
        withContrast: false,
      ),
      RadiologyOrderLine(
        modality: RadiologyModality.xRay,
        bodyRegion: 'Diz',
        side: RadiologySide.sag,
        clinicalIndication: 'Kemik yapı değerlendirmesi',
      ),
    ],
  ),
];
