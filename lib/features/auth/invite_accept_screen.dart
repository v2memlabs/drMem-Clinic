import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/auth/auth_password_paths.dart';
import '../../core/auth/auth_password_setup_intent.dart';
import '../../core/auth/auth_session.dart';
import '../../core/auth/invitation_acceptance.dart';
import '../../core/auth/invitation_deep_link.dart';
import '../../core/auth/pending_invitation_store.dart';
import '../../core/auth/supabase_auth_url_session.dart';
import '../../core/auth/session_bootstrap.dart';
import '../../core/data/backend_config.dart';
import '../../core/data/repository_registry.dart';
import '../../core/router/auth_route_guard.dart';
import '../../core/session/auth_session_bridge.dart';
import '../../core/session/session_readiness.dart';
import '../../core/theme/app_spacing.dart';
import '../../features/settings/data/tenant_invite_failure.dart';

/// Davet deep-link kabul ekranı — `/invite/accept?membership_id=...`
class InviteAcceptScreen extends StatefulWidget {
  final String? membershipId;

  const InviteAcceptScreen({super.key, this.membershipId});

  @override
  State<InviteAcceptScreen> createState() => _InviteAcceptScreenState();
}

class _InviteAcceptScreenState extends State<InviteAcceptScreen> {
  bool _busy = true;
  String? _errorMessage;
  bool _needsLogin = false;

  @override
  void initState() {
    super.initState();
    _bootstrapFromDeepLink();
  }

  Future<void> _bootstrapFromDeepLink() async {
    final membershipId = InvitationDeepLink.normalizeMembershipId(
      widget.membershipId,
    );

    if (membershipId == null) {
      setState(() {
        _busy = false;
        _errorMessage = 'Davet bağlantısı geçersiz.';
      });
      return;
    }

    PendingInvitationStore.setMembershipId(membershipId);

    if (!AppBackendConfig.isSupabase) {
      setState(() {
        _busy = false;
        _errorMessage = 'Davet kabulü yalnızca uzak sunucu modunda kullanılabilir.';
      });
      return;
    }

    await _waitForSupabaseSessionFromUrl();

    if (AuthPasswordSetupIntent.isRequired) {
      if (!mounted) return;
      context.go(AuthPasswordPaths.updatePasswordPath);
      return;
    }

    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      setState(() {
        _busy = false;
        _needsLogin = true;
      });
      return;
    }

    await _acceptWithSession(session.user.id);
  }

  Future<void> _acceptWithSession(String authUserId) async {
    setState(() {
      _busy = true;
      _errorMessage = null;
      _needsLogin = false;
    });

    SessionReadiness.markInitializing();

    try {
      var bootstrap =
          await RepositoryRegistry.membershipLoader.loadForAuthUserId(authUserId);

      if (bootstrap.isReady && bootstrap.context != null) {
        await _completeSignIn(bootstrap);
        return;
      }

      if (bootstrap.status == SessionBootstrapStatus.inactiveMembership) {
        bootstrap = await InvitationAcceptance.tryAcceptAndReload(
          initial: bootstrap,
          loader: RepositoryRegistry.membershipLoader,
          authUserId: authUserId,
          membershipId: PendingInvitationStore.membershipId,
        );
      }

      SessionReadiness.markBootstrapResult(bootstrap);

      if (!bootstrap.isReady || bootstrap.context == null) {
        setState(() {
          _busy = false;
          _errorMessage = _messageForBootstrap(bootstrap.status);
        });
        return;
      }

      await _completeSignIn(bootstrap);
    } on TenantInviteRepositoryException catch (e) {
      setState(() {
        _busy = false;
        _errorMessage = e.message;
      });
    } catch (_) {
      setState(() {
        _busy = false;
        _errorMessage = 'Davet kabul edilemedi. Lütfen yöneticinizle iletişime geçin.';
      });
    }
  }

  Future<void> _completeSignIn(SessionBootstrapResult bootstrap) async {
    final bridgeResult =
        AuthSessionBridge.setFromBootstrapContext(bootstrap.context!);
    if (!bridgeResult.success) {
      setState(() {
        _busy = false;
        _errorMessage = 'Oturum hazırlanamadı.';
      });
      return;
    }

    PendingInvitationStore.clear();
    if (!mounted) return;
    context.go(AuthSession.dashboardRoute);
  }

  Future<void> _waitForSupabaseSessionFromUrl() async {
    if (!kIsWeb) return;
    if (Supabase.instance.client.auth.currentSession != null) return;
    if (!SupabaseAuthUrlSession.hasAuthCallbackInUri(Uri.base)) return;

    await SupabaseAuthUrlSession.recoverFromCurrentUrlIfPresent();
  }

  String _messageForBootstrap(SessionBootstrapStatus status) {
    switch (status) {
      case SessionBootstrapStatus.multiplePendingInvitations:
        return 'Birden fazla bekleyen davet var. Yöneticinizle iletişime geçin.';
      case SessionBootstrapStatus.invitationAcceptFailed:
        return 'Davet kabul edilemedi. Lütfen yöneticinizle iletişime geçin.';
      case SessionBootstrapStatus.inactiveMembership:
        return 'Bu davet artık beklemede değil.';
      default:
        return 'Davet işlenemedi. Lütfen tekrar deneyin.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return Scaffold(
      appBar: AppBar(title: const Text('Davet kabul')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: _busy
                ? const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: AppSpacing.md),
                      Text('Davetiniz işleniyor…'),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_errorMessage != null) ...[
                        Text(
                          _errorMessage!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.error,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      if (_needsLogin) ...[
                        Text(
                          'Daveti kabul etmek için klinik hesabınızla giriş yapın.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: muted,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        FilledButton(
                          onPressed: () => context.go(AuthRouteGuard.loginPath),
                          child: const Text('Giriş yap'),
                        ),
                      ] else if (_errorMessage != null) ...[
                        OutlinedButton(
                          onPressed: () => context.go(AuthRouteGuard.loginPath),
                          child: const Text('Giriş ekranına dön'),
                        ),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
