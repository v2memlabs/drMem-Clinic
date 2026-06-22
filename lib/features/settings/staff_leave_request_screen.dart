import 'package:flutter/material.dart';

import '../../core/auth/auth_session.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/app_time_picker.dart';
import '../../shared/layout/responsive_page_body.dart';
import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/clinical_notice.dart';
import '../../shared/widgets/clinical_notice_tone.dart';
import '../../shared/widgets/page_header.dart';
import 'data/staff_leave_record_mapper.dart';
import 'data/staff_leave_request_repository.dart';
import 'data/staff_leave_request_repository_provider.dart';
import 'models/staff_leave_record.dart';
import 'models/staff_leave_request.dart';
import 'settings_widgets.dart';

class StaffLeaveRequestScreen extends StatefulWidget {
  const StaffLeaveRequestScreen({super.key});

  @override
  State<StaffLeaveRequestScreen> createState() =>
      _StaffLeaveRequestScreenState();
}

class _StaffLeaveRequestScreenState extends State<StaffLeaveRequestScreen> {
  List<StaffLeaveRequest> _mine = [];
  List<StaffLeaveRequest> _pending = [];
  bool _loading = true;
  String? _loadError;
  bool _busy = false;

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
      final repo = StaffLeaveRequestRepositoryProvider.repository;
      final mine = await repo.listMine();
      final pending = AuthSession.canApproveStaffLeave
          ? await repo.listPending()
          : <StaffLeaveRequest>[];
      if (!mounted) return;
      setState(() {
        _mine = mine;
        _pending = pending;
        _loading = false;
      });
    } on StaffLeaveRequestRepositoryException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.message;
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

  String _formatDateTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day}.${dt.month}.${dt.year} $h:$m';
  }

  Future<void> _openCreateDialog() async {
    final draft = await showDialog<StaffLeaveRequestDraft>(
      context: context,
      builder: (context) => const _LeaveRequestFormDialog(),
    );
    if (draft == null || !mounted) return;

    setState(() => _busy = true);
    try {
      await StaffLeaveRequestRepositoryProvider.repository.create(draft);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('İzin talebiniz doktor onayına gönderildi.')),
      );
      await _load();
    } on StaffLeaveRecordValidationException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } on StaffLeaveRequestRepositoryException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('İzin talebi gönderilemedi.')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _approve(StaffLeaveRequest request) async {
    setState(() => _busy = true);
    try {
      await StaffLeaveRequestRepositoryProvider.repository.approve(request.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${request.staffDisplayName} izin talebi onaylandı.'),
        ),
      );
      await _load();
    } on StaffLeaveRequestRepositoryException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Onay işlemi tamamlanamadı.')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reject(StaffLeaveRequest request) async {
    final reasonController = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('İzin talebini reddet'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'Red gerekçesi (opsiyonel)',
            hintText: 'Personel için kısa açıklama',
          ),
          maxLines: 3,
          maxLength: 500,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
            ),
            child: const Text('Reddet'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) {
      reasonController.dispose();
      return;
    }

    final reason = reasonController.text.trim();
    reasonController.dispose();

    setState(() => _busy = true);
    try {
      await StaffLeaveRequestRepositoryProvider.repository.reject(
        request.id,
        reason: reason.isEmpty ? null : reason,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${request.staffDisplayName} izin talebi reddedildi.')),
      );
      await _load();
    } on StaffLeaveRequestRepositoryException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Red işlemi tamamlanamadı.')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final isDoctor = AuthSession.canApproveStaffLeave;

    return AppShell(
      title: 'İzin Talebi',
      child: ResponsiveDetailPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PageHeader(
              title: 'İzin Talebi',
              icon: Icons.event_busy_outlined,
              leadingBack: true,
              fallbackRoute: AuthSession.dashboardRoute,
            ),
            ClinicalNotice(
              tone: ClinicalNoticeTone.info,
              dense: true,
              message: isDoctor
                  ? 'Personel izin taleplerini buradan onaylayabilir veya reddedebilirsiniz. Onaylanan izinler sisteme işlenir.'
                  : 'İzin talebiniz doktor onayına gönderilir. Onaylandığında personel izin kayıtlarına işlenir.',
            ),
            if (_loadError != null) ...[
              const SizedBox(height: AppSpacing.sm),
              ClinicalNotice(
                tone: ClinicalNoticeTone.danger,
                dense: true,
                message: _loadError!,
                actions: [
                  ClinicalNoticeAction(label: 'Yeniden dene', onPressed: _load),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            FilledButton.icon(
              onPressed: _busy || _loading ? null : _openCreateDialog,
              icon: const Icon(Icons.add),
              label: const Text('Yeni izin talebi'),
            ),
            const SizedBox(height: AppSpacing.md),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else ...[
              if (isDoctor && _pending.isNotEmpty) ...[
                Text(
                  'Onay bekleyen talepler',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryDeepTeal,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                for (final request in _pending)
                  _PendingRequestCard(
                    request: request,
                    formatRange:
                        '${_formatDateTime(request.startsAt)} – ${_formatDateTime(request.endsAt)}',
                    busy: _busy,
                    onApprove: () => _approve(request),
                    onReject: () => _reject(request),
                  ),
                const SizedBox(height: AppSpacing.md),
              ],
              Text(
                isDoctor ? 'Tüm taleplerim' : 'Taleplerim',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (_mine.isEmpty)
                SettingsSectionCard(
                  title: 'Kayıt yok',
                  children: [
                    Text(
                      'Henüz izin talebiniz bulunmuyor.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: muted,
                          ),
                    ),
                  ],
                )
              else
                for (final request in _mine)
                  _MyRequestCard(
                    request: request,
                    formatRange:
                        '${_formatDateTime(request.startsAt)} – ${_formatDateTime(request.endsAt)}',
                  ),
            ],
            if (_busy)
              const Padding(
                padding: EdgeInsets.only(top: AppSpacing.sm),
                child: LinearProgressIndicator(),
              ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}

class _PendingRequestCard extends StatelessWidget {
  final StaffLeaveRequest request;
  final String formatRange;
  final bool busy;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _PendingRequestCard({
    required this.request,
    required this.formatRange,
    required this.busy,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: SettingsSectionCard(
        title: request.staffDisplayName,
        icon: Icons.pending_actions_outlined,
        children: [
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              Chip(
                label: Text(request.leaveType.label),
                visualDensity: VisualDensity.compact,
              ),
              if (request.roleLabel != null && request.roleLabel!.isNotEmpty)
                Chip(
                  label: Text(request.roleLabel!),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(formatRange),
          if (request.note != null && request.note!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              request.note!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: muted),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              FilledButton.icon(
                onPressed: busy ? null : onApprove,
                icon: const Icon(Icons.check, size: 18),
                label: const Text('Onayla'),
              ),
              const SizedBox(width: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: busy ? null : onReject,
                icon: const Icon(Icons.close, size: 18),
                label: const Text('Reddet'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MyRequestCard extends StatelessWidget {
  final StaffLeaveRequest request;
  final String formatRange;

  const _MyRequestCard({
    required this.request,
    required this.formatRange,
  });

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final statusColor = switch (request.status) {
      StaffLeaveRequestStatus.pending => AppColors.warning,
      StaffLeaveRequestStatus.approved => AppColors.primaryDeepTeal,
      StaffLeaveRequestStatus.rejected => AppColors.danger,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: SettingsSectionCard(
        title: request.leaveType.label,
        icon: Icons.event_note_outlined,
        children: [
          Chip(
            label: Text(request.status.label),
            backgroundColor: statusColor.withValues(alpha: 0.12),
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(formatRange),
          if (request.note != null && request.note!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              request.note!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: muted),
            ),
          ],
          if (request.rejectionReason != null &&
              request.rejectionReason!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Red gerekçesi: ${request.rejectionReason!}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.danger,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LeaveRequestFormDialog extends StatefulWidget {
  const _LeaveRequestFormDialog();

  @override
  State<_LeaveRequestFormDialog> createState() => _LeaveRequestFormDialogState();
}

class _LeaveRequestFormDialogState extends State<_LeaveRequestFormDialog> {
  final _noteController = TextEditingController();
  StaffLeaveType _leaveType = StaffLeaveType.annual;
  late DateTime _startsAt;
  late DateTime _endsAt;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startsAt = DateTime(now.year, now.month, now.day, 9, 0);
    _endsAt = DateTime(now.year, now.month, now.day, 18, 0);
  }

  @override
  void dispose() {
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
    final draft = StaffLeaveRequestDraft(
      leaveType: _leaveType,
      startsAt: _startsAt,
      endsAt: _endsAt,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
    );
    try {
      StaffLeaveRecordMapper.validateDraft(
        StaffLeaveDraft(
          staffDisplayName: 'x',
          leaveType: draft.leaveType,
          startsAt: draft.startsAt,
          endsAt: draft.endsAt,
          note: draft.note,
        ),
      );
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
      title: const Text('İzin talebi oluştur'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                  labelText: 'Not (opsiyonel)',
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
          child: const Text('Gönder'),
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
