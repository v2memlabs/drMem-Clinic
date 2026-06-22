import 'package:flutter/material.dart';

import '../../core/auth/auth_session.dart';
import '../../core/session/active_tenant_context_refresher.dart';
import '../../core/theme/app_spacing.dart';
import 'data/settings_image_upload_service.dart';
import 'data/tenant_settings_repository.dart';
import 'data/tenant_settings_repository_provider.dart';
import 'settings_subpage_scaffold.dart';
import 'settings_widgets.dart';
import 'widgets/settings_image_picker_tile.dart';

class ClinicSettingsScreen extends StatefulWidget {
  const ClinicSettingsScreen({super.key});

  @override
  State<ClinicSettingsScreen> createState() => _ClinicSettingsScreenState();
}

class _ClinicSettingsScreenState extends State<ClinicSettingsScreen> {
  static const _timezoneOptions = [
    'Europe/Istanbul',
    'Europe/London',
    'Europe/Berlin',
    'UTC',
  ];

  late final TextEditingController _clinicNameCtrl;
  late final TextEditingController _specialtyCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _websiteCtrl;
  String _timezone = 'Europe/Istanbul';
  String _logoStoragePath = '';
  String _bannerStoragePath = '';
  bool _loading = true;
  bool _saving = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _clinicNameCtrl = TextEditingController();
    _specialtyCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    _addressCtrl = TextEditingController();
    _websiteCtrl = TextEditingController();
    _load();
  }

  @override
  void dispose() {
    _clinicNameCtrl.dispose();
    _specialtyCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _websiteCtrl.dispose();
    super.dispose();
  }

  void _applyInfo(TenantBasicInfo info) {
    _clinicNameCtrl.text = info.name;
    _specialtyCtrl.text = info.specialty;
    _timezone = info.timezone;
    _phoneCtrl.text = info.contact.phone;
    _emailCtrl.text = info.contact.email;
    _addressCtrl.text = info.contact.address;
    _websiteCtrl.text = info.contact.website;
    _logoStoragePath = info.branding.logoStoragePath;
    _bannerStoragePath = info.branding.bannerStoragePath;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final info =
          await TenantSettingsRepositoryProvider.repository.loadBasicInfo();
      if (!mounted) return;
      _applyInfo(info);
      setState(() => _loading = false);
    } on TenantSettingsRepositoryException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadError = 'Klinik bilgileri yüklenemedi.';
        _loading = false;
      });
    }
  }

  Future<void> _saveClinic() async {
    if (_saving || !AuthSession.canEditClinicProfile) return;
    setState(() => _saving = true);
    try {
      final name = _clinicNameCtrl.text.trim();
      final specialty = _specialtyCtrl.text.trim();
      final contact = TenantContactInfo(
        phone: _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        website: _websiteCtrl.text.trim(),
      );
      await TenantSettingsRepositoryProvider.repository.updateBasicInfo(
        name: name,
        specialty: specialty,
        timezone: _timezone,
        contact: contact,
      );
      ActiveTenantContextRefresher.refreshTenantBasicInfo(
        name: name,
        specialty: specialty,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Klinik bilgileri kaydedildi.')),
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

  @override
  Widget build(BuildContext context) {
    final editable = AuthSession.canEditClinicProfile;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return SettingsSubpageScaffold(
      title: 'Klinik Bilgileri',
      icon: Icons.local_hospital_outlined,
      children: [
        if (_loadError != null) ...[
          SettingsShellNote(message: _loadError!),
          const SizedBox(height: AppSpacing.sm),
        ],
        SettingsSectionCard(
          title: 'Klinik kimliği',
          children: [
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SettingsImagePickerTile(
                      label: 'Klinik logosu',
                      icon: Icons.business_outlined,
                      height: 88,
                      kind: SettingsImageKind.clinicLogo,
                      storagePath: _logoStoragePath,
                      enabled: editable && !_saving,
                      onUploaded: (path) => setState(() => _logoStoragePath = path),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    flex: 2,
                    child: SettingsImagePickerTile(
                      label: 'Tabela / klinik fotoğrafı',
                      height: 88,
                      kind: SettingsImageKind.clinicBanner,
                      storagePath: _bannerStoragePath,
                      enabled: editable && !_saving,
                      onUploaded: (path) => setState(() => _bannerStoragePath = path),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              if (editable) ...[
                TextField(
                  controller: _clinicNameCtrl,
                  enabled: !_saving,
                  decoration: const InputDecoration(labelText: 'Klinik adı', isDense: true),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _specialtyCtrl,
                  enabled: !_saving,
                  decoration: const InputDecoration(labelText: 'Branş', isDense: true),
                ),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<String>(
                  value: _timezoneOptions.contains(_timezone) ? _timezone : _timezoneOptions.first,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Saat dilimi', isDense: true),
                  items: _timezoneOptions
                      .map((tz) => DropdownMenuItem(value: tz, child: Text(tz)))
                      .toList(),
                  onChanged: _saving
                      ? null
                      : (value) {
                          if (value != null) setState(() => _timezone = value);
                        },
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _phoneCtrl,
                  enabled: !_saving,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Telefon', isDense: true),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _emailCtrl,
                  enabled: !_saving,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'E-posta', isDense: true),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _addressCtrl,
                  enabled: !_saving,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Adres', isDense: true),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _websiteCtrl,
                  enabled: !_saving,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(labelText: 'Web sitesi', isDense: true),
                ),
              ] else ...[
                SettingsReadOnlyRow(
                  label: 'Klinik adı',
                  value: _clinicNameCtrl.text.isEmpty ? '—' : _clinicNameCtrl.text,
                ),
                SettingsReadOnlyRow(
                  label: 'Branş',
                  value: _specialtyCtrl.text.isEmpty ? '—' : _specialtyCtrl.text,
                ),
                SettingsReadOnlyRow(label: 'Saat dilimi', value: _timezone),
                SettingsReadOnlyRow(
                  label: 'Telefon',
                  value: _phoneCtrl.text.isEmpty ? '—' : _phoneCtrl.text,
                ),
                SettingsReadOnlyRow(
                  label: 'E-posta',
                  value: _emailCtrl.text.isEmpty ? '—' : _emailCtrl.text,
                ),
                SettingsReadOnlyRow(
                  label: 'Adres',
                  value: _addressCtrl.text.isEmpty ? '—' : _addressCtrl.text,
                ),
                SettingsReadOnlyRow(
                  label: 'Web sitesi',
                  value: _websiteCtrl.text.isEmpty ? '—' : _websiteCtrl.text,
                ),
                Text(
                  'Klinik bilgilerini yalnızca doktor hesabı düzenleyebilir.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: muted),
                ),
              ],
            ],
          ],
          footer: editable && !_loading
              ? Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: _saving ? null : _saveClinic,
                    child: Text(_saving ? 'Kaydediliyor…' : 'Kaydet'),
                  ),
                )
              : null,
        ),
        const SizedBox(height: AppSpacing.sm),
        SettingsSectionCard(
          title: 'PDF üst bilgi önizleme',
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _clinicNameCtrl.text.isEmpty ? 'Klinik adı' : _clinicNameCtrl.text,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  if (_specialtyCtrl.text.isNotEmpty)
                    Text(
                      _specialtyCtrl.text,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: muted),
                    ),
                  if (_phoneCtrl.text.isNotEmpty || _emailCtrl.text.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      [
                        if (_phoneCtrl.text.isNotEmpty) _phoneCtrl.text,
                        if (_emailCtrl.text.isNotEmpty) _emailCtrl.text,
                      ].join(' · '),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: muted),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'PDF çıktılarında kullanılacak üst bilgi önizlemesi.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
