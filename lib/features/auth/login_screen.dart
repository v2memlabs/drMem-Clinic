import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_failure_reason.dart';
import '../../core/auth/auth_session.dart';
import '../../core/constants/app_branding.dart';
import '../../core/constants/app_roles.dart';
import '../../core/data/backend_config.dart';
import '../../core/data/repository_registry.dart';
import '../../core/session/auth_session_bridge.dart';
import '../../core/session/session_readiness.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/auth/auth_password_paths.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identityCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  String _selectedRole = AppRoles.doctor;
  bool _busy = false;
  bool _obscurePassword = true;

  static const double _twoColumnBreakpoint = 720;
  static const double _layoutMaxWidth = 960;

  bool get _isMockMode => AppBackendConfig.isMock;

  @override
  void dispose() {
    _identityCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _showLoginMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _login() async {
    setState(() => _busy = true);

    final result = _isMockMode
        ? await RepositoryRegistry.auth.signInMock(
            username: _identityCtrl.text.trim(),
            password: _passwordCtrl.text,
            role: _selectedRole,
          )
        : await RepositoryRegistry.auth.signInWithUsername(
            username: _identityCtrl.text.trim(),
            password: _passwordCtrl.text,
          );

    if (!mounted) return;
    setState(() => _busy = false);

    if (!result.success || result.user == null) {
      final reason = result.failure ?? AuthFailureReason.invalidCredentials;
      _showLoginMessage(_loginFailureMessage(reason));
      return;
    }

    if (_isMockMode) {
      AuthSessionBridge.setFromMockUser(result.user!);
    } else if (!SessionReadiness.isReady) {
      _showLoginMessage('Oturum hazırlanamadı.');
      RepositoryRegistry.auth.signOut();
      return;
    }

    if (!mounted) return;
    context.go(AuthSession.dashboardRoute);
  }

  String _loginFailureMessage(AuthFailureReason reason) {
    if (_isMockMode) return reason.message;
    return AuthFailureReasonMessage.forSupabaseLogin(reason);
  }

  Widget _brandPanel({required bool compact}) {
    final titleStyle = Theme.of(context).textTheme.headlineSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        );
    final taglineStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Colors.white.withValues(alpha: 0.82),
          height: 1.4,
        );
    final trustStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Colors.white.withValues(alpha: 0.68),
          height: 1.45,
        );

    final content = Column(
      crossAxisAlignment:
          compact ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
      children: [
        Row(
          mainAxisAlignment:
              compact ? MainAxisAlignment.center : MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              AppBranding.iconAsset,
              width: compact ? 28 : 32,
              height: compact ? 28 : 32,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(
                Icons.medical_services_outlined,
                size: compact ? 28 : 32,
                color: AppColors.accentTurquoise,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                AppBranding.productName,
                textAlign: compact ? TextAlign.center : TextAlign.start,
                style: titleStyle,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          AppBranding.productTagline,
          textAlign: compact ? TextAlign.center : TextAlign.start,
          style: taglineStyle,
        ),
        SizedBox(height: compact ? AppSpacing.md : AppSpacing.lg),
        Container(
          width: compact ? 48 : 56,
          height: 3,
          decoration: BoxDecoration(
            color: AppColors.accentTurquoise,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Özel klinik operasyonları için güvenilir hasta takibi ve klinik yönetim altyapısı.',
          textAlign: compact ? TextAlign.center : TextAlign.start,
          style: trustStyle,
        ),
      ],
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.navyDark,
        borderRadius: compact ? AppRadius.cardBorder : null,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.navyDark,
            AppColors.navyDark,
            AppColors.primaryDeepTeal.withValues(alpha: 0.35),
          ],
          stops: const [0, 0.55, 1],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? AppSpacing.lg : AppSpacing.xl),
        child: compact ? content : content,
      ),
    );
  }

  Widget _loginCard() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: AppRadius.cardBorder,
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: AppShadows.elevatedCard,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Güvenli giriş',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryDeepTeal,
                  ),
            ),
            if (AppBackendConfig.isSupabaseRequestedButNotConfigured) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Uzak sunucu yapılandırması eksik; demo giriş modu kullanılıyor.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.primaryDeepTeal.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _identityCtrl,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.next,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Kullanıcı adı',
                isDense: true,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _passwordCtrl,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) {
                if (!_busy) _login();
              },
              decoration: InputDecoration(
                labelText: 'Şifre',
                isDense: true,
                suffixIcon: IconButton(
                  tooltip: _obscurePassword ? 'Şifreyi göster' : 'Şifreyi gizle',
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
            ),
            if (!_isMockMode) ...[
              const SizedBox(height: AppSpacing.xs),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primaryDeepTeal,
                  ),
                  onPressed: _busy
                      ? null
                      : () => context.push(AuthPasswordPaths.forgotPasswordPath),
                  child: const Text('Şifremi unuttum'),
                ),
              ),
            ],
            if (_isMockMode) ...[
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                isExpanded: true,
                items: AppRoles.all
                    .map(
                      (r) => DropdownMenuItem(
                        value: r,
                        child: Text(
                          AppRoles.roleLabel(r),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedRole = v);
                },
                decoration: const InputDecoration(
                  labelText: 'Giriş profili',
                  helperText: 'Demo ortamında rol seçimi',
                  isDense: true,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _busy ? null : _login,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _busy
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                      )
                    : const Text('Giriş Yap'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSoft,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= _twoColumnBreakpoint;

            if (wide) {
              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: _layoutMaxWidth,
                    ),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            flex: 5,
                            child: ClipRRect(
                              borderRadius: AppRadius.cardBorder,
                              child: _brandPanel(compact: false),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.lg),
                          Expanded(
                            flex: 4,
                            child: _loginCard(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }

            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _brandPanel(compact: true),
                      const SizedBox(height: AppSpacing.lg),
                      _loginCard(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
