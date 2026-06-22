import '../models/prescription.dart';

final List<Prescription> mockPrescriptions = [
  Prescription(
    id: 'rx1',
    patientId: 'p1',
    patientName: 'Ahmet Yılmaz',
    clinicalEncounterId: 'ce1',
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
    createdBy: 'Dr. Mehmet Yalçınozan',
    status: PrescriptionStatus.hazirlandi,
    diagnosis: 'Sağ diz medial menisküs yırtığı',
    medications: const [
      PrescriptionMedication(
        name: 'Parasetamol 500 mg',
        dose: '1 tablet',
        frequency: 'Günde 3 kez',
        duration: '7 gün',
        notes: 'Tok karnına',
      ),
      PrescriptionMedication(
        name: 'Naproksen 250 mg',
        dose: '1 tablet',
        frequency: 'Günde 2 kez',
        duration: '5 gün',
        notes: 'Ağrı olduğunda',
      ),
    ],
    additionalNotes: 'NSAID kullanımında mide koruyucu önerildi.',
  ),
];
