import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_session.dart';
import '../../core/auth/login_username_generator.dart';
import '../../core/auth/tenant_role_mapper.dart';
import '../../core/session/active_tenant_context_store.dart';
import '../../core/theme/app_spacing.dart';
import 'data/tenant_invite_failure.dart';
import 'data/tenant_invite_repository_provider.dart';
import 'models/tenant_membership_user.dart';
import 'data/tenant_membership_repository.dart';
import 'data/tenant_membership_repository_provider.dart';
import 'settings_product_labels.dart';
import 'settings_subpage_scaffold.dart';
import 'settings_widgets.dart';

class UsersRolesSettingsScreen extends StatefulWidget {
  const UsersRolesSettingsScreen({super.key});

  @override
  State<UsersRolesSettingsScreen> createState() =>
      _UsersRolesSettingsScreenState();
}

class _UsersRolesSettingsScreenState extends State<UsersRolesSettingsScreen> {
  List<TenantMembershipUser>? _members;
  bool _loading = true;
  bool _saving = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!AuthSession.canEditClinicProfile) return;
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final members =
          await TenantMembershipRepositoryProvider.repository.listCurrentTenantMembers();
      if (!mounted) return;
      setState(() {
        _members = members;
        _loading = false;
      });
    } on TenantMembershipRepositoryException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadError = 'Kullanıcı bilgileri yüklenemedi. Lütfen tekrar deneyin.';
        _loading = false;
      });
    }
  }

  String? get _currentMembershipId =>
      ActiveTenantContextStore.current?.membership.id;

  int get _activeDoctorCount =>
      _members?.where((m) => m.isActiveDoctorAdmin).length ?? 0;

  bool _isSelf(TenantMembershipUser member) =>
      member.membershipId == _currentMembershipId;

  bool _isLastActiveDoctor(TenantMembershipUser member) =>
      member.isActiveDoctorAdmin && _activeDoctorCount <= 1;

  bool _canEditMember(TenantMembershipUser member) {
    if (_saving) return false;
    if (_isSelf(member)) return false;
    if (_isLastActiveDoctor(member)) return false;
    return true;
  }

  Future<void> _editLoginUsername(TenantMembershipUser member) async {
    if (!_canEditMember(member) || member.profileId.isEmpty) return;

    final updated = await showDialog<String>(
      context: context,
      builder: (ctx) => _LoginUsernameEditDialog(
        initialValue: member.loginUsername ?? '',
      ),
    );
    if (updated == null) return;

    final normalized = LoginUsernameGenerator.normalize(updated);
    if (!LoginUsernameGenerator.isValid(normalized)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kullanıcı adı 3–32 karakter olmalı (a-z, 0-9, . _)'),
        ),
      );
      return;
    }
    if (normalized == (member.loginUsername ?? '')) return;

    setState(() => _saving = true);
    try {
      await TenantMembershipRepositoryProvider.repository.updateLoginUsername(
        profileId: member.profileId,
        loginUsername: normalized,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Giriş kullanıcı adı güncellendi.')),
      );
      await _load();
    } on TenantMembershipRepositoryException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kullanıcı adı güncellenemedi. Lütfen tekrar deneyin.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _editRole(TenantMembershipUser member) async {
    if (!_canEditMember(member)) return;

    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => _RolePickerDialog(currentRole: member.role),
    );
    if (selected == null || selected == member.role) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rol değişikliği'),
        content: Text(
          '${member.displayName} kullanıcısının rolü '
          '${SettingsProductLabels.roleLabel(member.role)} → '
          '${SettingsProductLabels.roleLabel(selected)} olarak güncellensin mi?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _saving = true);
    try {
      await TenantMembershipRepositoryProvider.repository.updateRole(
        membershipId: member.membershipId,
        role: selected,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rol güncellendi.')),
      );
      await _load();
    } on TenantMembershipRepositoryException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rol güncellenemedi. Lütfen tekrar deneyin.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _openCreateUserForm() async {
    final created = await context.push<bool>('/settings/users-roles/invite');
    if (created == true && mounted) {
      await _load();
    }
  }

  Future<void> _editStatus(TenantMembershipUser member) async {
    if (!_canEditMember(member)) return;

    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => _StatusPickerDialog(
        currentStatus: member.status,
        hideActiveOption: member.status == 'invited',
      ),
    );
    if (selected == null || selected == member.status) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Durum değişikliği'),
        content: Text(
          '${member.displayName} kullanıcısının durumu '
          '${SettingsProductLabels.membershipStatusLabel(member.status)} → '
          '${SettingsProductLabels.membershipStatusLabel(selected)} olarak güncellensin mi?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _saving = true);
    try {
      await TenantMembershipRepositoryProvider.repository.updateStatus(
        membershipId: member.membershipId,
        status: selected,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Durum güncellendi.')),
      );
      await _load();
    } on TenantMembershipRepositoryException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Durum güncellenemedi. Lütfen tekrar deneyin.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return SettingsSubpageScaffold(
      title: 'Kullanıcılar ve Roller',
      icon: Icons.group_outlined,
      children: [
        SettingsSectionCard(
          title: 'Klinik kullanıcıları',
          children: [
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_loadError != null)
              Text(
                _loadError!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
              )
            else if (_members == null || _members!.isEmpty)
              Text(
                'Bu klinikte listelenecek kullanıcı bulunamadı.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: muted),
              )
            else
              ..._members!.map((member) => _MemberTile(
                    member: member,
                    muted: muted,
                    isSelf: _isSelf(member),
                    isLastDoctor: _isLastActiveDoctor(member),
                    canEdit: _canEditMember(member),
                    onEditRole: () => _editRole(member),
                    onEditLoginUsername: () => _editLoginUsername(member),
                    onEditStatus: () => _editStatus(member),
                  )),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton(
              onPressed: _loading || _saving ? null : _openCreateUserForm,
              child: const Text('Yeni kullanıcı'),
            ),
          ],
        ),
      ],
    );
  }
}

class _MemberTile extends StatelessWidget {
  final TenantMembershipUser member;
  final Color muted;
  final bool isSelf;
  final bool isLastDoctor;
  final bool canEdit;
  final VoidCallback onEditRole;
  final VoidCallback onEditLoginUsername;
  final VoidCallback onEditStatus;

  const _MemberTile({
    required this.member,
    required this.muted,
    required this.isSelf,
    required this.isLastDoctor,
    required this.canEdit,
    required this.onEditRole,
    required this.onEditLoginUsername,
    required this.onEditStatus,
  });

  @override
  Widget build(BuildContext context) {
    final email = member.email?.trim().isNotEmpty == true
        ? member.email!.trim()
        : '—';
    final loginUsername = member.loginUsername?.trim().isNotEmpty == true
        ? member.loginUsername!.trim()
        : '—';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                member.displayName,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 2),
              Text(
                email,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: muted),
              ),
              const SizedBox(height: AppSpacing.xs),
              SettingsReadOnlyRow(
                label: 'Giriş kullanıcı adı',
                value: loginUsername,
              ),
              SettingsReadOnlyRow(
                label: 'Rol',
                value: SettingsProductLabels.roleLabel(member.role),
              ),
              SettingsReadOnlyRow(
                label: 'Durum',
                value: SettingsProductLabels.membershipStatusLabel(member.status),
              ),
              if (isSelf) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Kendi rolünüz bu ekrandan değiştirilemez.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: muted),
                ),
              ]               else if (isLastDoctor) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Son aktif doktor/admin için rol/durum değişikliği kısıtlıdır.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: muted),
                ),
              ] else if (member.status == 'invited') ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Eski davet kaydı — kullanıcıyı yeniden oluşturun veya durumu güncelleyin.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: muted),
                ),
              ],
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  OutlinedButton(
                    onPressed: canEdit ? onEditLoginUsername : null,
                    child: const Text('Kullanıcı adı'),
                  ),
                  OutlinedButton(
                    onPressed: canEdit ? onEditRole : null,
                    child: const Text('Rolü düzenle'),
                  ),
                  OutlinedButton(
                    onPressed: canEdit ? onEditStatus : null,
                    child: const Text('Durumu düzenle'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RolePickerDialog extends StatelessWidget {
  final String currentRole;

  const _RolePickerDialog({required this.currentRole});

  static const _roles = [
    TenantRoleMapper.dbDoctorAdmin,
    TenantRoleMapper.dbAssistantSecretary,
    TenantRoleMapper.dbPhysiotherapist,
    TenantRoleMapper.dbNurse,
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rol seçin'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: _roles
            .map(
              (role) => RadioListTile<String>(
                value: role,
                groupValue: currentRole,
                onChanged: (value) => Navigator.pop(context, value),
                title: Text(SettingsProductLabels.roleLabel(role)),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            )
            .toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
      ],
    );
  }
}

class _LoginUsernameEditDialog extends StatefulWidget {
  const _LoginUsernameEditDialog({required this.initialValue});

  final String initialValue;

  @override
  State<_LoginUsernameEditDialog> createState() =>
      _LoginUsernameEditDialogState();
}

class _LoginUsernameEditDialogState extends State<_LoginUsernameEditDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Giriş kullanıcı adı'),
      content: TextField(
        controller: _controller,
        autocorrect: false,
        decoration: const InputDecoration(
          labelText: 'Kullanıcı adı',
          helperText: 'Eski kullanıcı adı anında geçersiz olur',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          child: const Text('Kaydet'),
        ),
      ],
    );
  }
}

class _StatusPickerDialog extends StatelessWidget {
  final String currentStatus;
  final bool hideActiveOption;

  const _StatusPickerDialog({
    required this.currentStatus,
    this.hideActiveOption = false,
  });

  static const _statuses = ['active', 'invited', 'disabled'];

  List<String> get _visibleStatuses {
    if (!hideActiveOption) return _statuses;
    return _statuses.where((s) => s != 'active').toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Durum seçin'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: _visibleStatuses
            .map(
              (status) => RadioListTile<String>(
                value: status,
                groupValue: currentStatus,
                onChanged: (value) => Navigator.pop(context, value),
                title: Text(SettingsProductLabels.membershipStatusLabel(status)),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            )
            .toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
      ],
    );
  }
}
