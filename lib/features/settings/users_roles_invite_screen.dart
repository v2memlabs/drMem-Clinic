import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/login_username_generator.dart';
import '../../core/auth/tenant_role_mapper.dart';
import '../../core/theme/app_spacing.dart';
import 'data/tenant_invite_failure.dart';
import 'data/tenant_invite_models.dart';
import 'data/tenant_invite_repository.dart';
import 'data/tenant_invite_repository_provider.dart';
import 'settings_product_labels.dart';
import 'settings_subpage_scaffold.dart';
import 'settings_widgets.dart';

class UsersRolesInviteScreen extends StatefulWidget {
  const UsersRolesInviteScreen({super.key});

  @override
  State<UsersRolesInviteScreen> createState() => _UsersRolesInviteScreenState();
}

class _UsersRolesInviteScreenState extends State<UsersRolesInviteScreen> {
  final _emailCtrl = TextEditingController();
  final _displayNameCtrl = TextEditingController();
  final _loginUsernameCtrl = TextEditingController();
  String _role = TenantRoleMapper.dbAssistantSecretary;
  bool _submitting = false;
  bool _loginUsernameTouched = false;
  String? _errorMessage;

  static const _roles = [
    TenantRoleMapper.dbDoctorAdmin,
    TenantRoleMapper.dbAssistantSecretary,
    TenantRoleMapper.dbPhysiotherapist,
    TenantRoleMapper.dbNurse,
  ];

  @override
  void initState() {
    super.initState();
    _displayNameCtrl.addListener(_maybeSuggestLoginUsername);
  }

  @override
  void dispose() {
    _displayNameCtrl.removeListener(_maybeSuggestLoginUsername);
    _emailCtrl.dispose();
    _displayNameCtrl.dispose();
    _loginUsernameCtrl.dispose();
    super.dispose();
  }

  void _maybeSuggestLoginUsername() {
    if (_loginUsernameTouched) return;
    final suggested =
        LoginUsernameGenerator.suggestFromDisplayName(_displayNameCtrl.text);
    if (suggested.isNotEmpty) {
      _loginUsernameCtrl.text = suggested;
    }
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final displayName = _displayNameCtrl.text.trim();
    final loginUsername =
        LoginUsernameGenerator.normalize(_loginUsernameCtrl.text.trim());

    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMessage = 'Geçerli bir e-posta adresi girin.');
      return;
    }
    if (displayName.isEmpty) {
      setState(() => _errorMessage = 'Görünen ad zorunludur.');
      return;
    }
    if (!LoginUsernameGenerator.isValid(loginUsername)) {
      setState(() => _errorMessage =
          'Giriş kullanıcı adı 3–32 karakter olmalı (a-z, 0-9, . _)');
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      await TenantInviteRepositoryProvider.repository.inviteUser(
        TenantInviteRequest(
          email: email,
          displayName: displayName,
          loginUsername: loginUsername,
          role: _role,
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Davet gönderildi.')),
      );
      context.pop(true);
    } on TenantInviteRepositoryException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _submitting = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Davet gönderilemedi. Lütfen tekrar deneyin.';
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return SettingsSubpageScaffold(
      title: 'Kullanıcı Davet Et',
      icon: Icons.person_add_outlined,
      children: [
        const SettingsShellNote(
          message:
              'Davet e-postasında giriş kullanıcı adı yer alır. Kullanıcı şifresini '
              'belirledikten sonra kullanıcı adı ve şifre bilgilendirme e-postası gönderilir.',
        ),
        SettingsSectionCard(
          title: 'Davet bilgileri',
          children: [
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(
                labelText: 'E-posta',
              ),
              enabled: !_submitting,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _displayNameCtrl,
              decoration: const InputDecoration(
                labelText: 'Görünen ad',
              ),
              enabled: !_submitting,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _loginUsernameCtrl,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Giriş kullanıcı adı',
                hintText: 'ör. myalcinozan',
                helperText: 'Giriş ekranında kullanılacak kısa ad',
              ),
              enabled: !_submitting,
              onChanged: (_) => _loginUsernameTouched = true,
            ),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<String>(
              value: _role,
              decoration: const InputDecoration(labelText: 'Rol'),
              items: _roles
                  .map(
                    (role) => DropdownMenuItem(
                      value: role,
                      child: Text(SettingsProductLabels.roleLabel(role)),
                    ),
                  )
                  .toList(),
              onChanged: _submitting
                  ? null
                  : (value) {
                      if (value != null) setState(() => _role = value);
                    },
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                _errorMessage!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Davet gönder'),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Davet e-postası gönderildikten sonra kullanıcı listesinde '
              '“Davetli” olarak görünür.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: muted),
            ),
          ],
        ),
      ],
    );
  }
}
