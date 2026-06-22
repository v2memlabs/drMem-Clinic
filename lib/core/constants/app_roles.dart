class AppRoles {
  static const String doctor = 'doctor';
  static const String assistant = 'assistant';
  static const String physiotherapist = 'physiotherapist';
  static const String nurse = 'nurse';

  /// IT bakım konsolu — klinik route yok.
  static const String maintenanceOperator = 'maintenance_operator';

  static const List<String> all = [
    doctor,
    assistant,
    physiotherapist,
    nurse,
  ];

  /// Kullanıcıya görünen rol etiketi — teknik DB rol kodu değil.
  static String roleLabel(String role) {
    switch (role) {
      case doctor:
        return 'Doktor';
      case assistant:
        return 'Asistan';
      case physiotherapist:
        return 'Fizyoterapist';
      case nurse:
        return 'Hemşire';
      case maintenanceOperator:
        return 'Bakım operatörü';
      default:
        return role;
    }
  }
}
