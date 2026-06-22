import '../constants/app_roles.dart';

/// Rol bazlı varsayılan görünen kullanıcı adları (mock/demo).
abstract final class UserDisplayNames {
  static String defaultForRole(String role) {
    switch (role) {
      case AppRoles.doctor:
        return 'Dr. Mehmet Yalçınozan';
      case AppRoles.assistant:
        return 'Asistan Kullanıcısı';
      case AppRoles.physiotherapist:
        return 'Fizyoterapist A';
      case AppRoles.nurse:
        return 'Hemşire Kullanıcısı';
      default:
        return 'Kullanıcı';
    }
  }

  /// Mock kayıtlarda kullanılacak geçmiş kullanıcı adı (demo temizliği).
  static const String mockDoctorLabel = 'Dr. Mehmet Yalçınozan';
  static const String mockAssistantLabel = 'Asistan Kullanıcısı';
  static const String mockPhysioLabel = 'Fizyoterapist A';
  static const String mockNurseLabel = 'Hemşire Kullanıcısı';
}
