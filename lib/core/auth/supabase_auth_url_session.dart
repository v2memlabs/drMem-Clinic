import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_client_initializer.dart';
import 'auth_password_paths.dart';
import 'auth_password_setup_intent.dart';
import 'supabase_web_auth_callback_uri.dart';

/// Web auth callback URL'lerinden (davet / şifre kurtarma) oturum kurar.
abstract final class SupabaseAuthUrlSession {
  static bool hasAuthCallbackInUri(Uri uri) {
    if (uri.queryParameters.containsKey('code')) return true;
    final fragment = uri.fragment;
    if (fragment.isEmpty) return false;
    return fragment.contains('access_token') ||
        fragment.contains('error_description') ||
        fragment.contains('type=recovery');
  }

  static Uri _callbackUri(Uri uri) {
    if (!kIsWeb) return uri;
    if (hasAuthCallbackInUri(uri) ||
        AuthPasswordPaths.isUpdatePasswordPath(uri.path)) {
      return SupabaseWebAuthCallbackUri.fromBrowser();
    }
    return uri;
  }

  /// Hash veya `?code=` içeren URL'den Supabase oturumu oluşturur.
  static Future<SupabaseAuthUrlSessionResult> recoverFromUri(Uri uri) async {
    if (!SupabaseClientInitializer.isInitialized) {
      return const SupabaseAuthUrlSessionResult.skipped();
    }

    final callbackUri = _callbackUri(uri);
    if (!hasAuthCallbackInUri(callbackUri)) {
      return const SupabaseAuthUrlSessionResult.skipped();
    }

    try {
      final response =
          await Supabase.instance.client.auth.getSessionFromUrl(callbackUri);
      final type = _redirectTypeFromUri(callbackUri) ?? response.redirectType;
      if (type == 'recovery' ||
          type == 'passwordRecovery' ||
          AuthPasswordPaths.isUpdatePasswordPath(callbackUri.path)) {
        AuthPasswordSetupIntent.markRequired();
      }
      return SupabaseAuthUrlSessionResult.recovered(
        session: response.session,
        redirectType: type,
      );
    } on AuthException catch (e) {
      return SupabaseAuthUrlSessionResult.failed(_messageForAuthException(e));
    } catch (_) {
      return const SupabaseAuthUrlSessionResult.failed(
        'Bağlantı işlenemedi. Lütfen e-postanızdaki linki tekrar açın.',
      );
    }
  }

  static Future<SupabaseAuthUrlSessionResult> recoverFromCurrentUrlIfPresent() {
    if (!kIsWeb) {
      return Future.value(const SupabaseAuthUrlSessionResult.skipped());
    }
    return recoverFromUri(Uri.base);
  }

  static String _messageForAuthException(AuthException e) {
    final message = e.message.toLowerCase();
    if (message.contains('code verifier')) {
      return 'Şifre sıfırlama bağlantısı bu tarayıcıda geçersiz. '
          'Lütfen şifre sıfırlamayı aynı tarayıcıda tekrar isteyin ve '
          'gelen e-postadaki linke hemen tıklayın.';
    }
    if (message.contains('no code detected')) {
      return 'Geçersiz veya süresi dolmuş bağlantı. Yeni sıfırlama e-postası isteyin.';
    }
    return e.message;
  }

  static String? _redirectTypeFromUri(Uri uri) {
    if (uri.queryParameters['type'] != null) {
      return uri.queryParameters['type'];
    }
    final fragment = uri.fragment;
    if (fragment.isEmpty) return null;
    for (final part in fragment.split('&')) {
      final kv = part.split('=');
      if (kv.length == 2 && kv[0] == 'type') {
        return Uri.decodeComponent(kv[1]);
      }
    }
    return null;
  }
}

class SupabaseAuthUrlSessionResult {
  const SupabaseAuthUrlSessionResult._({
    required this.status,
    this.session,
    this.redirectType,
    this.errorMessage,
  });

  const SupabaseAuthUrlSessionResult.skipped()
      : this._(status: SupabaseAuthUrlSessionStatus.skipped);

  const SupabaseAuthUrlSessionResult.failed(String message)
      : this._(
          status: SupabaseAuthUrlSessionStatus.failed,
          errorMessage: message,
        );

  factory SupabaseAuthUrlSessionResult.recovered({
    required Session? session,
    String? redirectType,
  }) {
    return SupabaseAuthUrlSessionResult._(
      status: SupabaseAuthUrlSessionStatus.recovered,
      session: session,
      redirectType: redirectType,
    );
  }

  final SupabaseAuthUrlSessionStatus status;
  final Session? session;
  final String? redirectType;
  final String? errorMessage;

  bool get isRecovered => status == SupabaseAuthUrlSessionStatus.recovered;
  bool get isFailed => status == SupabaseAuthUrlSessionStatus.failed;
}

enum SupabaseAuthUrlSessionStatus {
  skipped,
  recovered,
  failed,
}
