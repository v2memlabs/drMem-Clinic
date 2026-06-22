import 'package:flutter/material.dart';

import '../../core/auth/auth_session.dart';
import '../../core/theme/app_spacing.dart';
import '../patient_tags/widgets/patient_tag_list_content.dart';
import '../patients/data/patient_file_number_helper.dart';
import 'data/tenant_settings_repository.dart';
import 'data/tenant_settings_repository_provider.dart';
import 'models/patient_registration_settings.dart';
import 'models/patient_required_field.dart';
import 'settings_subpage_scaffold.dart';
import 'settings_widgets.dart';

class PatientSettingsScreen extends StatefulWidget {
  const PatientSettingsScreen({super.key});

  @override
  State<PatientSettingsScreen> createState() => _PatientSettingsScreenState();
}

class _PatientSettingsScreenState extends State<PatientSettingsScreen> {
  String _fileNumberFormat = PatientRegistrationSettings.defaultFileNumberFormat;
  int _seqPadding = PatientRegistrationSettings.defaultSeqPadding;
  Set<PatientRequiredField> _requiredFields = {};
  bool _loading = true;
  bool _saving = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  PatientRegistrationSettings get _currentSettings => PatientRegistrationSettings(
        fileNumberFormat: _fileNumberFormat,
        seqPadding: _seqPadding,
        requiredFields: _requiredFields,
      );

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final settings = await TenantSettingsRepositoryProvider.repository
          .loadPatientRegistrationSettings();
      if (!mounted) return;
      setState(() {
        _fileNumberFormat = settings.fileNumberFormat;
        _seqPadding = settings.seqPadding;
        _requiredFields = Set<PatientRequiredField>.from(settings.requiredFields);
        _loading = false;
      });
    } on TenantSettingsRepositoryException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadError = 'Hasta kayıt ayarları yüklenemedi.';
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    if (_saving || !AuthSession.canEditClinicProfile) return;
    setState(() => _saving = true);
    try {
      await TenantSettingsRepositoryProvider.repository
          .updatePatientRegistrationSettings(_currentSettings);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hasta kayıt ayarları kaydedildi.')),
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

  String get _previewNumber {
    return PatientFileNumberHelper.nextFromExisting(
      const [],
      settings: _currentSettings,
      year: DateTime.now().year,
    );
  }

  void _toggleRequiredField(PatientRequiredField field, bool? value) {
    if (value == null) return;
    setState(() {
      if (value) {
        _requiredFields.add(field);
      } else {
        _requiredFields.remove(field);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final canEdit = AuthSession.canEditClinicProfile;

    return SettingsSubpageScaffold(
      title: 'Hasta Ayarları',
      icon: Icons.badge_outlined,
      children: [
        if (_loadError != null) ...[
          SettingsShellNote(message: _loadError!),
          const SizedBox(height: AppSpacing.sm),
        ],
        SettingsSectionCard(
          title: 'Hasta etiketleri',
          children: [
            Text(
              'Klinik genelinde kullanılacak hasta etiketlerini tanımlayın. '
              'Hasta detayından etiket atayabilirsiniz.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: muted),
            ),
            const SizedBox(height: AppSpacing.md),
            const SizedBox(
              height: 360,
              child: PatientTagListContent(),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        SettingsSectionCard(
          title: 'Kayıt formatı',
          children: [
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              Text(
                'Yeni hasta kayıtlarında otomatik dosya numarası bu şablona göre üretilir. '
                '{seq} sıra numarası, {year} yıl anlamına gelir.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: muted),
              ),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<String>(
                value: PatientRegistrationSettings.formatPresets
                        .any((p) => p.format == _fileNumberFormat)
                    ? _fileNumberFormat
                    : PatientRegistrationSettings.formatPresets.first.format,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Dosya no formatı',
                  isDense: true,
                ),
                items: PatientRegistrationSettings.formatPresets
                    .map(
                      (p) => DropdownMenuItem(
                        value: p.format,
                        child: Text(p.label),
                      ),
                    )
                    .toList(),
                onChanged: canEdit && !_saving
                    ? (value) {
                        if (value == null) return;
                        setState(() {
                          _fileNumberFormat = value;
                          if (value == 'A-{seq}' || value == 'DEMO-{seq}') {
                            _seqPadding = 3;
                          } else {
                            _seqPadding = PatientRegistrationSettings.defaultSeqPadding;
                          }
                        });
                      }
                    : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              SettingsReadOnlyRow(
                label: 'Örnek',
                value: _previewNumber,
              ),
              if (!canEdit) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Kayıt ayarlarını yalnızca doktor hesabı değiştirebilir.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: muted),
                ),
              ],
            ],
          ],
          footer: canEdit && !_loading
              ? Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    child: Text(_saving ? 'Kaydediliyor…' : 'Kaydet'),
                  ),
                )
              : null,
        ),
        const SizedBox(height: AppSpacing.sm),
        SettingsSectionCard(
          title: 'Kimlik tipi seçenekleri',
          children: const [
            SettingsReadOnlyRow(
              label: 'Seçenekler',
              value: 'T.C. · Pasaport · Yabancı kimlik',
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        SettingsSectionCard(
          title: 'Zorunlu alanlar',
          children: [
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              Text(
                'Ad, soyad ve doğum tarihi her zaman zorunludur. '
                'Aşağıdaki alanları klinik kayıt politikasına göre zorunlu yapabilirsiniz.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: muted),
              ),
              const SizedBox(height: AppSpacing.sm),
              ...PatientRequiredField.values.map(
                (field) => CheckboxListTile(
                  value: _requiredFields.contains(field),
                  onChanged: canEdit && !_saving
                      ? (value) => _toggleRequiredField(field, value)
                      : null,
                  title: Text(field.label),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ),
              if (!canEdit) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Zorunlu alanları yalnızca doktor hesabı değiştirebilir.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: muted),
                ),
              ],
            ],
          ],
          footer: canEdit && !_loading
              ? Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    child: Text(_saving ? 'Kaydediliyor…' : 'Kaydet'),
                  ),
                )
              : null,
        ),
      ],
    );
  }
}
