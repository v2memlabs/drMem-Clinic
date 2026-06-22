import '../models/patient_tag.dart';

abstract final class PatientTagMapper {
  static const _validColors = {
    'blue',
    'green',
    'orange',
    'red',
    'purple',
    'gray',
    'teal',
  };

  static PatientTag fromRow(Map<String, dynamic> row) {
    final id = row['id'];
    final name = row['name'];
    final colorRaw = row['color'];
    final description = row['description'];
    final isActive = row['is_active'];
    final createdAt = row['created_at'];
    final updatedAt = row['updated_at'];

    return PatientTag(
      id: id is String ? id : id.toString(),
      name: name is String ? name.trim() : '',
      color: _parseColor(colorRaw),
      description: description is String ? description.trim() : '',
      isActive: isActive is bool ? isActive : true,
      createdAt: _parseDate(createdAt) ?? DateTime.now(),
      updatedAt: _parseDate(updatedAt) ?? DateTime.now(),
    );
  }

  static Map<String, dynamic> toInsertRow({
    required String tenantId,
    required String name,
    required PatientTagColor color,
    required String description,
  }) {
    final now = DateTime.now().toUtc().toIso8601String();
    return {
      'tenant_id': tenantId,
      'name': name.trim(),
      'color': color.name,
      'description': description.trim(),
      'is_active': true,
      'created_at': now,
      'updated_at': now,
    };
  }

  static PatientTagColor _parseColor(Object? raw) {
    final value = raw is String ? raw.trim().toLowerCase() : '';
    if (_validColors.contains(value)) {
      return PatientTagColor.values.firstWhere((c) => c.name == value);
    }
    return PatientTagColor.blue;
  }

  static DateTime? _parseDate(Object? raw) {
    if (raw is String && raw.isNotEmpty) {
      return DateTime.tryParse(raw);
    }
    if (raw is DateTime) return raw;
    return null;
  }
}
