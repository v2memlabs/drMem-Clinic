import 'package:flutter/material.dart';

import '../../core/auth/auth_session.dart';
import '../../core/settings/app_settings.dart';
import '../../core/settings/app_settings_controller.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/app_time_picker.dart';
import 'data/clinic_workflow_settings_repository.dart';
import 'data/clinic_workflow_settings_repository_provider.dart';
import 'models/clinic_workflow_settings.dart';
import 'settings_subpage_scaffold.dart';
import 'settings_categories.dart';
import 'settings_widgets.dart';
import '../../shared/widgets/clinical_notice.dart';
import '../../shared/widgets/clinical_notice_tone.dart';

class ClinicWorkflowSettingsScreen extends StatefulWidget {
  const ClinicWorkflowSettingsScreen({super.key});

  @override
  State<ClinicWorkflowSettingsScreen> createState() =>
      _ClinicWorkflowSettingsScreenState();
}

class _ClinicWorkflowSettingsScreenState
    extends State<ClinicWorkflowSettingsScreen> {
  static const _weekdayLabels = [
    'Pazartesi',
    'Salı',
    'Çarşamba',
    'Perşembe',
    'Cuma',
    'Cumartesi',
    'Pazar',
  ];

  ClinicWorkflowSettings? _settings;
  bool _loading = true;
  bool _saving = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    appSettingsController.addListener(_onSettingsChanged);
    _load();
  }

  @override
  void dispose() {
    appSettingsController.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final loaded =
          await ClinicWorkflowSettingsRepositoryProvider.repository.load();
      if (!mounted) return;
      setState(() {
        _settings = loaded ?? ClinicWorkflowSettings.defaultClinic();
        _loading = false;
      });
    } on ClinicWorkflowSettingsRepositoryException {
      if (!mounted) return;
      setState(() {
        _loadError = 'Ayarlar yüklenemedi. Lütfen tekrar deneyin.';
        _settings = ClinicWorkflowSettings.defaultClinic();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadError = 'Ayarlar yüklenemedi. Lütfen tekrar deneyin.';
        _settings = ClinicWorkflowSettings.defaultClinic();
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    final settings = _settings;
    if (settings == null) return;

    setState(() => _saving = true);
    try {
      await ClinicWorkflowSettingsRepositoryProvider.repository.save(settings);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Klinik işleyiş ayarları kaydedildi.')),
      );
    } on ClinicWorkflowSettingsRepositoryException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ayarlar kaydedilemedi. Lütfen tekrar deneyin.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ayarlar kaydedilemedi. Lütfen tekrar deneyin.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _updateSettings(ClinicWorkflowSettings settings) {
    setState(() => _settings = settings);
  }

  String _formatTime(TimeOfDay t) {
    return AppSettings.formatTimeOfDay(
      t,
      appSettingsController.settings.timeFormat,
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  Future<void> _pickTime({
    required TimeOfDay initial,
    required ValueChanged<TimeOfDay> onPicked,
    required bool enabled,
  }) async {
    if (!enabled) return;
    final picked = await showAppTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked != null) onPicked(picked);
  }

  Future<void> _addClosedDate(bool enabled) async {
    if (!enabled || _settings == null) return;
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked == null || !mounted) return;
    final day = DateTime(picked.year, picked.month, picked.day);
    final existing = _settings!.closedDates;
    if (existing.any(
      (d) => d.year == day.year && d.month == day.month && d.day == day.day,
    )) {
      return;
    }
    _updateSettings(
      ClinicWorkflowSettings(
        slotDurationMinutes: _settings!.slotDurationMinutes,
        lunchBreak: _settings!.lunchBreak,
        weekdays: _settings!.weekdays,
        closedDates: [...existing, day]..sort((a, b) => a.compareTo(b)),
      ),
    );
  }

  void _removeClosedDate(DateTime day, bool enabled) {
    if (!enabled || _settings == null) return;
    _updateSettings(
      ClinicWorkflowSettings(
        slotDurationMinutes: _settings!.slotDurationMinutes,
        lunchBreak: _settings!.lunchBreak,
        weekdays: _settings!.weekdays,
        closedDates: _settings!.closedDates
            .where(
              (d) =>
                  !(d.year == day.year &&
                      d.month == day.month &&
                      d.day == day.day),
            )
            .toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canEdit = AuthSession.canEditClinicProfile;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final settings = _settings;

    return SettingsSubpageScaffold(
      title: 'Klinik İşleyiş',
      icon: Icons.schedule_outlined,
      fallbackRoute: SettingsCategories.hubPath,
      children: [
        ClinicalNotice(
          tone: ClinicalNoticeTone.info,
          dense: true,
          message: canEdit
              ? 'Randevu oluşturma ekranındaki müsait saatler bu ayarlara göre hesaplanır.'
              : 'Bu ayarları yalnızca doktor hesabı düzenleyebilir. Görüntüleme modundasınız.',
        ),
        if (_loadError != null) ...[
          ClinicalNotice(
            tone: ClinicalNoticeTone.danger,
            dense: true,
            message: _loadError!,
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (_loading)
          const Center(child: Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: CircularProgressIndicator(),
          ))
        else if (settings != null) ...[
          SettingsSectionCard(
            title: 'Slot süresi',
            children: [
              DropdownButtonFormField<int>(
                value: settings.slotDurationMinutes,
                decoration: const InputDecoration(
                  labelText: 'Randevu slot süresi',
                  isDense: true,
                ),
                items: ClinicWorkflowSettings.allowedSlotDurations
                    .map(
                      (m) => DropdownMenuItem(
                        value: m,
                        child: Text('$m dakika'),
                      ),
                    )
                    .toList(),
                onChanged: canEdit
                    ? (v) {
                        if (v == null) return;
                        _updateSettings(
                          ClinicWorkflowSettings(
                            slotDurationMinutes: v,
                            lunchBreak: settings.lunchBreak,
                            weekdays: settings.weekdays,
                            closedDates: settings.closedDates,
                          ),
                        );
                      }
                    : null,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SettingsSectionCard(
            title: 'Çalışma günleri ve saatleri',
            children: [
              for (var i = 0; i < settings.weekdays.length; i++)
                _WeekdayRow(
                  label: _weekdayLabels[i],
                  day: settings.weekdays[i],
                  canEdit: canEdit,
                  formatTime: _formatTime,
                  onEnabledChanged: (enabled) {
                    final list = List<ClinicWeekdaySettings>.from(
                      settings.weekdays,
                    );
                    list[i] = list[i].copyWith(enabled: enabled);
                    _updateSettings(
                      ClinicWorkflowSettings(
                        slotDurationMinutes: settings.slotDurationMinutes,
                        lunchBreak: settings.lunchBreak,
                        weekdays: list,
                        closedDates: settings.closedDates,
                      ),
                    );
                  },
                  onStartChanged: (t) {
                    final list = List<ClinicWeekdaySettings>.from(
                      settings.weekdays,
                    );
                    list[i] = list[i].copyWith(start: t);
                    _updateSettings(
                      ClinicWorkflowSettings(
                        slotDurationMinutes: settings.slotDurationMinutes,
                        lunchBreak: settings.lunchBreak,
                        weekdays: list,
                        closedDates: settings.closedDates,
                      ),
                    );
                  },
                  onEndChanged: (t) {
                    final list = List<ClinicWeekdaySettings>.from(
                      settings.weekdays,
                    );
                    list[i] = list[i].copyWith(end: t);
                    _updateSettings(
                      ClinicWorkflowSettings(
                        slotDurationMinutes: settings.slotDurationMinutes,
                        lunchBreak: settings.lunchBreak,
                        weekdays: list,
                        closedDates: settings.closedDates,
                      ),
                    );
                  },
                  onPickTime: (initial, onPicked) => _pickTime(
                    initial: initial,
                    onPicked: onPicked,
                    enabled: canEdit,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SettingsSectionCard(
            title: 'Öğle arası / mola',
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Öğle arası aktif'),
                value: settings.lunchBreak.enabled,
                onChanged: canEdit
                    ? (v) {
                        _updateSettings(
                          ClinicWorkflowSettings(
                            slotDurationMinutes: settings.slotDurationMinutes,
                            lunchBreak: settings.lunchBreak.copyWith(
                              enabled: v,
                            ),
                            weekdays: settings.weekdays,
                            closedDates: settings.closedDates,
                          ),
                        );
                      }
                    : null,
              ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: canEdit && settings.lunchBreak.enabled
                          ? () => _pickTime(
                                initial: settings.lunchBreak.start,
                                onPicked: (t) {
                                  _updateSettings(
                                    ClinicWorkflowSettings(
                                      slotDurationMinutes:
                                          settings.slotDurationMinutes,
                                      lunchBreak: settings.lunchBreak.copyWith(
                                        start: t,
                                      ),
                                      weekdays: settings.weekdays,
                                      closedDates: settings.closedDates,
                                    ),
                                  );
                                },
                                enabled: true,
                              )
                          : null,
                      child: Text(
                        'Başlangıç: ${_formatTime(settings.lunchBreak.start)}',
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: canEdit && settings.lunchBreak.enabled
                          ? () => _pickTime(
                                initial: settings.lunchBreak.end,
                                onPicked: (t) {
                                  _updateSettings(
                                    ClinicWorkflowSettings(
                                      slotDurationMinutes:
                                          settings.slotDurationMinutes,
                                      lunchBreak: settings.lunchBreak.copyWith(
                                        end: t,
                                      ),
                                      weekdays: settings.weekdays,
                                      closedDates: settings.closedDates,
                                    ),
                                  );
                                },
                                enabled: true,
                              )
                          : null,
                      child: Text(
                        'Bitiş: ${_formatTime(settings.lunchBreak.end)}',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SettingsSectionCard(
            title: 'Kapalı tarihler',
            children: [
              if (settings.closedDates.isEmpty)
                Text(
                  'Henüz tanımlı kapalı tarih yok.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: muted,
                      ),
                )
              else
                ...settings.closedDates.map(
                  (d) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(_formatDate(d)),
                    trailing: canEdit
                        ? IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _removeClosedDate(d, canEdit),
                            tooltip: 'Kaldır',
                          )
                        : null,
                  ),
                ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: canEdit ? () => _addClosedDate(canEdit) : null,
                icon: const Icon(Icons.event_busy_outlined),
                label: const Text('Kapalı tarih ekle'),
              ),
            ],
          ),
          if (canEdit) ...[
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(_saving ? 'Kaydediliyor…' : 'Kaydet'),
            ),
          ],
        ],
      ],
    );
  }
}

class _WeekdayRow extends StatelessWidget {
  final String label;
  final ClinicWeekdaySettings day;
  final bool canEdit;
  final String Function(TimeOfDay) formatTime;
  final ValueChanged<bool> onEnabledChanged;
  final ValueChanged<TimeOfDay> onStartChanged;
  final ValueChanged<TimeOfDay> onEndChanged;
  final Future<void> Function(
    TimeOfDay initial,
    ValueChanged<TimeOfDay> onPicked,
  ) onPickTime;

  const _WeekdayRow({
    required this.label,
    required this.day,
    required this.canEdit,
    required this.formatTime,
    required this.onEnabledChanged,
    required this.onStartChanged,
    required this.onEndChanged,
    required this.onPickTime,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SizedBox(
                width: 100,
                child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
              ),
              Switch(
                value: day.enabled,
                onChanged: canEdit ? onEnabledChanged : null,
              ),
            ],
          ),
          if (day.enabled)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: canEdit
                        ? () => onPickTime(day.start, onStartChanged)
                        : null,
                    child: Text('Başlangıç: ${formatTime(day.start)}'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton(
                    onPressed: canEdit
                        ? () => onPickTime(day.end, onEndChanged)
                        : null,
                    child: Text('Bitiş: ${formatTime(day.end)}'),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
