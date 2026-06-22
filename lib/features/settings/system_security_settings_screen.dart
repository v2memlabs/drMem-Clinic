import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_password_paths.dart';
import '../../core/auth/auth_session.dart';
import '../../core/constants/app_branding.dart';
import '../../core/data/backend_config.dart';
import '../../core/session/session_auto_lock_controller.dart';
import '../../core/settings/app_settings.dart';
import '../../core/settings/app_settings_controller.dart';
import '../../core/theme/app_spacing.dart';
import 'data/tenant_settings_repository.dart';
import 'data/tenant_settings_repository_provider.dart';
import 'models/tenant_security_settings.dart';
import 'settings_subpage_scaffold.dart';
import 'settings_widgets.dart';

class SystemSecuritySettingsScreen extends StatefulWidget {
  const SystemSecuritySettingsScreen({super.key});

  @override
  State<SystemSecuritySettingsScreen> createState() =>
      _SystemSecuritySettingsScreenState();
}

class _SystemSecuritySettingsScreenState
    extends State<SystemSecuritySettingsScreen> {
  static const _autoLockOptions = AutoLockDurationKind.values;

  bool _loading = true;
  bool _saving = false;
  String? _loadError;
  AutoLockDurationKind _autoLockDuration = AutoLockDurationKind.min15;

  @override
  void initState() {
    super.initState();
    _load();
    appSettingsController.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    appSettingsController.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    if (!mounted) return;
    setState(() {
      _autoLockDuration = appSettingsController.settings.autoLockDuration;
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final security =
          await TenantSettingsRepositoryProvider.repository.loadSecuritySettings();
      if (!mounted) return;
      await appSettingsController.applyTenantSecuritySettings(security);
      sessionAutoLockController.configure(security.autoLockDuration);
      setState(() {
        _autoLockDuration = security.autoLockDuration;
        _loading = false;
      });
    } on TenantSettingsRepositoryException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.message;
        _autoLockDuration = appSettingsController.settings.autoLockDuration;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadError = 'Güvenlik ayarları yüklenemedi.';
        _autoLockDuration = appSettingsController.settings.autoLockDuration;
        _loading = false;
      });
    }
  }

  Future<void> _saveAutoLock() async {
    if (_saving || !AuthSession.canEditClinicProfile) return;
    setState(() => _saving = true);
    try {
      final security = TenantSecuritySettings(autoLockDuration: _autoLockDuration);
      await TenantSettingsRepositoryProvider.repository.updateSecuritySettings(
        security,
      );
      await appSettingsController.applyTenantSecuritySettings(security);
      sessionAutoLockController.configure(security.autoLockDuration);
      if (AuthSession.isLoggedIn) {
        sessionAutoLockController.arm();
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Otomatik kilit ayarı kaydedildi.')),
      );
    } on TenantSettingsRepositoryException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kayıt başarısız. Lütfen tekrar deneyin.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _passwordSection(BuildContext context, Color? muted) {
    return SettingsSectionCard(
      title: 'Hesap güvenliği',
      children: [
        Text(
          'Şifrenizi güncellemek veya sıfırlama bağlantısı almak için aşağıdaki seçenekleri kullanın.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: muted),
        ),
        const SizedBox(height: 12),
        if (AppBackendConfig.isSupabase) ...[
          OutlinedButton(
            onPressed: () => context.push(AuthPasswordPaths.updatePasswordPath),
            child: const Text('Şifre değiştir'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => context.push(AuthPasswordPaths.forgotPasswordPath),
            child: const Text('Şifre sıfırlama e-postası gönder'),
          ),
        ] else
          const SettingsShellNote(
            message: 'Şifre işlemleri yalnızca uzak sunucu modunda kullanılabilir.',
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final canEdit = AuthSession.canEditClinicProfile;
    final passwordOnly = !AuthSession.canViewDoctorOnlySettings;

    if (passwordOnly) {
      return SettingsSubpageScaffold(
        title: 'Şifre İşlemleri',
        icon: Icons.lock_outline,
        children: [
          _passwordSection(context, muted),
        ],
      );
    }

    const kvkkBullets = [
      'Hasta verileri yalnızca yetkili roller tarafından görüntülenmelidir.',
      'İşlem geçmişi ve erişim kayıtları audit log ekranından izlenebilir.',
      'KVKK uyum süreçleri klinik politikalarıyla birlikte değerlendirilmelidir.',
    ];

    return SettingsSubpageScaffold(
      title: 'Sistem ve Güvenlik',
      icon: Icons.shield_outlined,
      children: [
        SettingsSectionCard(
          title: 'KVKK',
          children: kvkkBullets
              .map(
                (b) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    '• $b',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: muted,
                        ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 12),
        SettingsSectionCard(
          title: 'Oturum güvenliği',
          children: [
            Text(
              'Belirlenen süre boyunca işlem yapılmazsa oturum kilitlenir. Kilit açmak için yeniden giriş gerekir.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: muted),
            ),
            const SizedBox(height: 12),
            if (_loadError != null) ...[
              SettingsShellNote(message: _loadError!),
              const SizedBox(height: AppSpacing.sm),
            ],
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              DropdownButtonFormField<AutoLockDurationKind>(
                value: _autoLockDuration,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Otomatik kilit süresi',
                  isDense: true,
                ),
                items: _autoLockOptions
                    .map(
                      (kind) => DropdownMenuItem(
                        value: kind,
                        child: Text(kind.label),
                      ),
                    )
                    .toList(),
                onChanged: canEdit && !_saving
                    ? (value) {
                        if (value == null) return;
                        setState(() => _autoLockDuration = value);
                      }
                    : null,
              ),
            if (!canEdit) ...[
              const SizedBox(height: AppSpacing.sm),
              const SettingsShellNote(
                message:
                    'Otomatik kilit süresini yalnızca doktor hesabı değiştirebilir.',
              ),
            ],
            if (canEdit) ...[
              const SizedBox(height: AppSpacing.md),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: _saving || _loading ? null : _saveAutoLock,
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Kaydet'),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        _passwordSection(context, muted),
        const SizedBox(height: 12),
        SettingsSectionCard(
          title: 'Uygulama bilgisi',
          children: [
            SettingsReadOnlyRow(label: 'Uygulama', value: AppBranding.productName),
            const SettingsReadOnlyRow(
              label: 'Sürüm',
              value: 'MVP (staging)',
            ),
          ],
        ),
      ],
    );
  }
}
