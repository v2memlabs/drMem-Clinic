import '../models/patient_file.dart';
import '../../patients/data/mock_patients.dart';

final List<PatientFile> mockPatientFiles = [
  PatientFile(id: 'f1', patientId: 'p1', patientName: mockPatientName('p1'), fileName: 'id_card.jpg', fileType: 'image/jpeg', uploadedAt: DateTime.now().subtract(const Duration(days: 200)), uploadedBy: 'Asistan A', description: 'Kimlik fotokopisi'),
  PatientFile(id: 'f2', patientId: 'p1', patientName: mockPatientName('p1'), fileName: 'consent_form.pdf', fileType: 'application/pdf', uploadedAt: DateTime.now().subtract(const Duration(days: 180)), uploadedBy: 'Doktor B', description: 'Onam formu'),
  PatientFile(id: 'f3', patientId: 'p2', patientName: mockPatientName('p2'), fileName: 'previous_report.pdf', fileType: 'application/pdf', uploadedAt: DateTime.now().subtract(const Duration(days: 60)), uploadedBy: 'Asistan C', description: 'Önceki rapor'),
  PatientFile(id: 'f4', patientId: 'p3', patientName: mockPatientName('p3'), fileName: 'exercise_plan.pdf', fileType: 'application/pdf', uploadedAt: DateTime.now().subtract(const Duration(days: 20)), uploadedBy: 'Fizyoterapist D', description: 'Egzersiz programı'),
  PatientFile(id: 'f5', patientId: 'p4', patientName: mockPatientName('p4'), fileName: 'lab_results.pdf', fileType: 'application/pdf', uploadedAt: DateTime.now().subtract(const Duration(days: 10)), uploadedBy: 'Doktor E', description: 'Laboratuvar sonuçları'),
  PatientFile(id: 'f6', patientId: 'p5', patientName: mockPatientName('p5'), fileName: 'therapy_notes.docx', fileType: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document', uploadedAt: DateTime.now().subtract(const Duration(days: 5)), uploadedBy: 'Asistan F', description: 'Tedavi notları'),
  PatientFile(id: 'f7', patientId: 'p6', patientName: mockPatientName('p6'), fileName: 'photo_postop.jpg', fileType: 'image/jpeg', uploadedAt: DateTime.now().subtract(const Duration(days: 2)), uploadedBy: 'Asistan G', description: 'Operasyon sonrası fotoğraf'),
  PatientFile(id: 'f8', patientId: 'p7', patientName: mockPatientName('p7'), fileName: 'insurance_card.pdf', fileType: 'application/pdf', uploadedAt: DateTime.now().subtract(const Duration(days: 400)), uploadedBy: 'Asistan H', description: 'Sigorta kartı'),
  PatientFile(id: 'f9', patientId: 'p8', patientName: mockPatientName('p8'), fileName: 'gait_analysis.mp4', fileType: 'video/mp4', uploadedAt: DateTime.now().subtract(const Duration(days: 1)), uploadedBy: 'Fizyoterapist I', description: 'Yürüme analizi videosu'),
  PatientFile(id: 'f10', patientId: 'p1', patientName: mockPatientName('p1'), fileName: 'referral_letter.pdf', fileType: 'application/pdf', uploadedAt: DateTime.now().subtract(const Duration(days: 3)), uploadedBy: 'Doktor J', description: 'Sevk mektubu'),
];

/// Diğer modüller için geriye dönük uyumluluk.
void addMockPatientFile(PatientFile f) => mockPatientFiles.insert(0, f);
