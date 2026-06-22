import '../models/appointment.dart';
import 'appointment_type_mapping.dart';

/// Route `type` query → [AppointmentType] (create prefill only).
abstract final class AppointmentTypeQueryParser {
  static AppointmentType? fromQuery(String? raw) {
    final q = raw?.trim();
    if (q == null || q.isEmpty) return null;

    for (final value in AppointmentType.values) {
      if (value.name == q) return value;
    }

    if (q == AppointmentTypeMapping.physiotherapy) {
      return AppointmentType.fizikTedavi;
    }

    return null;
  }
}
