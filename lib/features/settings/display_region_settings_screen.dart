import 'package:flutter/material.dart';

import '../../core/auth/auth_session.dart';
import '../../core/settings/app_settings.dart';
import '../../core/settings/app_settings_controller.dart';
import '../../core/theme/app_spacing.dart';
import 'data/profile_settings_repository.dart';
import 'data/profile_settings_repository_provider.dart';
import 'data/tenant_settings_repository.dart';
import 'data/tenant_settings_repository_provider.dart';
import 'models/tenant_preferences.dart';
import 'models/user_display_preferences.dart';
import 'settings_subpage_scaffold.dart';
import 'settings_widgets.dart';

class DisplayRegionSettingsScreen extends StatefulWidget {
  const DisplayRegionSettingsScreen({super.key});

  @override
  State<DisplayRegionSettingsScreen> createState() =>
      _DisplayRegionSettingsScreenState();
}

class _DisplayRegionSettingsScreenState extends State<DisplayRegionSettingsScreen> {
  static const _formatOptions = [
    DateTimeFormatKind.shortTurkish,
    DateTimeFormatKind.longTurkish,
    DateTimeFormatKind.iso,
  ];

  static const _languageOptions = <String, String>{
    'tr': 'Türkçe',
    'en': 'English',
  };

  static const _currencyOptions = ['TRY', 'EUR', 'USD'];

  static const _weekStartOptions = <String, String>{
    'monday': 'Pazartesi',
    'sunday': 'Pazar',
  };

  bool _loading = true;
  bool _saving = false;
  String? _loadError;
  DateTimeFormatKind _selectedFormat = DateTimeFormatKind.shortTurkish;
  TimeFormatKind _selectedTimeFormat = TimeFormatKind.hour24;
  AppThemeModeKind _themeMode = AppThemeModeKind.light;
  String _languageCode = 'tr';
  String _currencyCode = 'TRY';
  String _weekStart = 'monday';

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
    final settings = appSettingsController.settings;
    setState(() {
      _selectedFormat = settings.dateTimeFormat;
      _selectedTimeFormat = settings.timeFormat;
      _themeMode = settings.themeMode;
      _languageCode = settings.languageCode;
    });
  }

  void _applyPersonal(UserDisplayPreferences preferences) {
    _selectedFormat = preferences.dateTimeFormat;
    _selectedTimeFormat = preferences.timeFormat;
    _themeMode = preferences.themeMode;
    _languageCode = preferences.languageCode;
  }

  void _applyRegional(TenantPreferences preferences) {
    _currencyCode = preferences.currencyCode;
    _weekStart = preferences.weekStart;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final tenantPreferences =
          await TenantSettingsRepositoryProvider.repository.loadPreferences();
      UserDisplayPreferences? userPreferences;
      try {
        userPreferences = await ProfileSettingsRepositoryProvider.repository
            .loadMyDisplayPreferences();
      } catch (_) {
        // Profil kaynağı yoksa tenant varsayılanı kullanılır.
      }

      final personal =
          userPreferences ?? UserDisplayPreferences.fromTenant(tenantPreferences);

      if (!mounted) return;
      await appSettingsController.applyUserDisplayPreferences(personal);
      setState(() {
        _applyPersonal(personal);
        _applyRegional(tenantPreferences);
        _loading = false;
      });
    } on TenantSettingsRepositoryException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.message;
        _applyPersonal(UserDisplayPreferences(
          dateTimeFormat: appSettingsController.settings.dateTimeFormat,
          timeFormat: appSettingsController.settings.timeFormat,
          themeMode: appSettingsController.settings.themeMode,
          languageCode: appSettingsController.settings.languageCode,
        ));
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadError = 'Tercihler yüklenemedi.';
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final personal = UserDisplayPreferences(
        dateTimeFormat: _selectedFormat,
        timeFormat: _selectedTimeFormat,
        themeMode: _themeMode,
        languageCode: _languageCode,
      );
      await ProfileSettingsRepositoryProvider.repository
          .updateMyDisplayPreferences(personal);
      await appSettingsController.applyUserDisplayPreferences(personal);

      if (AuthSession.canEditClinicProfile) {
        final current =
            await TenantSettingsRepositoryProvider.repository.loadPreferences();
        await TenantSettingsRepositoryProvider.repository.updatePreferences(
          current.copyWith(
            currencyCode: _currencyCode,
            weekStart: _weekStart,
          ),
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Görünüm tercihleri kaydedildi.')),
      );
    } on TenantSettingsRepositoryException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
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
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final canEditClinicRegional = AuthSession.canEditClinicProfile;
    final sample = AppSettings.formatDateTime(
      DateTime.now(),
      _selectedFormat,
      timeFormat: _selectedTimeFormat,
    );

    return SettingsSubpageScaffold(
      title: 'Görünüm ve Bölge',
      icon: Icons.tune_outlined,
      children: [
        if (_loadError != null) ...[
          SettingsShellNote(message: _loadError!),
          const SizedBox(height: AppSpacing.sm),
        ],
        SettingsSectionCard(
          title: 'Kişisel görünüm',
          children: [
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              Text(
                'Tema, dil ve tarih formatı yalnızca sizin ekranınızı etkiler.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: muted),
              ),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<String>(
                value: _languageOptions.containsKey(_languageCode)
                    ? _languageCode
                    : 'tr',
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Dil', isDense: true),
                items: _languageOptions.entries
                    .map(
                      (e) => DropdownMenuItem(
                        value: e.key,
                        child: Text(e.value),
                      ),
                    )
                    .toList(),
                onChanged: _saving
                    ? null
                    : (value) {
                        if (value != null) setState(() => _languageCode = value);
                      },
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Tarih ve saat formatı',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              ..._formatOptions.map(
                (format) => RadioListTile<DateTimeFormatKind>(
                  value: format,
                  groupValue: _selectedFormat,
                  onChanged: _saving
                      ? null
                      : (value) {
                          if (value == null) return;
                          setState(() => _selectedFormat = value);
                        },
                  title: Text(format.label),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              Text(
                'Önizleme: $sample',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: muted),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Saat formatı',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              ...TimeFormatKind.values.map(
                (format) => RadioListTile<TimeFormatKind>(
                  value: format,
                  groupValue: _selectedTimeFormat,
                  onChanged: _saving
                      ? null
                      : (value) {
                          if (value == null) return;
                          setState(() => _selectedTimeFormat = value);
                        },
                  title: Text(format.label),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Tema',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              ...AppThemeModeKind.values.map(
                (mode) => RadioListTile<AppThemeModeKind>(
                  value: mode,
                  groupValue: _themeMode,
                  onChanged: _saving
                      ? null
                      : (value) {
                          if (value == null) return;
                          setState(() => _themeMode = value);
                        },
                  title: Text(mode.label),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        SettingsSectionCard(
          title: 'Klinik bölge ayarları',
          children: [
            if (_loading)
              const SizedBox.shrink()
            else ...[
              Text(
                canEditClinicRegional
                    ? 'Para birimi ve hafta başlangıcı tüm klinik için geçerlidir.'
                    : 'Para birimi ve hafta başlangıcı yalnızca doktor hesabı tarafından değiştirilebilir.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: muted),
              ),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<String>(
                value: _currencyOptions.contains(_currencyCode)
                    ? _currencyCode
                    : _currencyOptions.first,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Para birimi', isDense: true),
                items: _currencyOptions
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: canEditClinicRegional && !_saving
                    ? (value) {
                        if (value != null) setState(() => _currencyCode = value);
                      }
                    : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<String>(
                value: _weekStartOptions.containsKey(_weekStart)
                    ? _weekStart
                    : 'monday',
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Haftanın başlangıç günü',
                  isDense: true,
                ),
                items: _weekStartOptions.entries
                    .map(
                      (e) => DropdownMenuItem(
                        value: e.key,
                        child: Text(e.value),
                      ),
                    )
                    .toList(),
                onChanged: canEditClinicRegional && !_saving
                    ? (value) {
                        if (value != null) setState(() => _weekStart = value);
                      }
                    : null,
              ),
            ],
          ],
          footer: !_loading
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
