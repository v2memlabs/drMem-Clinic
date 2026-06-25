import '../auth/auth_password_setup_intent.dart';
import '../data/backend_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// İlk girişte şifre değiştirme zorunluluğu (admin tarafından oluşturulan hesaplar).
abstract final class MustChangePasswordGate {
  static const metadataKey = 'must_change_password';

  static bool get isRequired {
    if (AuthPasswordSetupIntent.isRequired) return true;
    return _readFromSession();
  }

  static bool readsRequired(User? user) {
    if (user == null) return false;
    final value = user.userMetadata?[metadataKey];
    return value == true || value == 'true';
  }

  static bool _readFromSession() {
    if (!AppBackendConfig.isSupabase) return false;
    return readsRequired(Supabase.instance.client.auth.currentUser);
  }

  static void markRequiredFromSession() {
    if (_readFromSession()) {
      AuthPasswordSetupIntent.markRequired();
    }
  }

  static Map<String, dynamic> clearedMetadata(User user) {
    final data = Map<String, dynamic>.from(user.userMetadata ?? {});
    data[metadataKey] = false;
    return data;
  }
}
