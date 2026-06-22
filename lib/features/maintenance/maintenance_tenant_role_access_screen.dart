import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_roles.dart';
import '../../core/theme/app_spacing.dart';
import '../settings/models/tenant_role_access_settings.dart';
import 'data/maintenance_repository.dart';
import 'widgets/maintenance_copy_id.dart';
import 'widgets/maintenance_gate.dart';
import 'widgets/maintenance_scaffold.dart';

class MaintenanceTenantRoleAccessScreen extends StatefulWidget {
  final String tenantId;
  final String tenantName;

  const MaintenanceTenantRoleAccessScreen({
    super.key,
    required this.tenantId,
    required this.tenantName,
  });

  @override
  State<MaintenanceTenantRoleAccessScreen> createState() =>
      _MaintenanceTenantRoleAccessScreenState();
}

class _MaintenanceTenantRoleAccessScreenState
    extends State<MaintenanceTenantRoleAccessScreen>
    with SingleTickerProviderStateMixin {
  TenantRoleAccessSettings? _draft;
  bool _loading = true;
  bool _saving = false;
  String? _loadError;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: TenantRoleAccessCatalog.roles.length,
      vsync: this,
    );
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final settings = await MaintenanceRepository.fromSupabase()
          .getTenantRoleAccessSettings(widget.tenantId);
      if (!mounted) return;
      setState(() {
        _draft = settings;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadError = 'Rol erişim ayarları yüklenemedi.';
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    final draft = _draft;
    if (draft == null || _saving) return;

    setState(() => _saving = true);
    try {
      await MaintenanceRepository.fromSupabase().updateTenantRoleAccessSettings(
        tenantId: widget.tenantId,
        settings: draft,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rol erişim ayarları kaydedildi.')),
      );
      await _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kaydedilemedi.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaintenanceGate(
      child: MaintenanceScaffold(
        title: 'Rol Erişimleri',
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _loadError != null
                ? Center(child: Text(_loadError!))
                : _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final settings = _draft ?? TenantRoleAccessSettings.empty();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.tenantName,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              MaintenanceCopyId(label: 'tenant_id', value: widget.tenantId),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Klinik personelinin modül erişimlerini rol bazında yönetin. '
                'Değişiklikler kullanıcılar yeniden giriş yaptığında veya oturum '
                'senkronu sonrası uygulanır.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
        TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            for (final role in TenantRoleAccessCatalog.roles)
              Tab(text: AppRoles.roleLabel(role)),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              for (final role in TenantRoleAccessCatalog.roles)
                _RoleAccessList(
                  role: role,
                  settings: settings,
                  saving: _saving,
                  onChanged: (key, enabled) {
                    setState(() {
                      _draft = settings.copyWithFlag(role, key, enabled);
                    });
                  },
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving ? null : () => context.pop(),
                  child: const Text('Geri'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Kaydet'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RoleAccessList extends StatelessWidget {
  final String role;
  final TenantRoleAccessSettings settings;
  final bool saving;
  final void Function(TenantRoleAccessKey key, bool enabled) onChanged;

  const _RoleAccessList({
    required this.role,
    required this.settings,
    required this.saving,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        for (final def in TenantRoleAccessCatalog.definitions)
          SwitchListTile(
            title: Text(def.label),
            subtitle: Text(def.description),
            value: settings.isAllowed(role, def.key),
            onChanged: saving ? null : (enabled) => onChanged(def.key, enabled),
          ),
      ],
    );
  }
}
