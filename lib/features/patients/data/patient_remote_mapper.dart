import '../models/patient.dart';
import 'patient_remote_row.dart';

/// Supabase `patients` satırı ↔ [Patient] dönüşümü (query yok).
abstract final class PatientRemoteMapper {
  /// `birth_date` null ise [Patient] zorunluluğu için [fallbackBirthDate] kullanılır
  /// (öncelik: satır `updated_at` → `created_at` → sabit 1970-01-01).
  static final DateTime fallbackBirthDate = DateTime(1970, 1, 1);

  static Patient fromRow(Map<String, dynamic> row) {
    final remote = PatientRemoteRow.fromMap(row);
    return fromRemoteRow(remote);
  }

  static Patient fromRemoteRow(PatientRemoteRow row) {
    final birth = row.birthDate ?? _birthFallbackFromRow(row);
    final lastVisit = row.updatedAt ?? row.createdAt ?? birth;

    final phone = row.phone?.trim();
    final displayPhone =
        phone != null && phone.isNotEmpty ? phone : Patient.unspecifiedLabel;

    final nationalId = row.nationalId?.trim() ?? '';

    return Patient(
      id: row.id ?? '',
      fileNumber: row.fileNumber,
      firstName: row.firstName,
      lastName: row.lastName,
      phone: displayPhone,
      birthDate: birth,
      lastVisitDate: lastVisit,
      primaryComplaint: '',
      bodyRegion: '',
      tags: const [],
      tagIds: const [],
      notes: '',
      gender: _parseGender(row.gender),
      identityType: _parseIdentityType(row.identityType),
      identityNumber: nationalId,
      nationality: row.nationality?.trim().isNotEmpty == true
          ? row.nationality!.trim()
          : Patient.defaultNationality,
      bloodType: _parseBloodType(row.bloodType),
      occupation: row.occupation?.trim() ?? '',
      sportBranch: row.sportsBranch?.trim() ?? '',
      secondaryPhone: row.secondaryPhone?.trim() ?? '',
      email: row.email?.trim() ?? '',
      address: row.address?.trim() ?? '',
      city: row.city?.trim() ?? '',
      district: row.district?.trim() ?? '',
      emergencyContactName: row.emergencyContactName?.trim() ?? '',
      emergencyContactRelation: row.emergencyContactRelation?.trim() ?? '',
      emergencyContactPhone: row.emergencyContactPhone?.trim() ?? '',
      emergencyContactNote: row.emergencyContactNote?.trim() ?? '',
      insuranceType: row.insuranceType?.trim().isNotEmpty == true
          ? row.insuranceType!.trim()
          : Patient.defaultInsuranceType,
      insuranceCompany: '',
      policyNumber: '',
    );
  }

  /// Insert — `id` / timestamp / `deleted_at` gönderilmez; `tenant_id` scope'tan gelir.
  static Map<String, dynamic> toInsertRow(
    Patient patient, {
    required String tenantId,
  }) {
    return {
      'tenant_id': tenantId,
      'file_number': patient.fileNumber.trim(),
      'first_name': patient.firstName.trim(),
      'last_name': patient.lastName.trim(),
      'phone': _phoneToDb(patient.phone),
      'birth_date': _formatDate(patient.birthDate),
      'national_id': _nullableNonEmpty(patient.identityNumber),
      'insurance_type': _insuranceToDb(patient.insuranceType),
      'status': 'active',
      ..._profileFieldsToDb(patient),
    };
  }

  /// Update — `id`, `tenant_id`, `file_number`, `deleted_at` yok; timestamp DB'ye bırakılır.
  static Map<String, dynamic> toUpdateRow(Patient patient) {
    return {
      'first_name': patient.firstName.trim(),
      'last_name': patient.lastName.trim(),
      'phone': _phoneToDb(patient.phone),
      'birth_date': _formatDate(patient.birthDate),
      'national_id': _nullableNonEmpty(patient.identityNumber),
      'insurance_type': _insuranceToDb(patient.insuranceType),
      ..._profileFieldsToDb(patient),
    };
  }

  /// Soft delete — `deleted_at` + `status: archived`.
  static Map<String, dynamic> toSoftDeleteRow({DateTime? at}) {
    final when = (at ?? DateTime.now()).toUtc();
    return {
      'deleted_at': when.toIso8601String(),
      'status': 'archived',
    };
  }

  static Map<String, dynamic> _profileFieldsToDb(Patient patient) {
    return {
      'gender': _genderToDb(patient.gender),
      'identity_type': _identityTypeToDb(patient.identityType),
      'nationality': _nullableNonEmpty(
        patient.nationality == Patient.defaultNationality
            ? ''
            : patient.nationality,
      ),
      'blood_type': _bloodTypeToDb(patient.bloodType),
      'occupation': _nullableNonEmpty(patient.occupation),
      'sports_branch': _nullableNonEmpty(patient.sportBranch),
      'secondary_phone': _phoneToDb(patient.secondaryPhone),
      'email': _nullableNonEmpty(patient.email),
      'address': _nullableNonEmpty(patient.address),
      'city': _nullableNonEmpty(patient.city),
      'district': _nullableNonEmpty(patient.district),
      'emergency_contact_name': _nullableNonEmpty(patient.emergencyContactName),
      'emergency_contact_relation':
          _nullableNonEmpty(patient.emergencyContactRelation),
      'emergency_contact_phone':
          _phoneToDb(patient.emergencyContactPhone),
      'emergency_contact_note': _nullableNonEmpty(patient.emergencyContactNote),
    };
  }

  static String _parseGender(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return Patient.unspecifiedLabel;
    }
    final t = raw.trim();
    if (t == 'male' || t == 'M' || t.toLowerCase() == 'erkek') return 'Erkek';
    if (t == 'female' || t == 'F' || t.toLowerCase() == 'kadın') {
      return 'Kadın';
    }
    return Patient.normalizeDropdownValue(
      t,
      Patient.genderOptions,
      Patient.unspecifiedLabel,
    );
  }

  static String _parseIdentityType(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return Patient.defaultIdentityType;
    }
    return Patient.normalizeDropdownValue(
      raw,
      Patient.identityTypeOptions,
      Patient.defaultIdentityType,
    );
  }

  static String _parseBloodType(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return Patient.unspecifiedLabel;
    }
    return Patient.normalizeDropdownValue(
      raw,
      Patient.bloodTypeOptions,
      Patient.unspecifiedLabel,
    );
  }

  static String? _genderToDb(String gender) {
    final t = gender.trim();
    if (t.isEmpty || t == Patient.unspecifiedLabel) return null;
    return t;
  }

  static String? _identityTypeToDb(String identityType) {
    final t = identityType.trim();
    if (t.isEmpty || t == Patient.unspecifiedLabel) return null;
    if (t == Patient.defaultIdentityType) return t;
    return t;
  }

  static String? _bloodTypeToDb(String bloodType) {
    final t = bloodType.trim();
    if (t.isEmpty || t == Patient.unspecifiedLabel) return null;
    return t;
  }

  static DateTime _birthFallbackFromRow(PatientRemoteRow row) {
    if (row.updatedAt != null) {
      final u = row.updatedAt!.toLocal();
      return DateTime(u.year, u.month, u.day);
    }
    if (row.createdAt != null) {
      final c = row.createdAt!.toLocal();
      return DateTime(c.year, c.month, c.day);
    }
    return fallbackBirthDate;
  }

  static String? _phoneToDb(String phone) {
    final t = phone.trim();
    if (t.isEmpty || t == Patient.unspecifiedLabel || t == '-') {
      return null;
    }
    return t;
  }

  static String? _nullableNonEmpty(String value) {
    final t = value.trim();
    return t.isEmpty ? null : t;
  }

  static String _insuranceToDb(String insuranceType) {
    final t = insuranceType.trim();
    if (t.isEmpty || t == Patient.defaultInsuranceType) {
      return Patient.defaultInsuranceType;
    }
    return t;
  }

  static String _formatDate(DateTime date) {
    final local = date.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
