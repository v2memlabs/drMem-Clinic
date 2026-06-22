import '../../../core/auth/auth_session.dart';
import '../../../core/constants/app_roles.dart';
import '../models/patient_file_metadata.dart';
import '../models/patient_file_metadata_enums.dart';

/// Metadata satırı için app-layer görüntüleme/yükleme yetkisi (RLS sonrası).
abstract final class PatientFileMetadataAccessGate {
  static bool canView(PatientFileMetadata metadata) {
    if (!metadata.isActive) return false;

    final role = AuthSession.currentUser?.role;
    if (role == AppRoles.doctor) {
      return true;
    }
    if (role == AppRoles.assistant) {
      return metadata.visibilityScope ==
          PatientFileVisibilityScope.clinicOperations;
    }
    if (role == AppRoles.physiotherapist) {
      return metadata.visibilityScope ==
          PatientFileVisibilityScope.physiotherapy;
    }
    return false;
  }

  static bool canUploadForScope(PatientFileVisibilityScope scope) {
    final role = AuthSession.currentUser?.role;
    if (role == AppRoles.doctor) {
      return AuthSession.canEditFiles;
    }
    if (role == AppRoles.assistant) {
      return AuthSession.canEditFiles &&
          scope == PatientFileVisibilityScope.clinicOperations;
    }
    if (role == AppRoles.physiotherapist) {
      return scope == PatientFileVisibilityScope.physiotherapy;
    }
    return false;
  }
}
