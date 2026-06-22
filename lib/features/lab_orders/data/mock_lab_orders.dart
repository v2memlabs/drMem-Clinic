import '../models/lab_order.dart';
import '../models/lab_test_catalog.dart';

final List<LabOrder> mockLabOrders = [
  LabOrder(
    id: 'lo1',
    patientId: 'p1',
    patientName: 'Ahmet Yılmaz',
    clinicalEncounterId: 'ce1',
    clinicalEncounterProtocolNumber: 'M-2026-00001',
    createdAt: DateTime.now().subtract(const Duration(hours: 4)),
    createdBy: 'Asistan',
    status: LabOrderStatus.istendi,
    diagnosis: 'Sağ diz medial menisküs yırtığı — preoperatif değerlendirme',
    orderReason: LabOrderReason.preoperatifHazirlik,
    selectedTests: const [
      LabTestCode.hemogram,
      LabTestCode.biyokimyaTam,
      LabTestCode.ptaInr,
      LabTestCode.ekg,
    ],
    preoperativeNotes: 'Planlanan artroskopi öncesi',
    templateId: 'lot1',
    templateName: 'Preoperatif standart panel',
  ),
];
