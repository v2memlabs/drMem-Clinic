import '../../../core/session/record_ownership_context.dart';
import '../models/appointment.dart';

abstract final class AppointmentOwnership {
  static bool isVisibleToCurrentUser(Appointment appointment) {
    if (RecordOwnershipContext.seesAllAppointments) return true;

    final profileId = RecordOwnershipContext.currentProfileId();

    if (RecordOwnershipContext.isDoctor) {
      final doctorId = appointment.assignedDoctorProfileId?.trim();
      if (profileId != null &&
          profileId.isNotEmpty &&
          doctorId != null &&
          doctorId.isNotEmpty) {
        return doctorId == profileId;
      }
      final doctorName = appointment.assignedDoctorName?.trim();
      if (doctorName != null && doctorName.isNotEmpty) {
        return doctorName.toLowerCase() ==
            RecordOwnershipContext.currentDisplayName().toLowerCase();
      }
      return false;
    }

    if (RecordOwnershipContext.isPhysiotherapist) {
      final physioId = appointment.assignedPhysiotherapistProfileId?.trim();
      if (profileId != null &&
          profileId.isNotEmpty &&
          physioId != null &&
          physioId.isNotEmpty) {
        return physioId == profileId;
      }
      return false;
    }

    return true;
  }
}
