/// Tenant yapılandırılabilir zorunlu hasta form alanları.
enum PatientRequiredField {
  phone,
  gender,
  identityNumber,
  email,
  address;

  String get storageKey {
    switch (this) {
      case PatientRequiredField.phone:
        return 'phone';
      case PatientRequiredField.gender:
        return 'gender';
      case PatientRequiredField.identityNumber:
        return 'identity_number';
      case PatientRequiredField.email:
        return 'email';
      case PatientRequiredField.address:
        return 'address';
    }
  }

  String get label {
    switch (this) {
      case PatientRequiredField.phone:
        return 'Telefon';
      case PatientRequiredField.gender:
        return 'Cinsiyet';
      case PatientRequiredField.identityNumber:
        return 'Kimlik numarası';
      case PatientRequiredField.email:
        return 'E-posta';
      case PatientRequiredField.address:
        return 'Adres';
    }
  }

  static PatientRequiredField? fromStorageKey(String raw) {
    final key = raw.trim().toLowerCase();
    for (final field in PatientRequiredField.values) {
      if (field.storageKey == key) return field;
    }
    return null;
  }

  static Set<PatientRequiredField> fromStorageList(Iterable<Object?> raw) {
    final fields = <PatientRequiredField>{};
    for (final item in raw) {
      if (item is! String) continue;
      final parsed = fromStorageKey(item);
      if (parsed != null) fields.add(parsed);
    }
    return fields;
  }

  static List<String> toStorageList(Set<PatientRequiredField> fields) {
    return fields.map((f) => f.storageKey).toList()..sort();
  }
}
