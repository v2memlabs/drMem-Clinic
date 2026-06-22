import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/repository_registry.dart';
import '../router/auth_route_guard.dart';

/// Oturum kapatma ve route guard ile uyumlu temizlik.
abstract final class AuthSessionLifecycle {
  static Future<void> signOut({BuildContext? context}) async {
    await RepositoryRegistry.auth.signOutAsync();
    if (context != null && context.mounted) {
      final router = GoRouter.maybeOf(context);
      if (router != null) {
        router.go(AuthRouteGuard.loginPath);
      }
    }
  }

  /// Graceful kapanış / detached — best-effort uzak + yerel temizlik.
  static Future<void> signOutBestEffort() async {
    await RepositoryRegistry.auth.signOutAsync();
  }

  /// Supabase fazında token geçersiz — aynı temizlik + login.
  static Future<void> signOutSessionExpired({BuildContext? context}) async {
    await signOut(context: context);
  }
}
