enum PatientTagColor {
  blue,
  green,
  orange,
  red,
  purple,
  gray,
  teal,
}

class PatientTag {
  final String id;
  final String name;
  final PatientTagColor color;
  final String description;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PatientTag({
    required this.id,
    required this.name,
    required this.color,
    this.description = '',
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  PatientTag copyWith({
    String? id,
    String? name,
    PatientTagColor? color,
    String? description,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PatientTag(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

String patientTagColorLabel(PatientTagColor color) {
  switch (color) {
    case PatientTagColor.blue:
      return 'Mavi';
    case PatientTagColor.green:
      return 'Yeşil';
    case PatientTagColor.orange:
      return 'Turuncu';
    case PatientTagColor.red:
      return 'Kırmızı';
    case PatientTagColor.purple:
      return 'Mor';
    case PatientTagColor.gray:
      return 'Gri';
    case PatientTagColor.teal:
      return 'Turkuaz';
  }
}
