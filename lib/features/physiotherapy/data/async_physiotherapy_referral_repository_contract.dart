import '../models/physiotherapy_referral.dart';

/// Güvenli alan güncellemesi — fizyoterapist ve doktor status/takip.
class PhysiotherapyReferralSafeUpdate {
  final ReferralStatus? status;
  final String? notesSafe;
  final DateTime? plannedStartDate;
  final String? assignedPhysiotherapistProfileId;
  final String? appointmentId;

  const PhysiotherapyReferralSafeUpdate({
    this.status,
    this.notesSafe,
    this.plannedStartDate,
    this.assignedPhysiotherapistProfileId,
    this.appointmentId,
  });

  bool get isEmpty =>
      status == null &&
      notesSafe == null &&
      plannedStartDate == null &&
      assignedPhysiotherapistProfileId == null &&
      appointmentId == null;
}

/// Async FTR yönlendirme repository — liste/detay/form active backend hattı.
abstract interface class AsyncPhysiotherapyReferralRepositoryContract {
  Future<List<PhysiotherapyReferral>> getAll();

  Future<List<PhysiotherapyReferral>> getByPatientId(String patientId);

  Future<PhysiotherapyReferral?> getById(String id);

  Future<List<PhysiotherapyReferral>> search(String query);

  Future<List<PhysiotherapyReferral>> getFiltered({
    String? patientId,
    String? query,
    ReferralStatus? statusEnumFilter,
    String? physiotherapistFilter,
  });

  Future<PhysiotherapyReferral> add(PhysiotherapyReferral referral);

  Future<PhysiotherapyReferral> updateSafeFields(
    String id,
    PhysiotherapyReferralSafeUpdate update,
  );
}
