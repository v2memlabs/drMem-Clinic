import '../models/patient_tag.dart';

final List<PatientTag> mockPatientTagDefinitions = [
  PatientTag(
    id: 'pt1',
    name: 'Sporcu',
    color: PatientTagColor.green,
    description: 'Sporcu hastası veya spor branşı takibi.',
    createdAt: DateTime(2024, 3, 1),
    updatedAt: DateTime(2024, 3, 1),
  ),
  PatientTag(
    id: 'pt2',
    name: 'Post-op Takip',
    color: PatientTagColor.orange,
    description: 'Ameliyat veya girişim sonrası takip süreci.',
    createdAt: DateTime(2024, 4, 1),
    updatedAt: DateTime(2024, 4, 1),
  ),
  PatientTag(
    id: 'pt3',
    name: 'Ödeme Bekliyor',
    color: PatientTagColor.red,
    description: 'Tahsilat veya fatura bekleyen hasta.',
    createdAt: DateTime(2024, 5, 1),
    updatedAt: DateTime(2024, 5, 1),
  ),
  PatientTag(
    id: 'pt4',
    name: 'Öncelikli Takip',
    color: PatientTagColor.purple,
    description: 'Yakın kontrol veya klinik öncelik gerektiren hasta.',
    createdAt: DateTime(2024, 6, 1),
    updatedAt: DateTime(2024, 6, 1),
  ),
  PatientTag(
    id: 'pt5',
    name: 'Fizyoterapiye Yönlendirildi',
    color: PatientTagColor.teal,
    description: 'Fizyoterapi değerlendirmesi veya seans planı.',
    createdAt: DateTime(2024, 7, 1),
    updatedAt: DateTime(2024, 7, 1),
  ),
  PatientTag(
    id: 'pt6',
    name: 'Ameliyat Adayı',
    color: PatientTagColor.blue,
    description: 'Cerrahi veya girişim planlaması değerlendirilen hasta.',
    createdAt: DateTime(2024, 8, 1),
    updatedAt: DateTime(2024, 8, 1),
  ),
];
