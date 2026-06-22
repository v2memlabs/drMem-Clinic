import '../constants/app_roles.dart';

/// Flutter [AppRoles] ↔ DB `memberships.role` tek kaynak eşlemesi.
abstract final class TenantRoleMapper {
  static const String dbDoctorAdmin = 'doctor_admin';
  static const String dbAssistantSecretary = 'assistant_secretary';
  static const String dbPhysiotherapist = 'physiotherapist';
  static const String dbNurse = 'nurse';

  static const Map<String, String> _flutterToDb = {
    AppRoles.doctor: dbDoctorAdmin,
    AppRoles.assistant: dbAssistantSecretary,
    AppRoles.physiotherapist: dbPhysiotherapist,
    AppRoles.nurse: dbNurse,
  };

  static const Map<String, String> _dbToFlutter = {
    dbDoctorAdmin: AppRoles.doctor,
    dbAssistantSecretary: AppRoles.assistant,
    dbPhysiotherapist: AppRoles.physiotherapist,
    dbNurse: AppRoles.nurse,
  };

  /// UI / mock rol → PostgreSQL CHECK rolü.
  static String? toDbRole(String flutterRole) => _flutterToDb[flutterRole];

  /// Membership DB rolü → [AppRoles] sabiti.
  static String? toFlutterRole(String dbRole) => _dbToFlutter[dbRole];

  static bool isKnownFlutterRole(String role) => _flutterToDb.containsKey(role);

  static bool isKnownDbRole(String dbRole) => _dbToFlutter.containsKey(dbRole);
}
