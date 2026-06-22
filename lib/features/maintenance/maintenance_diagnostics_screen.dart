import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/session/active_tenant_context_store.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/clinical_state_message.dart';
import 'data/maintenance_models.dart';
import 'data/maintenance_repository.dart';
import 'widgets/maintenance_copy_id.dart';
import 'widgets/maintenance_gate.dart';
import 'widgets/maintenance_role_labels.dart';
import 'widgets/maintenance_scaffold.dart';

class MaintenanceDiagnosticsScreen extends StatefulWidget {
  const MaintenanceDiagnosticsScreen({super.key});

  @override
  State<MaintenanceDiagnosticsScreen> createState() =>
      _MaintenanceDiagnosticsScreenState();
}

class _MaintenanceDiagnosticsScreenState extends State<MaintenanceDiagnosticsScreen> {
  final _emailCtrl = TextEditingController();
  final _profileCtrl = TextEditingController();
  final _authCtrl = TextEditingController();
  MaintenanceBootstrapChain? _chain;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _profileCtrl.dispose();
    _authCtrl.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final chain = await MaintenanceRepository.fromSupabase().getBootstrapChain(
        email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        profileId: _profileCtrl.text.trim().isEmpty ? null : _profileCtrl.text.trim(),
        authUserId: _authCtrl.text.trim().isEmpty ? null : _authCtrl.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _chain = chain;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Tanı çalıştırılamadı.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final localTenant = ActiveTenantContextStore.current?.tenantId;

    return MaintenanceGate(
      child: MaintenanceScaffold(
        title: 'Bootstrap Tanı',
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            TextField(
              controller: _emailCtrl,
              decoration: const InputDecoration(labelText: 'E-posta'),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _profileCtrl,
              decoration: const InputDecoration(labelText: 'Profile ID (opsiyonel)'),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _authCtrl,
              decoration: const InputDecoration(labelText: 'Auth user ID (opsiyonel)'),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: _loading ? null : _run,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Zinciri çalıştır'),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            if (_chain != null) ...[
              const SizedBox(height: AppSpacing.lg),
              _ChainCard(chain: _chain!, localTenantId: localTenant),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                children: [
                  OutlinedButton(
                    onPressed: () => context.push('/maintenance/auth-profile'),
                    child: const Text('Auth bağla'),
                  ),
                  OutlinedButton(
                    onPressed: () => context.push('/maintenance/memberships/new'),
                    child: const Text('Üyelik oluştur'),
                  ),
                  OutlinedButton(
                    onPressed: () => context.push('/maintenance/memberships'),
                    child: const Text('Üyelikleri düzenle'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChainCard extends StatelessWidget {
  final MaintenanceBootstrapChain chain;
  final String? localTenantId;

  const _ChainCard({required this.chain, this.localTenantId});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _StatusRow(
              label: 'Auth kullanıcı',
              ok: chain.authUserId != null && chain.authUserExists,
            ),
            if (chain.authUserId != null)
              MaintenanceCopyId(label: 'auth_user_id', value: chain.authUserId!),
            const Divider(),
            _StatusRow(label: 'Profil', ok: chain.profile != null),
            if (chain.profile != null) ...[
              MaintenanceCopyId(label: 'profile_id', value: chain.profile!.id),
              Text(
                'Auth bağlı: ${chain.profile!.hasAuthLink ? "Evet" : "Hayır"}',
              ),
            ],
            const Divider(),
            _StatusRow(
              label: 'Aktif üyelik',
              ok: chain.memberships.any(
                (m) => m.membershipStatus == 'active' && m.tenantStatus == 'active',
              ),
            ),
            ...chain.memberships.map(
              (m) => ListTile(
                dense: true,
                title: Text('${m.tenantName} · ${MaintenanceRoleLabels.labelForDbRole(m.role)}'),
                subtitle: Text(
                  'Üyelik: ${m.membershipStatus} · Klinik: ${m.tenantStatus}',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => context.push('/maintenance/memberships/${m.membershipId}'),
                ),
              ),
            ),
            const Divider(),
            if (chain.resolvedActiveTenantId != null)
              MaintenanceCopyId(
                label: 'Sunucu active tenant',
                value: chain.resolvedActiveTenantId!,
              ),
            if (localTenantId != null)
              MaintenanceCopyId(label: 'İstemci active tenant', value: localTenantId!),
            if (localTenantId != null &&
                chain.resolvedActiveTenantId != null &&
                localTenantId != chain.resolvedActiveTenantId)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: ClinicalStateMessage.empty(
                  icon: Icons.warning_amber_outlined,
                  title: 'Bağlam uyumsuzluğu',
                  description:
                      'Aktif klinik bağlamı ile sunucu üyelik bilgisi uyumsuz görünüyor.',
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String label;
  final bool ok;

  const _StatusRow({required this.label, required this.ok});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(ok ? Icons.check_circle : Icons.cancel, color: ok ? Colors.green : Colors.red),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(label, style: Theme.of(context).textTheme.titleSmall)),
      ],
    );
  }
}
