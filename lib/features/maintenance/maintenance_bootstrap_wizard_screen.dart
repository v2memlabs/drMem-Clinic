import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/login_username_generator.dart';
import '../../core/theme/app_spacing.dart';
import 'data/maintenance_models.dart';
import 'data/maintenance_provision_errors.dart';
import 'data/maintenance_provision_models.dart';
import 'data/maintenance_repository.dart';
import 'widgets/maintenance_copy_id.dart';
import 'widgets/maintenance_gate.dart';
import 'widgets/maintenance_role_labels.dart';
import 'widgets/maintenance_scaffold.dart';

typedef MaintenanceProvisionFn = Future<MaintenanceUserProvisionResult> Function(
  MaintenanceInitialAdminRequest request,
);

typedef MaintenanceBootstrapStatusFn = Future<MaintenanceBootstrapStatus> Function({
  required String tenantId,
  String? profileId,
  String? authUserId,
});

typedef MaintenanceListTenantsFn = Future<List<MaintenanceTenantRow>> Function();

/// Mevcut tenant için ilk doctor_admin bootstrap (v2a-2).
class MaintenanceBootstrapWizardScreen extends StatefulWidget {
  final String? initialTenantId;
  final String? initialTenantName;

  const MaintenanceBootstrapWizardScreen({
    super.key,
    this.initialTenantId,
    this.initialTenantName,
    this.bypassGateForTesting = false,
    this.provisionOverride,
    this.bootstrapStatusOverride,
    this.listTenantsOverride,
  });

  @visibleForTesting
  final bool bypassGateForTesting;

  @visibleForTesting
  final MaintenanceProvisionFn? provisionOverride;

  @visibleForTesting
  final MaintenanceBootstrapStatusFn? bootstrapStatusOverride;

  @visibleForTesting
  final MaintenanceListTenantsFn? listTenantsOverride;

  @override
  State<MaintenanceBootstrapWizardScreen> createState() =>
      _MaintenanceBootstrapWizardScreenState();
}

class _MaintenanceBootstrapWizardScreenState
    extends State<MaintenanceBootstrapWizardScreen> {
  /// 0 tenant select, 1 admin form, 2 loading, 3 success
  late int _step;
  bool _busy = false;
  String? _errorMessage;

  final _emailCtrl = TextEditingController();
  final _displayNameCtrl = TextEditingController();
  final _loginUsernameCtrl = TextEditingController();
  bool _loginUsernameTouched = false;

  String? _tenantId;
  String? _tenantName;
  List<MaintenanceTenantRow> _eligibleTenants = [];
  MaintenanceUserProvisionResult? _provisionResult;
  MaintenanceBootstrapStatus? _bootstrapStatus;

  @override
  void initState() {
    super.initState();
    _displayNameCtrl.addListener(_maybeSuggestLoginUsername);
    if (widget.initialTenantId != null) {
      _tenantId = widget.initialTenantId;
      _tenantName = widget.initialTenantName;
      _step = 1;
    } else {
      _step = 0;
      _loadTenants();
    }
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

  Future<void> _loadTenants() async {
    setState(() => _busy = true);
    try {
      final list = widget.listTenantsOverride ??
          () => MaintenanceRepository.fromSupabase().listTenants();
      final tenants = await list();
      if (!mounted) return;
      setState(() {
        _eligibleTenants = tenants
            .where((t) => t.status == 'active' || t.status == 'trial')
            .toList();
        _busy = false;
        if (_eligibleTenants.isEmpty) {
          _errorMessage =
              'Aktif veya deneme durumunda klinik bulunamadı. Önce yeni klinik oluşturun.';
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _errorMessage = 'Klinik listesi yüklenemedi.';
      });
    }
  }

  void _selectTenant(MaintenanceTenantRow tenant) {
    setState(() {
      _tenantId = tenant.id;
      _tenantName = tenant.name;
      _step = 1;
      _errorMessage = null;
    });
  }

  Future<void> _provisionAdmin() async {
    final email = _emailCtrl.text.trim();
    final displayName = _displayNameCtrl.text.trim();
    final loginUsername =
        LoginUsernameGenerator.normalize(_loginUsernameCtrl.text.trim());
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMessage = 'Geçerli bir e-posta girin.');
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
    if (_tenantId == null) {
      setState(() => _errorMessage = 'Önce bir klinik seçin.');
      return;
    }

    setState(() {
      _busy = true;
      _errorMessage = null;
      _step = 2;
    });

    try {
      final provisionFn = widget.provisionOverride ??
          (req) =>
              MaintenanceRepository.fromSupabase().provisionInitialAdminV2(req);
      final statusFn = widget.bootstrapStatusOverride ??
          ({required tenantId, profileId, authUserId}) =>
              MaintenanceRepository.fromSupabase().getBootstrapStatusV2(
                tenantId: tenantId,
                profileId: profileId,
                authUserId: authUserId,
              );

      final provision = await provisionFn(
        MaintenanceInitialAdminRequest(
          email: email,
          displayName: displayName,
          loginUsername: loginUsername,
          tenantId: _tenantId!,
        ),
      );

      final status = await statusFn(
        tenantId: _tenantId!,
        profileId: provision.profileId,
        authUserId: provision.authUserId,
      );

      if (!mounted) return;
      setState(() {
        _provisionResult = provision;
        _bootstrapStatus = status;
        _step = 3;
        _busy = false;
      });
    } on MaintenanceProvisionException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _step = 1;
        _errorMessage =
            MaintenanceProvisionErrorMapper.userMessage(e.reason);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _step = 1;
        _errorMessage = 'Yönetici oluşturulamadı.';
      });
    }
  }

  void _finish() {
    context.go('/maintenance/tenants');
  }

  String _gapMessage(String? gapCode) {
    switch (gapCode) {
      case 'tenant_inactive':
        return 'Klinik aktif değil.';
      case 'auth_missing':
        return 'Auth hesabı eksik.';
      case 'profile_missing':
        return 'Profil eksik.';
      case 'auth_not_linked':
        return 'Auth bağlantısı eksik.';
      case 'membership_missing':
        return 'Klinik üyeliği eksik.';
      case 'membership_inactive':
        return 'Üyelik aktif değil.';
      case 'role_mismatch':
        return 'Rol uyumsuz.';
      default:
        return 'Bootstrap zinciri tamamlanamadı. Onarım v2c gerekli.';
    }
  }

  Widget _errorBanner() {
    if (_errorMessage == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: MaterialBanner(
        content: Text(_errorMessage!),
        leading: const Icon(Icons.error_outline),
        actions: [
          TextButton(
            onPressed: () => setState(() => _errorMessage = null),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  Widget _tenantSelectStep() {
    if (_busy && _eligibleTenants.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '1. Klinik seçimi',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.md),
        if (_eligibleTenants.isEmpty)
          const Text('Uygun klinik bulunamadı.')
        else
          ..._eligibleTenants.map(
            (t) => Card(
              child: ListTile(
                title: Text(t.name),
                subtitle: Text('${t.status} · ${t.specialty ?? "—"}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _selectTenant(t),
              ),
            ),
          ),
      ],
    );
  }

  Widget _adminStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.initialTenantId != null ? '1. İlk yönetici' : '2. İlk yönetici',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        if (_tenantName != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text('Klinik: $_tenantName'),
        ],
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _emailCtrl,
          decoration: const InputDecoration(labelText: 'E-posta *'),
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          enabled: !_busy,
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _displayNameCtrl,
          decoration: const InputDecoration(labelText: 'Görünen ad *'),
          textInputAction: TextInputAction.next,
          enabled: !_busy,
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _loginUsernameCtrl,
          decoration: const InputDecoration(
            labelText: 'Giriş kullanıcı adı *',
            helperText: 'Giriş ekranında kullanılacak tekil kullanıcı adı',
          ),
          autocorrect: false,
          textInputAction: TextInputAction.done,
          enabled: !_busy,
          onChanged: (_) => _loginUsernameTouched = true,
        ),
        const SizedBox(height: AppSpacing.sm),
        InputDecorator(
          decoration: const InputDecoration(labelText: 'Rol'),
          child: Text(
            MaintenanceRoleLabels.labelForDbRole('doctor_admin'),
          ),
        ),
        const InputDecorator(
          decoration: InputDecoration(labelText: 'Durum'),
          child: Text('Aktif'),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            if (widget.initialTenantId == null)
              TextButton(
                onPressed: _busy ? null : () => setState(() => _step = 0),
                child: const Text('Geri'),
              ),
            const Spacer(),
            FilledButton(
              onPressed: _busy ? null : _provisionAdmin,
              child: const Text('Oluştur ve doğrula'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _loadingStep() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(),
        SizedBox(height: AppSpacing.md),
        Text('Auth hesabı ve bootstrap zinciri oluşturuluyor…'),
      ],
    );
  }

  Widget _statusRow(String label, bool ok) {
    return ListTile(
      dense: true,
      leading: Icon(
        ok ? Icons.check_circle : Icons.cancel,
        color: ok ? Colors.green : Colors.red,
      ),
      title: Text(label),
      subtitle: Text(ok ? 'Hazır' : 'Eksik'),
    );
  }

  Widget _successStep() {
    final status = _bootstrapStatus;
    final provision = _provisionResult;
    final chainOk = status?.chainOk == true;
    final credentialsEmailed =
        provision?.operationResult == 'created' && chainOk;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.initialTenantId != null ? '2. Doğrulama' : '3. Doğrulama',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.sm),
        Card(
          child: Column(
            children: [
              _statusRow('Auth kullanıcı', status?.authExists == true),
              _statusRow('Profil', status?.profileExists == true),
              _statusRow('Auth bağlantısı', status?.authLinked == true),
              _statusRow('Klinik üyeliği', status?.membershipExists == true),
              _statusRow(
                'Rol',
                status?.role == 'doctor_admin',
              ),
              _statusRow('Tenant', status?.tenantActive == true),
              ListTile(
                dense: true,
                leading: Icon(
                  chainOk ? Icons.check_circle : Icons.warning_amber,
                  color: chainOk ? Colors.green : Colors.orange,
                ),
                title: const Text('Login zinciri'),
                subtitle: Text(
                  chainOk ? 'Hazır' : _gapMessage(status?.gapCode),
                ),
              ),
            ],
          ),
        ),
        if (provision != null) ...[
          ExpansionTile(
            title: const Text('Teknik ayrıntılar'),
            children: [
              if (_tenantId != null)
                MaintenanceCopyId(label: 'tenant_id', value: _tenantId!),
              if (provision.profileId != null)
                MaintenanceCopyId(
                  label: 'profile_id',
                  value: provision.profileId!,
                ),
              if (provision.authUserId != null)
                MaintenanceCopyId(
                  label: 'auth_user_id',
                  value: provision.authUserId!,
                ),
              if (provision.membershipId != null)
                MaintenanceCopyId(
                  label: 'membership_id',
                  value: provision.membershipId!,
                ),
            ],
          ),
        ],
        if (provision?.loginUsername?.isNotEmpty == true) ...[
          const SizedBox(height: AppSpacing.md),
          ListTile(
            title: const Text('Giriş kullanıcı adı'),
            subtitle: Text(provision!.loginUsername!),
          ),
        ],
        if (credentialsEmailed) ...[
          const SizedBox(height: AppSpacing.md),
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Giriş bilgileri e-posta ile gönderildi',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Geçici parola yalnızca e-postada iletilir; uygulama veya API yanıtında gösterilmez.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        FilledButton(
          onPressed: _finish,
          child: const Text('Klinikler listesine dön'),
        ),
      ],
    );
  }

  Widget _body() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _errorBanner(),
          if (_step == 0) _tenantSelectStep(),
          if (_step == 1) _adminStep(),
          if (_step == 2) _loadingStep(),
          if (_step == 3) _successStep(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scaffold = MaintenanceScaffold(
      title: 'İlk Yönetici Bootstrap',
      child: _body(),
    );
    if (widget.bypassGateForTesting) return scaffold;
    return MaintenanceGate(child: scaffold);
  }
}
