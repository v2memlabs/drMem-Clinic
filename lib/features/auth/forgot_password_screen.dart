import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/auth/auth_redirect_urls.dart';
import '../../core/data/backend_config.dart';
import '../../core/theme/app_spacing.dart';
import 'widgets/auth_password_form_scaffold.dart';

/// Şifre sıfırlama e-postası isteği.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  bool _busy = false;
  bool _sent = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMessage = 'Geçerli bir e-posta adresi girin.');
      return;
    }

    if (!AppBackendConfig.isSupabase) {
      setState(() => _errorMessage = 'Şifre sıfırlama yalnızca uzak sunucu modunda kullanılabilir.');
      return;
    }

    setState(() {
      _busy = true;
      _errorMessage = null;
    });

    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        email,
        redirectTo: AuthRedirectUrls.updatePasswordRedirect(),
      );
      if (!mounted) return;
      setState(() {
        _busy = false;
        _sent = true;
      });
    } on AuthException {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _errorMessage = 'İşlem tamamlanamadı. Lütfen tekrar deneyin.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _errorMessage = 'İşlem tamamlanamadı. Lütfen tekrar deneyin.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return AuthPasswordFormScaffold(
      title: 'Şifremi unuttum',
      icon: Icons.mail_outline,
      body: _sent
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Şifre sıfırlama bağlantısı e-posta adresinize gönderildi.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                FilledButton(
                  onPressed: () => AuthPasswordFormScaffold.navigateBack(context),
                  child: Text(AuthPasswordFormScaffold.backLabel(context)),
                ),
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                      Text(
                        'Kayıtlı e-posta adresinizi girin; size şifre sıfırlama bağlantısı gönderelim.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: muted),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      TextField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                        autocorrect: false,
                        enabled: !_busy,
                        onSubmitted: (_) {
                          if (!_busy) _submit();
                        },
                        decoration: const InputDecoration(
                          labelText: 'E-posta',
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
                        onPressed: _busy ? null : _submit,
                        child: _busy
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                              )
                            : const Text('Bağlantı gönder'),
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
