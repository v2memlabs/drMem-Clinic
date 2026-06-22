import 'package:flutter/foundation.dart';

import 'auth_password_paths.dart';

/// Web'de Supabase auth callback — pathname + query (hash router kirlenmesini önler).
abstract final class SupabaseWebAuthCallbackUri {
  static Uri fromBrowser() {
    final base = Uri.base;
    return Uri(
      scheme: base.scheme,
      host: base.host,
      port: base.hasPort ? base.port : null,
      path: base.path,
      query: base.query,
    );
  }

  static bool isPasswordRecoveryLanding() {
    if (!kIsWeb) return false;
    final uri = fromBrowser();
    if (!AuthPasswordPaths.isUpdatePasswordPath(uri.path)) return false;
    return uri.queryParameters.containsKey('code') ||
        uri.fragment.contains('access_token') ||
        uri.fragment.contains('type=recovery');
  }

  static bool hasExchangeableCallback() {
    if (!kIsWeb) return false;
    final uri = fromBrowser();
    if (uri.queryParameters.containsKey('code')) return true;
    final fragment = uri.fragment;
    return fragment.contains('access_token') ||
        fragment.contains('error_description');
  }
}
