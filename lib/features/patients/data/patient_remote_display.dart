import '../../../core/data/repository_registry.dart';
import '../models/patient.dart';

/// Remote v1 — DB'de olmayan alanların UI'da gereksiz görünmesini engeller.
abstract final class PatientRemoteDisplay {
  static bool get usesRemote => RepositoryRegistry.usesRemotePatients;

  static bool isMeaningfulText(String value) {
    final t = value.trim();
    return t.isNotEmpty &&
        t != '-' &&
        t != Patient.unspecifiedLabel;
  }

  static bool showPhone(Patient patient) => isMeaningfulText(patient.phone);

  static bool showIdentityNumber(Patient patient) =>
      isMeaningfulText(patient.identityNumber);

  static bool showNationality(Patient patient) {
    if (!usesRemote) return true;
    return patient.nationality.trim().isNotEmpty &&
        patient.nationality != Patient.defaultNationality;
  }

  static bool showInsurance(Patient patient) {
    if (!usesRemote) return true;
    return patient.insuranceType.trim().isNotEmpty &&
        patient.insuranceType != Patient.defaultInsuranceType;
  }

  static bool showPolicy(Patient patient) {
    if (!usesRemote) return isMeaningfulText(patient.policyNumber);
    return patient.insuranceCompany.trim().isNotEmpty ||
        isMeaningfulText(patient.policyNumber);
  }

  static bool showComplaint(Patient patient) =>
      isMeaningfulText(patient.primaryComplaint);

  static bool showBodyRegion(Patient patient) =>
      isMeaningfulText(patient.bodyRegion);

  static bool showTags(Patient patient) =>
      !usesRemote ||
      patient.tagIds.isNotEmpty ||
      patient.tags.isNotEmpty;

  static bool showGender(Patient patient) =>
      patient.gender.trim().isNotEmpty &&
      patient.gender != Patient.unspecifiedLabel;

  static bool showBloodType(Patient patient) =>
      patient.bloodType.trim().isNotEmpty &&
      patient.bloodType != Patient.unspecifiedLabel;

  static bool showOccupation(Patient patient) => isMeaningfulText(patient.occupation);

  static bool showSportBranch(Patient patient) => isMeaningfulText(patient.sportBranch);

  static bool showSecondaryPhone(Patient patient) =>
      isMeaningfulText(patient.secondaryPhone);

  static bool showEmail(Patient patient) => isMeaningfulText(patient.email);

  static bool showAddress(Patient patient) {
    return isMeaningfulText(patient.address) ||
        isMeaningfulText(patient.city) ||
        isMeaningfulText(patient.district);
  }

  static String formatAddressLine(Patient patient) {
    final parts = <String>[];
    if (isMeaningfulText(patient.address)) parts.add(patient.address.trim());
    final cityDistrict = [
      if (isMeaningfulText(patient.district)) patient.district.trim(),
      if (isMeaningfulText(patient.city)) patient.city.trim(),
    ].join(' / ');
    if (cityDistrict.isNotEmpty) parts.add(cityDistrict);
    return parts.isEmpty ? '—' : parts.join(', ');
  }

  static bool showEmergencyContact(Patient patient) {
    return isMeaningfulText(patient.emergencyContactName) ||
        isMeaningfulText(patient.emergencyContactPhone);
  }
}
