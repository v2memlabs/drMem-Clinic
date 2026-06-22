import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_session.dart';
import '../../core/session/active_tenant_context_refresher.dart';
import '../../core/theme/app_spacing.dart';
import 'data/profile_settings_repository.dart';
import 'data/profile_settings_repository_provider.dart';
import 'models/my_profile_settings.dart';
import 'settings_product_labels.dart';
import 'settings_subpage_scaffold.dart';
import 'data/settings_image_upload_service.dart';
import 'settings_widgets.dart';
import 'widgets/settings_image_picker_tile.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  late final TextEditingController _displayNameCtrl;
  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _titleCtrl;
  late final TextEditingController _phoneCtrl;
  String _email = '';
  String _avatarStoragePath = '';
  bool _loading = true;
  bool _saving = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _displayNameCtrl = TextEditingController();
    _firstNameCtrl = TextEditingController();
    _lastNameCtrl = TextEditingController();
    _titleCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _load();
  }

  @override
  void dispose() {
    _displayNameCtrl.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _titleCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _applyProfile(MyProfileSettings profile) {
    _displayNameCtrl.text = profile.displayName;
    _firstNameCtrl.text = profile.firstName;
    _lastNameCtrl.text = profile.lastName;
    _titleCtrl.text = profile.title;
    _phoneCtrl.text = profile.phone;
    _email = profile.email;
    _avatarStoragePath = profile.avatarStoragePath;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final profile =
          await ProfileSettingsRepositoryProvider.repository.loadMyProfile();
      if (!mounted) return;
      _applyProfile(profile);
      setState(() => _loading = false);
    } on ProfileSettingsRepositoryException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.message;
        _loading = false;
        final sessionName = AuthSession.currentUser?.displayName;
        if (sessionName != null && sessionName.trim().isNotEmpty) {
          _displayNameCtrl.text = sessionName.trim();
        }
        _email = AuthSession.currentUser?.username ?? '';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadError = 'Profil yüklenemedi.';
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final profile = MyProfileSettings(
        displayName: _displayNameCtrl.text.trim(),
        firstName: _firstNameCtrl.text.trim(),
        lastName: _lastNameCtrl.text.trim(),
        title: _titleCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        email: _email,
      );
      await ProfileSettingsRepositoryProvider.repository.updateMyProfile(profile);
      AuthSession.updateDisplayName(profile.displayName);
      ActiveTenantContextRefresher.refreshProfileDisplayName(profile.displayName);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil bilgileri kaydedildi.')),
      );
    } on ProfileSettingsRepositoryException catch (e) {
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

  @override
  Widget build(BuildContext context) {
    final user = AuthSession.currentUser;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return SettingsSubpageScaffold(
      title: 'Profil Bilgileri',
      icon: Icons.person_outline,
      children: [
        if (_loadError != null) ...[
          SettingsShellNote(message: _loadError!),
          const SizedBox(height: AppSpacing.sm),
        ],
        SettingsSectionCard(
          title: 'Profil',
          children: [
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              Center(
                child: SizedBox(
                  width: 160,
                  child: SettingsImagePickerTile(
                    label: 'Profil fotoğrafı',
                    icon: Icons.account_circle_outlined,
                    height: 120,
                    kind: SettingsImageKind.profileAvatar,
                    storagePath: _avatarStoragePath,
                    enabled: !_saving,
                    onUploaded: (path) => setState(() => _avatarStoragePath = path),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _firstNameCtrl,
                enabled: !_saving,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Ad', isDense: true),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _lastNameCtrl,
                enabled: !_saving,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Soyad', isDense: true),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _titleCtrl,
                enabled: !_saving,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Ünvan',
                  hintText: 'Örn. Op. Dr.',
                  isDense: true,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _displayNameCtrl,
                enabled: !_saving,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Görünen kullanıcı adı',
                  isDense: true,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SettingsReadOnlyRow(
                label: 'E-posta',
                value: _email.isEmpty ? '—' : _email,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _phoneCtrl,
                enabled: !_saving,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(labelText: 'Telefon', isDense: true),
              ),
              if (user != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Rol: ${SettingsProductLabels.roleLabel(user.role)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: muted),
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              Text(
                AuthSession.canViewDoctorOnlySettings
                    ? 'Şifre değişikliği için Ayarlar → Sistem ve Güvenlik bölümünü kullanın.'
                    : 'Şifre değişikliği için Ayarlar → Şifre İşlemleri bölümünü kullanın.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: muted),
              ),
            ],
          ],
          footer: _loading
              ? null
              : Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    child: Text(_saving ? 'Kaydediliyor…' : 'Kaydet'),
                  ),
                ),
        ),
        if (AuthSession.canViewConsentTemplates) ...[
          const SizedBox(height: AppSpacing.md),
          SettingsSectionCard(
            title: 'Onam Form Şablonları',
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.description_outlined),
                title: const Text('Onam / KVKK şablonlarım'),
                subtitle: const Text(
                  'Metin oluştur, PDF yükle veya hazır şablonu düzenle',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: _saving ? null : () => context.push('/consent-templates'),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
