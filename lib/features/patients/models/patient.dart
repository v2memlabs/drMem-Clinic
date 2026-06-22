class Patient {
  static const String defaultIdentityType = 'T.C. Kimlik No';
  static const String defaultNationality = 'Türkiye';
  static const String defaultInsuranceType = 'Belirtilmedi';
  static const String unspecifiedLabel = 'Belirtilmedi';

  static const List<String> identityTypeOptions = [
    'T.C. Kimlik No',
    'Pasaport No',
    'Yabancı Kimlik No',
    unspecifiedLabel,
  ];

  static const List<String> genderOptions = [
    'Erkek',
    'Kadın',
    unspecifiedLabel,
  ];

  static const List<String> bloodTypeOptions = [
    'A Rh+',
    'A Rh-',
    'B Rh+',
    'B Rh-',
    'AB Rh+',
    'AB Rh-',
    '0 Rh+',
    '0 Rh-',
    unspecifiedLabel,
  ];

  static const List<String> insuranceTypeOptions = [
    'SGK',
    'TSS',
    'ÖSS',
    'Özel Sigorta',
    'Ücretli / Sigortasız',
    'Diğer',
    unspecifiedLabel,
  ];

  final String id;
  final String fileNumber;
  final String firstName;
  final String lastName;
  final String phone;
  final DateTime birthDate;
  final DateTime lastVisitDate;
  final String primaryComplaint;
  final String bodyRegion;
  final List<String> tags;
  final List<String> tagIds;
  final String notes;
  final String gender;
  final String identityType;
  final String identityNumber;
  final String nationality;
  final String bloodType;
  final String occupation;
  final String sportBranch;
  final String secondaryPhone;
  final String email;
  final String address;
  final String city;
  final String district;
  final String emergencyContactName;
  final String emergencyContactRelation;
  final String emergencyContactPhone;
  final String emergencyContactNote;
  final String insuranceType;
  final String insuranceCompany;
  final String policyNumber;

  Patient({
    required this.id,
    required this.fileNumber,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.birthDate,
    required this.lastVisitDate,
    required this.primaryComplaint,
    required this.bodyRegion,
    this.tags = const [],
    this.tagIds = const [],
    this.notes = '',
    this.gender = unspecifiedLabel,
    this.identityType = defaultIdentityType,
    this.identityNumber = '',
    this.nationality = defaultNationality,
    this.bloodType = unspecifiedLabel,
    this.occupation = '',
    this.sportBranch = '',
    this.secondaryPhone = '',
    this.email = '',
    this.address = '',
    this.city = '',
    this.district = '',
    this.emergencyContactName = '',
    this.emergencyContactRelation = '',
    this.emergencyContactPhone = '',
    this.emergencyContactNote = '',
    this.insuranceType = defaultInsuranceType,
    this.insuranceCompany = '',
    this.policyNumber = '',
  });

  String get fullName => '$firstName $lastName';

  String displayValue(String value) =>
      value.trim().isEmpty ? unspecifiedLabel : value.trim();

  int get age {
    final now = DateTime.now();
    var a = now.year - birthDate.year;
    final hasHadBirthday = (now.month > birthDate.month) ||
        (now.month == birthDate.month && now.day >= birthDate.day);
    if (!hasHadBirthday) a -= 1;
    return a;
  }

  /// Dropdown değeri listede yoksa güvenli fallback (kırmızı ekran önleme).
  static String normalizeDropdownValue(
    String value,
    List<String> options,
    String fallback,
  ) {
    final t = value.trim();
    if (t.isEmpty) return fallback;
    if (options.contains(t)) return t;
    return fallback;
  }

  /// Liste için kısa cinsiyet: E / K
  String get genderShortLabel {
    switch (gender.trim()) {
      case 'Erkek':
        return 'E';
      case 'Kadın':
        return 'K';
      default:
        return '';
    }
  }

  String get identityNumberFieldLabel {
    switch (identityType) {
      case 'Pasaport No':
        return 'Pasaport No';
      case 'Yabancı Kimlik No':
        return 'Yabancı Kimlik No';
      case 'T.C. Kimlik No':
        return 'T.C. Kimlik No';
      default:
        return 'Kimlik No';
    }
  }

  Patient copyWith({
    String? id,
    String? fileNumber,
    String? firstName,
    String? lastName,
    String? phone,
    DateTime? birthDate,
    DateTime? lastVisitDate,
    String? primaryComplaint,
    String? bodyRegion,
    List<String>? tags,
    List<String>? tagIds,
    String? notes,
    String? gender,
    String? identityType,
    String? identityNumber,
    String? nationality,
    String? bloodType,
    String? occupation,
    String? sportBranch,
    String? secondaryPhone,
    String? email,
    String? address,
    String? city,
    String? district,
    String? emergencyContactName,
    String? emergencyContactRelation,
    String? emergencyContactPhone,
    String? emergencyContactNote,
    String? insuranceType,
    String? insuranceCompany,
    String? policyNumber,
  }) {
    return Patient(
      id: id ?? this.id,
      fileNumber: fileNumber ?? this.fileNumber,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      birthDate: birthDate ?? this.birthDate,
      lastVisitDate: lastVisitDate ?? this.lastVisitDate,
      primaryComplaint: primaryComplaint ?? this.primaryComplaint,
      bodyRegion: bodyRegion ?? this.bodyRegion,
      tags: tags ?? this.tags,
      tagIds: tagIds ?? this.tagIds,
      notes: notes ?? this.notes,
      gender: gender ?? this.gender,
      identityType: identityType ?? this.identityType,
      identityNumber: identityNumber ?? this.identityNumber,
      nationality: nationality ?? this.nationality,
      bloodType: bloodType ?? this.bloodType,
      occupation: occupation ?? this.occupation,
      sportBranch: sportBranch ?? this.sportBranch,
      secondaryPhone: secondaryPhone ?? this.secondaryPhone,
      email: email ?? this.email,
      address: address ?? this.address,
      city: city ?? this.city,
      district: district ?? this.district,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactRelation:
          emergencyContactRelation ?? this.emergencyContactRelation,
      emergencyContactPhone:
          emergencyContactPhone ?? this.emergencyContactPhone,
      emergencyContactNote: emergencyContactNote ?? this.emergencyContactNote,
      insuranceType: insuranceType ?? this.insuranceType,
      insuranceCompany: insuranceCompany ?? this.insuranceCompany,
      policyNumber: policyNumber ?? this.policyNumber,
    );
  }
}
