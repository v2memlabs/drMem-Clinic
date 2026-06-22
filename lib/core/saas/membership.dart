import '../constants/app_roles.dart';

/// Kullanıcının bir tenant içindeki üyeliği ve rolü.
///
/// [role] değeri [AppRoles] sabitleriyle uyumludur (doctor, assistant, …).
class Membership {
  final String id;
  final String tenantId;
  final String userId;
  final String role;
  final String status;

  const Membership({
    required this.id,
    required this.tenantId,
    required this.userId,
    required this.role,
    this.status = 'active',
  });

  bool get isActive => status == 'active';

  String get roleLabel => AppRoles.roleLabel(role);
}
