import '../../../core/auth/auth_session.dart';
import '../../../core/constants/app_roles.dart';
import '../../../core/data/backend_config.dart';
import '../../physiotherapy/data/physiotherapy_repository.dart';
import '../models/patient.dart';

abstract final class PatientAccessFilter {
  /// Mock backend: fizyoterapist yalnızca kendine yönlendirilmiş hastaları görür.
  /// Remote: RLS (`patients_select_physio_referred_v1`) uygulanır — filtre gerekmez.
  static List<Patient> filterVisible(List<Patient> patients) {
    if (!AppBackendConfig.isMock) {
      return patients;
    }

    if (AuthSession.currentUser?.role != AppRoles.physiotherapist) {
      return patients;
    }

    final referredPatientIds = _referredPatientIdsForCurrentPhysio();
    return patients
        .where((p) => referredPatientIds.contains(p.id))
        .toList(growable: false);
  }

  static bool canViewPatient(Patient patient) {
    if (!AppBackendConfig.isMock) {
      return true;
    }

    if (AuthSession.currentUser?.role != AppRoles.physiotherapist) {
      return true;
    }
    return _referredPatientIdsForCurrentPhysio().contains(patient.id);
  }

  static Set<String> _referredPatientIdsForCurrentPhysio() {
    final filter = _mockPhysiotherapistFilter();
    final referrals = PhysiotherapyRepository.instance.getFilteredReferrals(
      physiotherapistFilter: filter,
    );
    return referrals.map((r) => r.patientId).toSet();
  }

  static String? _mockPhysiotherapistFilter() {
    final displayName = AuthSession.currentUser?.displayName.trim() ?? '';
    if (displayName.isEmpty) return null;
    return displayName;
  }
}
