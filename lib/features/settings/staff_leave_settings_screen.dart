import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_session.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'models/staff_leave_record.dart';
import 'data/staff_leave_record_mapper.dart';
import 'data/staff_leave_record_repository.dart';
import 'data/staff_leave_record_repository_provider.dart';
import 'settings_subpage_scaffold.dart';
import 'settings_categories.dart';
import 'settings_widgets.dart';
import '../../shared/widgets/app_time_picker.dart';
import '../../shared/widgets/clinical_notice.dart';
import '../../shared/widgets/clinical_notice_tone.dart';

enum _StaffLeaveListFilter { all, active, cancelled }

class StaffLeaveSettingsScreen extends StatefulWidget {
  const StaffLeaveSettingsScreen({super.key});

  @override
  State<StaffLeaveSettingsScreen> createState() =>
      _StaffLeaveSettingsScreenState();
}

class _StaffLeaveSettingsScreenState extends State<StaffLeaveSettingsScreen> {
  List<StaffLeaveRecord> _records = [];
  bool _loading = true;
  String? _loadError;
  bool _busy = false;
  _StaffLeaveListFilter _filter = _StaffLeaveListFilter.all;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final list = await StaffLeaveRecordRepositoryProvider.repository.list();
      if (!mounted) return;
      setState(() {
        _records = list;
        _loading = false;
      });
    } on StaffLeaveRecordRepositoryException {
      if (!mounted) return;
      setState(() {
        _loadError = 'Kayıtlar yüklenemedi. Lütfen tekrar deneyin.';
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadError = 'Kayıtlar yüklenemedi. Lütfen tekrar deneyin.';
        _loading = false;
      });
    }
  }

  List<StaffLeaveRecord> get _filteredRecords {
    switch (_filter) {
      case _StaffLeaveListFilter.active:
        return _records.where((r) => r.isActive).toList();
      case _StaffLeaveListFilter.cancelled:
        return _records.where((r) => !r.isActive).toList();
      case _StaffLeaveListFilter.all:
        return _records;
    }
  }

  String _formatDateTime(DateTime dt) {
    const months = [
      'Oca',
      'Şub',
      'Mar',
      'Nis',
      'May',
      'Haz',
      'Tem',
      'Ağu',
      'Eyl',
      'Eki',
      'Kas',
      'Ara',
    ];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} ${dt.year} $h:$m';
  }

  Future<void> _openForm({StaffLeaveRecord? existing}) async {
    if (!AuthSession.canEditClinicProfile) return;
    final result = await showDialog<StaffLeaveDraft>(
      context: context,
      builder: (context) => _StaffLeaveFormDialog(existing: existing),
    );
    if (result == null || !mounted) return;

    setState(() => _busy = true);
    try {
      if (existing != null) {
        final updated = existing.copyWith(
          staffDisplayName: result.staffDisplayName,
          roleLabel: result.roleLabel,
          leaveType: result.leaveType,
          startsAt: result.startsAt,
          endsAt: result.endsAt,
          note: result.note,
          updatedAt: DateTime.now(),
        );
        await StaffLeaveRecordRepositoryProvider.repository.update(updated);
      } else {
        await StaffLeaveRecordRepositoryProvider.repository.create(result);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('İzin kaydı kaydedildi.')),
      );
      await _load();
    } on StaffLeaveRecordValidationException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } on StaffLeaveRecordRepositoryException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('İzin kaydı kaydedilemedi. Lütfen tekrar deneyin.'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('İzin kaydı kaydedilemedi. Lütfen tekrar deneyin.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmCancel(StaffLeaveRecord record) async {
    if (!AuthSession.canEditClinicProfile || !record.isActive) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('İzin kaydını iptal et'),
        content: const Text(
          'Bu izin kaydı iptal edilecek. Kayıt silinmez; durum "İptal edildi" olarak işaretlenir.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('İptal et'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _busy = true);
    try {
      await StaffLeaveRecordRepositoryProvider.repository.cancel(record.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('İzin kaydı iptal edildi.')),
      );
      await _load();
    } on StaffLeaveRecordRepositoryException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('İzin kaydı iptal edilemedi. Lütfen tekrar deneyin.'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('İzin kaydı iptal edilemedi. Lütfen tekrar deneyin.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canEdit = AuthSession.canEditClinicProfile;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final filtered = _filteredRecords;

    return SettingsSubpageScaffold(
      title: 'Personel izinleri',
      icon: Icons.beach_access_outlined,
      fallbackRoute: SettingsCategories.hubPath,
      children: [
        TextButton.icon(
          onPressed: () => context.go('/clinic-workflow'),
          icon: const Icon(Icons.arrow_back, size: 18),
          label: const Text('Klinik İşleyiş\'e dön'),
        ),
        ClinicalNotice(
          tone: ClinicalNoticeTone.info,
          dense: true,
          message: canEdit
              ? 'Aktif izin kayıtları çakışan randevu saatlerini kapatır. Tüm kliniği kapalı göstermek için Klinik İşleyiş → Kapalı tarihler alanını kullanın.'
              : 'Bu kayıtları görüntüleme modundasınız. Düzenleme yalnızca doktor hesabı ile yapılabilir.',
        ),
        if (_loadError != null) ...[
          ClinicalNotice(
            tone: ClinicalNoticeTone.danger,
            dense: true,
            message: _loadError!,
            actions: [
              ClinicalNoticeAction(
                label: 'Yeniden dene',
                onPressed: _load,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            ChoiceChip(
              label: const Text('Tümü'),
              selected: _filter == _StaffLeaveListFilter.all,
              onSelected: _loading
                  ? null
                  : (_) => setState(() => _filter = _StaffLeaveListFilter.all),
            ),
            ChoiceChip(
              label: const Text('Aktif'),
              selected: _filter == _StaffLeaveListFilter.active,
              onSelected: _loading
                  ? null
                  : (_) =>
                      setState(() => _filter = _StaffLeaveListFilter.active),
            ),
            ChoiceChip(
              label: const Text('İptal edilmiş'),
              selected: _filter == _StaffLeaveListFilter.cancelled,
              onSelected: _loading
                  ? null
                  : (_) => setState(
                        () => _filter = _StaffLeaveListFilter.cancelled,
                      ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (_loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: CircularProgressIndicator(),
            ),
          )
        else if (filtered.isEmpty)
          SettingsSectionCard(
            title: 'Kayıt yok',
            children: [
              Text(
                _filter == _StaffLeaveListFilter.all
                    ? 'Henüz personel izin kaydı bulunmuyor.'
                    : 'Bu filtre için kayıt bulunamadı.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: muted,
                    ),
              ),
            ],
          )
        else
          ...filtered.map((r) => _LeaveRecordCard(
                record: r,
                canEdit: canEdit,
                formatRange:
                    '${_formatDateTime(r.startsAt)} – ${_formatDateTime(r.endsAt)}',
                onEdit: () => _openForm(existing: r),
                onCancel: () => _confirmCancel(r),
              )),
        if (canEdit) ...[
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: _busy ? null : () => _openForm(),
            icon: const Icon(Icons.add),
            label: const Text('İzin ekle'),
          ),
        ],
        if (_busy)
          const Padding(
            padding: EdgeInsets.only(top: AppSpacing.sm),
            child: LinearProgressIndicator(),
          ),
      ],
    );
  }
}

class _LeaveRecordCard extends StatelessWidget {
  final StaffLeaveRecord record;
  final bool canEdit;
  final String formatRange;
  final VoidCallback onEdit;
  final VoidCallback onCancel;

  const _LeaveRecordCard({
    required this.record,
    required this.canEdit,
    required this.formatRange,
    required this.onEdit,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final isCancelled = !record.isActive;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: SettingsSectionCard(
        title: record.staffDisplayName,
        icon: Icons.person_outline,
        children: [
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              Chip(
                label: Text(record.leaveType.label),
                visualDensity: VisualDensity.compact,
              ),
              Chip(
                label: Text(record.status.label),
                backgroundColor: isCancelled
                    ? Theme.of(context).colorScheme.errorContainer
                    : AppColors.primaryDeepTeal.withValues(alpha: 0.12),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          if (record.roleLabel != null && record.roleLabel!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              record.roleLabel!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: muted),
            ),
          ],
          const SizedBox(height: AppSpacing.xs),
          Text(formatRange),
          if (record.note != null && record.note!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              record.note!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: muted),
            ),
          ],
          if (canEdit && record.isActive) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Düzenle'),
                ),
                TextButton.icon(
                  onPressed: onCancel,
                  icon: const Icon(Icons.cancel_outlined, size: 18),
                  label: const Text('İzin kaydını iptal et'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StaffLeaveFormDialog extends StatefulWidget {
  final StaffLeaveRecord? existing;

  const _StaffLeaveFormDialog({this.existing});

  @override
  State<_StaffLeaveFormDialog> createState() => _StaffLeaveFormDialogState();
}

class _StaffLeaveFormDialogState extends State<_StaffLeaveFormDialog> {
  final _nameController = TextEditingController();
  final _roleController = TextEditingController();
  final _noteController = TextEditingController();
  StaffLeaveType _leaveType = StaffLeaveType.annual;
  late DateTime _startsAt;
  late DateTime _endsAt;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _nameController.text = e.staffDisplayName;
      _roleController.text = e.roleLabel ?? '';
      _noteController.text = e.note ?? '';
      _leaveType = e.leaveType;
      _startsAt = e.startsAt;
      _endsAt = e.endsAt;
    } else {
      final now = DateTime.now();
      _startsAt = DateTime(now.year, now.month, now.day, 9, 0);
      _endsAt = DateTime(now.year, now.month, now.day, 18, 0);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _roleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<DateTime?> _pickDateTime(DateTime initial) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(initial.year - 1),
      lastDate: DateTime(initial.year + 5),
    );
    if (date == null || !mounted) return null;

    final time = await showAppTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  void _submit() {
    final draft = StaffLeaveDraft(
      staffDisplayName: _nameController.text,
      roleLabel: _roleController.text.trim().isEmpty
          ? null
          : _roleController.text.trim(),
      leaveType: _leaveType,
      startsAt: _startsAt,
      endsAt: _endsAt,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
    );
    try {
      StaffLeaveRecordMapper.validateDraft(draft);
      Navigator.pop(context, draft);
    } on StaffLeaveRecordValidationException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'İzin ekle' : 'İzin düzenle'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Personel adı *',
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _roleController,
                decoration: const InputDecoration(
                  labelText: 'Rol etiketi (opsiyonel)',
                  hintText: 'Örn. Doktor, Asistan',
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<StaffLeaveType>(
                value: _leaveType,
                decoration: const InputDecoration(labelText: 'İzin tipi'),
                items: StaffLeaveType.values
                    .map(
                      (t) => DropdownMenuItem(
                        value: t,
                        child: Text(t.label),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _leaveType = v);
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Başlangıç'),
                subtitle: Text(_formatShort(_startsAt)),
                trailing: const Icon(Icons.calendar_today_outlined),
                onTap: () async {
                  final picked = await _pickDateTime(_startsAt);
                  if (picked != null) setState(() => _startsAt = picked);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Bitiş'),
                subtitle: Text(_formatShort(_endsAt)),
                trailing: const Icon(Icons.calendar_today_outlined),
                onTap: () async {
                  final picked = await _pickDateTime(_endsAt);
                  if (picked != null) setState(() => _endsAt = picked);
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Not (opsiyonel, en fazla 500 karakter)',
                ),
                maxLines: 3,
                maxLength: 500,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Vazgeç'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Kaydet'),
        ),
      ],
    );
  }

  String _formatShort(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day}.${dt.month}.${dt.year} $h:$m';
  }
}
