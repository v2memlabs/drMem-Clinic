/// Supabase `patients` tablo satırı — `supabase_flutter` bağımlılığı yok.
class PatientRemoteRow {
  final String? id;
  final String tenantId;
  final String fileNumber;
  final String firstName;
  final String lastName;
  final String? phone;
  final DateTime? birthDate;
  final String? gender;
  final String? identityType;
  final String? nationalId;
  final String? nationality;
  final String? bloodType;
  final String? occupation;
  final String? sportsBranch;
  final String? secondaryPhone;
  final String? email;
  final String? address;
  final String? city;
  final String? district;
  final String? emergencyContactName;
  final String? emergencyContactRelation;
  final String? emergencyContactPhone;
  final String? emergencyContactNote;
  final String? insuranceType;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  const PatientRemoteRow({
    this.id,
    required this.tenantId,
    required this.fileNumber,
    required this.firstName,
    required this.lastName,
    this.phone,
    this.birthDate,
    this.gender,
    this.identityType,
    this.nationalId,
    this.nationality,
    this.bloodType,
    this.occupation,
    this.sportsBranch,
    this.secondaryPhone,
    this.email,
    this.address,
    this.city,
    this.district,
    this.emergencyContactName,
    this.emergencyContactRelation,
    this.emergencyContactPhone,
    this.emergencyContactNote,
    this.insuranceType,
    this.status = 'active',
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory PatientRemoteRow.fromMap(Map<String, dynamic> map) {
    return PatientRemoteRow(
      id: map['id'] as String?,
      tenantId: map['tenant_id'] as String? ?? '',
      fileNumber: (map['file_number'] as String?)?.trim() ?? '',
      firstName: (map['first_name'] as String?)?.trim() ?? '',
      lastName: (map['last_name'] as String?)?.trim() ?? '',
      phone: _nullableTrimmed(map['phone']),
      birthDate: _parseDate(map['birth_date']),
      gender: _nullableTrimmed(map['gender']),
      identityType: _nullableTrimmed(map['identity_type']),
      nationalId: _nullableTrimmed(map['national_id']),
      nationality: _nullableTrimmed(map['nationality']),
      bloodType: _nullableTrimmed(map['blood_type']),
      occupation: _nullableTrimmed(map['occupation']),
      sportsBranch: _nullableTrimmed(map['sports_branch']),
      secondaryPhone: _nullableTrimmed(map['secondary_phone']),
      email: _nullableTrimmed(map['email']),
      address: _nullableTrimmed(map['address']),
      city: _nullableTrimmed(map['city']),
      district: _nullableTrimmed(map['district']),
      emergencyContactName: _nullableTrimmed(map['emergency_contact_name']),
      emergencyContactRelation:
          _nullableTrimmed(map['emergency_contact_relation']),
      emergencyContactPhone: _nullableTrimmed(map['emergency_contact_phone']),
      emergencyContactNote: _nullableTrimmed(map['emergency_contact_note']),
      insuranceType: _nullableTrimmed(map['insurance_type']),
      status: (map['status'] as String?)?.trim().isNotEmpty == true
          ? (map['status'] as String).trim()
          : 'active',
      createdAt: _parseDateTime(map['created_at']),
      updatedAt: _parseDateTime(map['updated_at']),
      deletedAt: _parseDateTime(map['deleted_at']),
    );
  }

  Map<String, dynamic> toMap({bool includeId = true}) {
    final map = <String, dynamic>{
      'tenant_id': tenantId,
      'file_number': fileNumber,
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      'birth_date': birthDate != null ? _formatDate(birthDate!) : null,
      'gender': gender,
      'identity_type': identityType,
      'national_id': nationalId,
      'nationality': nationality,
      'blood_type': bloodType,
      'occupation': occupation,
      'sports_branch': sportsBranch,
      'secondary_phone': secondaryPhone,
      'email': email,
      'address': address,
      'city': city,
      'district': district,
      'emergency_contact_name': emergencyContactName,
      'emergency_contact_relation': emergencyContactRelation,
      'emergency_contact_phone': emergencyContactPhone,
      'emergency_contact_note': emergencyContactNote,
      'insurance_type': insuranceType,
      'status': status,
    };
    if (includeId && id != null) {
      map['id'] = id;
    }
    if (createdAt != null) {
      map['created_at'] = createdAt!.toUtc().toIso8601String();
    }
    if (updatedAt != null) {
      map['updated_at'] = updatedAt!.toUtc().toIso8601String();
    }
    if (deletedAt != null) {
      map['deleted_at'] = deletedAt!.toUtc().toIso8601String();
    }
    return map;
  }

  static String? _nullableTrimmed(dynamic value) {
    if (value == null) return null;
    final s = value.toString().trim();
    return s.isEmpty ? null : s;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) {
      return DateTime(value.year, value.month, value.day);
    }
    final s = value.toString().trim();
    if (s.isEmpty) return null;
    try {
      final parsed = DateTime.parse(s);
      return DateTime(parsed.year, parsed.month, parsed.day);
    } catch (_) {
      return null;
    }
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value.toUtc();
    final s = value.toString().trim();
    if (s.isEmpty) return null;
    try {
      return DateTime.parse(s).toUtc();
    } catch (_) {
      return null;
    }
  }

  static String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
