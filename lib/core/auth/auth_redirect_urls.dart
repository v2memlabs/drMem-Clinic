import 'package:flutter/foundation.dart';

import 'auth_password_paths.dart';

/// Supabase Auth `redirectTo` / `emailRedirectTo` için uygulama URL'leri.
abstract final class AuthRedirectUrls {
  static String updatePasswordRedirect() {
    if (kIsWeb) {
      final origin = Uri.base.origin;
      if (origin.isNotEmpty) {
        return '$origin${AuthPasswordPaths.updatePasswordPath}';
      }
    }
    return AuthPasswordPaths.updatePasswordPath;
  }
}
