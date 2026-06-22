import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/auth/auth_password_setup_intent.dart';
import '../../core/auth/supabase_auth_url_session.dart';
import '../../core/auth/auth_session.dart';
import '../../core/auth/invitation_acceptance.dart';
import '../../core/auth/invitation_deep_link.dart';
import '../../core/auth/pending_invitation_store.dart';
import '../../core/data/backend_config.dart';
import '../../core/data/repository_registry.dart';
import '../../core/session/auth_session_bridge.dart';
import '../../core/session/session_readiness.dart';
import '../../core/theme/app_spacing.dart';
import 'widgets/auth_password_form_scaffold.dart';

/// Davet veya kurtarma linkinden sonra yeni şifre belirleme.
class UpdatePasswordScreen extends StatefulWidget {
  const UpdatePasswordScreen({super.key});

  @override
  State<UpdatePasswordScreen> createState() => _UpdatePasswordScreenState();
}

class _UpdatePasswordScreenState extends State<UpdatePasswordScreen> {
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _busy = false;
  bool _recoveringSession = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _recoverSessionFromUrl();
  }

  Future<void> _recoverSessionFromUrl() async {
    if (!AppBackendConfig.isSupabase) {
      if (mounted) setState(() => _recoveringSession = false);
      return;
    }

    if (Supabase.instance.client.auth.currentSession != null) {
      if (mounted) setState(() => _recoveringSession = false);
      return;
    }

    final result = await SupabaseAuthUrlSession.recoverFromCurrentUrlIfPresent();
    if (!mounted) return;

    setState(() {
      _recoveringSession = false;
      if (result.isFailed) {
        _errorMessage = result.errorMessage;
      }
    });
  }

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  String? _validatePasswords() {
    final password = _passwordCtrl.text;
    final confirm = _confirmCtrl.text;
    if (password.length < 8) {
      return 'Şifre en az 8 karakter olmalıdır.';
    }
    if (password != confirm) {
      return 'Şifreler eşleşmiyor.';
    }
    return null;
  }

  Future<void> _submit() async {
    final validationError = _validatePasswords();
    if (validationError != null) {
      setState(() => _errorMessage = validationError);
      return;
    }

    if (!AppBackendConfig.isSupabase) {
      setState(() => _errorMessage = 'Şifre belirleme yalnızca uzak sunucu modunda kullanılabilir.');
      return;
    }

    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      setState(() => _errorMessage = 'Oturum bulunamadı. Lütfen e-postanızdaki bağlantıyı tekrar açın.');
      return;
    }

    setState(() {
      _busy = true;
      _errorMessage = null;
    });

    final newPassword = _passwordCtrl.text;

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      AuthPasswordSetupIntent.clear();
      if (!mounted) return;
      await _continueAfterPassword(session.user.id);
    } on AuthException catch (e) {
      setState(() {
        _busy = false;
        _errorMessage = _messageForAuthException(e);
      });
    } catch (_) {
      setState(() {
        _busy = false;
        _errorMessage = 'Şifre kaydedilemedi. Lütfen tekrar deneyin.';
      });
    }
  }

  String _messageForAuthException(AuthException e) {
    final code = e.code?.toLowerCase() ?? '';
    if (code.contains('weak') || code.contains('password')) {
      return 'Şifre güvenlik kurallarını karşılamıyor.';
    }
    return 'Şifre kaydedilemedi. Lütfen tekrar deneyin.';
  }

  Future<void> _continueAfterPassword(String authUserId) async {
    final membershipId = PendingInvitationStore.membershipId;
    if (membershipId != null) {
      if (!mounted) return;
      context.go(InvitationDeepLink.buildAcceptLocation(membershipId));
      return;
    }

    SessionReadiness.markInitializing();

    try {
      var bootstrap =
          await RepositoryRegistry.membershipLoader.loadForAuthUserId(authUserId);

      if (!bootstrap.isReady && !bootstrap.isMaintenanceReady) {
        bootstrap = await InvitationAcceptance.tryAcceptAndReload(
          initial: bootstrap,
          loader: RepositoryRegistry.membershipLoader,
          authUserId: authUserId,
          membershipId: PendingInvitationStore.membershipId,
        );
      }

      SessionReadiness.markBootstrapResult(bootstrap);

      if (!bootstrap.isReady || bootstrap.context == null) {
        if (!mounted) return;
        setState(() {
          _busy = false;
          _errorMessage = 'Şifre kaydedildi ancak klinik oturumu hazırlanamadı. Giriş yapmayı deneyin.';
        });
        return;
      }

      final bridgeResult =
          AuthSessionBridge.setFromBootstrapContext(bootstrap.context!);
      if (!bridgeResult.success) {
        if (!mounted) return;
        setState(() {
          _busy = false;
          _errorMessage = 'Oturum hazırlanamadı. Giriş yapmayı deneyin.';
        });
        return;
      }

      PendingInvitationStore.clear();
      if (!mounted) return;
      context.go(AuthSession.dashboardRoute);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _errorMessage = 'Oturum hazırlanamadı. Giriş yapmayı deneyin.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final hasSession = AppBackendConfig.isSupabase &&
        Supabase.instance.client.auth.currentSession != null;

    return AuthPasswordFormScaffold(
      title: 'Şifre belirle',
      icon: Icons.lock_outline,
      body: _recoveringSession
          ? const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: AppSpacing.md),
                Text('Bağlantı doğrulanıyor…'),
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Klinik hesabınız için yeni bir şifre oluşturun.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: muted),
                  textAlign: TextAlign.center,
                ),
                if (!hasSession) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Geçerli bir davet veya kurtarma bağlantısı gerekir.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                TextField(
                  controller: _passwordCtrl,
                  obscureText: true,
                  textInputAction: TextInputAction.next,
                  enabled: !_busy && hasSession,
                  decoration: const InputDecoration(
                    labelText: 'Yeni şifre',
                    isDense: true,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _confirmCtrl,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  enabled: !_busy && hasSession,
                  onSubmitted: (_) {
                    if (!_busy && hasSession) _submit();
                  },
                  decoration: const InputDecoration(
                    labelText: 'Yeni şifre (tekrar)',
                    isDense: true,
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    _errorMessage!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                FilledButton(
                  onPressed: _busy || !hasSession ? null : _submit,
                  child: _busy
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                        )
                      : const Text('Şifreyi kaydet'),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextButton(
                  onPressed: _busy ? null : () => AuthPasswordFormScaffold.navigateBack(context),
                  child: Text(AuthPasswordFormScaffold.backLabel(context)),
                ),
              ],
            ),
    );
  }
}

