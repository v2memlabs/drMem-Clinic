import '../../../core/data/repository_registry.dart';
import '../models/patient.dart';
import 'patient_form_data_source.dart';
import 'patient_list_refresh.dart';
import 'patient_profile_completion.dart';
import 'patient_remote_mapper.dart';
/// Hızlı hasta oluşturma — muayene formu bağlamı (minimal alanlar).
abstract final class QuickPatientCreateDataSource {
  static String normalizePhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 12 && digits.startsWith('90')) {
      return digits.substring(digits.length - 10);
    }
    if (digits.length > 10 && digits.startsWith('0')) {
      return digits.substring(digits.length - 10);
    }
    return digits;
  }

  static bool isValidPhone(String phone) => normalizePhone(phone).length >= 10;

  static Patient buildDraft({
    required String fileNumber,
    required String firstName,
    required String lastName,
    required String phone,
    DateTime? birthDate,
    String gender = Patient.unspecifiedLabel,
    String identityType = Patient.defaultIdentityType,
    String identityNumber = '',
  }) {
    final now = DateTime.now();
    return Patient(
      id: '',
      fileNumber: fileNumber,
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      phone: phone.trim(),
      birthDate: birthDate ?? PatientRemoteMapper.fallbackBirthDate,
      lastVisitDate: now,
      primaryComplaint: '',
      bodyRegion: '',
      gender: gender,
      identityType: identityType,
      identityNumber: identityNumber.trim(),
    );
  }

  static bool isProfilePartiallyComplete(Patient patient) {
    return !PatientProfileCompletion.evaluate(patient).isComplete;
  }

  static Future<List<Patient>> findSimilarPatients({
    required String firstName,
    required String lastName,
    required String phone,
  }) async {
    final normalized = normalizePhone(phone);
    if (normalized.length < 10) return const [];

    final first = firstName.trim().toLowerCase();
    final last = lastName.trim().toLowerCase();

    try {
      final all = await RepositoryRegistry.patientsAsync.getAll();
      return all.where((p) {
        final pPhone = normalizePhone(p.phone);
        if (pPhone != normalized) return false;
        final nameMatch = p.firstName.trim().toLowerCase() == first &&
            p.lastName.trim().toLowerCase() == last;
        return nameMatch || pPhone == normalized;
      }).toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<Patient> createQuickPatient({
    required String firstName,
    required String lastName,
    required String phone,
    DateTime? birthDate,
    String gender = Patient.unspecifiedLabel,
    String identityType = Patient.defaultIdentityType,
    String identityNumber = '',
  }) async {
    final fileNumber = await PatientFormDataSource.nextFileNumber();
    final draft = buildDraft(
      fileNumber: fileNumber,
      firstName: firstName,
      lastName: lastName,
      phone: phone,
      birthDate: birthDate,
      gender: gender,
      identityType: identityType,
      identityNumber: identityNumber,
    );
    final created = await PatientFormDataSource.create(draft);
    PatientListRefresh.markStale();
    return created;
  }

  /// Kullanıcıya gösterilecek kısa özet (teknik detay yok).
  static String similarPatientSummary(Patient patient) {
    final phone = patient.phone.trim();
    return '${patient.fullName} · $phone · ${patient.fileNumber}';
  }
}
