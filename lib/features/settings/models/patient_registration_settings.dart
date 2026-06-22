import 'patient_required_field.dart';

/// Tenant hasta kayıt ayarları (`settings_json.patient`).
class PatientRegistrationSettings {
  static const String defaultFileNumberFormat = 'H-{year}-{seq}';
  static const int defaultSeqPadding = 4;
  static const int minSeqPadding = 1;
  static const int maxSeqPadding = 8;

  static const List<({String format, String label})> formatPresets = [
    (format: 'H-{year}-{seq}', label: 'H-2026-0001 (varsayılan)'),
    (format: 'A-{seq}', label: 'A-001'),
    (format: 'DEMO-{seq}', label: 'DEMO-001'),
  ];

  final String fileNumberFormat;
  final int seqPadding;
  final Set<PatientRequiredField> requiredFields;

  const PatientRegistrationSettings({
    this.fileNumberFormat = defaultFileNumberFormat,
    this.seqPadding = defaultSeqPadding,
    this.requiredFields = const {},
  });

  bool isRequired(PatientRequiredField field) => requiredFields.contains(field);

  PatientRegistrationSettings copyWith({
    String? fileNumberFormat,
    int? seqPadding,
    Set<PatientRequiredField>? requiredFields,
  }) {
    return PatientRegistrationSettings(
      fileNumberFormat: fileNumberFormat ?? this.fileNumberFormat,
      seqPadding: seqPadding ?? this.seqPadding,
      requiredFields: requiredFields ?? this.requiredFields,
    );
  }

  String? validate() {
    final format = fileNumberFormat.trim();
    if (format.isEmpty) return 'Dosya no formatı boş olamaz.';
    if (!format.contains('{seq}')) {
      return 'Format {seq} içermelidir.';
    }
    if (RegExp(r'\{[^}]+\}').allMatches(format).any((m) {
      final token = m.group(0);
      return token != '{seq}' && token != '{year}';
    })) {
      return 'Yalnızca {seq} ve {year} kullanılabilir.';
    }
    if (seqPadding < minSeqPadding || seqPadding > maxSeqPadding) {
      return 'Sıra numarası uzunluğu $minSeqPadding–$maxSeqPadding arasında olmalıdır.';
    }
    return null;
  }
}
