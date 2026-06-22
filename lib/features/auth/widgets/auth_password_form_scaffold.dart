import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/auth_route_guard.dart';
import '../../../core/session/session_readiness.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/layout/responsive_page_body.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/page_header.dart';

/// Şifre formları — oturum açıkken AppShell; davet/kurtarma linkinde düz Scaffold.
class AuthPasswordFormScaffold extends StatelessWidget {
  static const systemSecurityPath = '/settings/system-security';

  final String title;
  final IconData icon;
  final Widget body;

  const AuthPasswordFormScaffold({
    super.key,
    required this.title,
    required this.icon,
    required this.body,
  });

  static bool get useAppShell => SessionReadiness.isReady;

  static void navigateBack(BuildContext context) {
    if (useAppShell) {
      context.go(systemSecurityPath);
    } else {
      context.go(AuthRouteGuard.loginPath);
    }
  }

  static String backLabel(BuildContext context) {
    return useAppShell ? 'Ayarlara dön' : 'Giriş ekranına dön';
  }

  @override
  Widget build(BuildContext context) {
    final form = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: body,
        ),
      ),
    );

    if (!useAppShell) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: form,
      );
    }

    return AppShell(
      title: title,
      child: ResponsiveDetailPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PageHeader(
              title: title,
              icon: icon,
              leadingBack: true,
              fallbackRoute: systemSecurityPath,
            ),
            const SizedBox(height: AppSpacing.sm),
            form,
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}
