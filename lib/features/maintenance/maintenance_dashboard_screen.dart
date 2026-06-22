import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_session.dart';
import '../../core/config/app_env_config.dart';
import '../../core/session/active_tenant_context_store.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/clinical_state_message.dart';
import 'data/maintenance_models.dart';
import 'data/maintenance_repository.dart';
import 'widgets/maintenance_gate.dart';
import 'widgets/maintenance_scaffold.dart';

class MaintenanceDashboardScreen extends StatefulWidget {
  const MaintenanceDashboardScreen({super.key});

  @override
  State<MaintenanceDashboardScreen> createState() =>
      _MaintenanceDashboardScreenState();
}

class _MaintenanceDashboardScreenState extends State<MaintenanceDashboardScreen> {
  late Future<({List<MaintenanceAuditEventRow> audits, MaintenanceBootstrapChain? chain})> _load;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    final repo = MaintenanceRepository.fromSupabase();
    _load = () async {
      final audits = await repo.listAuditEvents(limit: 10);
      MaintenanceBootstrapChain? chain;
      final email = AuthSession.currentUser?.username;
      if (email != null && email.contains('@')) {
        chain = await repo.getBootstrapChain(email: email);
      }
      return (audits: audits, chain: chain);
    }();
  }

  @override
  Widget build(BuildContext context) {
    return MaintenanceGate(
      child: MaintenanceScaffold(
        title: 'Bakım Konsolu',
        child: FutureBuilder(
          future: _load,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return ClinicalStateMessage.loading(message: 'Yükleniyor…');
            }
            if (snapshot.hasError) {
              return ClinicalStateMessage.empty(
                icon: Icons.error_outline,
                title: 'Yüklenemedi',
                description: 'Bakım verileri alınamadı.',
              );
            }
            final data = snapshot.data!;
            return ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                _OperatorCard(chain: data.chain),
                const SizedBox(height: AppSpacing.md),
                _QuickLinks(),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Son bakım kayıtları',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                if (data.audits.isEmpty)
                  const Text('Henüz bakım audit kaydı yok.')
                else
                  ...data.audits.map(_AuditTile.new),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _OperatorCard extends StatelessWidget {
  final MaintenanceBootstrapChain? chain;

  const _OperatorCard({this.chain});

  @override
  Widget build(BuildContext context) {
    final user = AuthSession.currentUser;
    final localTenant = ActiveTenantContextStore.current?.tenantId;
    final serverTenant = chain?.resolvedActiveTenantId;
    final mismatch = localTenant != null &&
        serverTenant != null &&
        localTenant != serverTenant;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Operatör', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(user?.displayName ?? '—'),
            Text(user?.username ?? '—', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Ortam: ${AppEnvConfig.environment.name}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (chain != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                chain!.chainOk
                    ? 'Bootstrap zinciri: Tamam'
                    : 'Bootstrap zinciri: Eksik / hatalı',
                style: TextStyle(
                  color: chain!.chainOk ? Colors.green.shade700 : Colors.orange.shade800,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if (mismatch) ...[
              const SizedBox(height: AppSpacing.sm),
              Material(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.all(AppSpacing.sm),
                  child: Text(
                    'Aktif klinik bağlamı ile sunucu üyelik bilgisi uyumsuz görünüyor.',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuickLinks extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        FilledButton.tonal(
          onPressed: () => context.push('/maintenance/diagnostics'),
          child: const Text('Bootstrap tanı'),
        ),
        FilledButton.tonal(
          onPressed: () => context.push('/maintenance/auth-profile'),
          child: const Text('Auth / Profil'),
        ),
        FilledButton.tonal(
          onPressed: () => context.push('/maintenance/tenants'),
          child: const Text('Klinikler'),
        ),
        FilledButton.tonal(
          onPressed: () => context.push('/maintenance/memberships'),
          child: const Text('Üyelikler'),
        ),
      ],
    );
  }
}

class _AuditTile extends StatelessWidget {
  final MaintenanceAuditEventRow event;

  const _AuditTile(this.event);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      title: Text(event.action),
      subtitle: Text(
        [
          if (event.createdAt != null) event.createdAt.toString(),
          if (event.recordId != null) 'kayıt: ${event.recordId}',
        ].join(' · '),
      ),
    );
  }
}
