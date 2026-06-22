import '../../core/constants/app_roles.dart';
import '../../core/settings/app_settings_controller.dart';

class AppUser {
  final String id;
  final String username;
  final String displayName;
  final String role;

  AppUser({required this.id, required this.username, required this.displayName, required this.role});
}

Future<AppUser?> mockLogin(String username, String password, String role) async {
  await Future.delayed(const Duration(milliseconds: 400));
  if (username.isEmpty) return null;
  if (password.isEmpty) return null;
  final id = DateTime.now().millisecondsSinceEpoch.toString();
  final display = appSettingsController.displayNameForRole(role);
  return AppUser(id: id, username: username, displayName: display, role: role);
}
