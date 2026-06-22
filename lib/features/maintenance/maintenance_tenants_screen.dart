import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_spacing.dart';
import 'data/maintenance_models.dart';
import 'data/maintenance_repository.dart';
import 'widgets/maintenance_copy_id.dart';
import 'widgets/maintenance_gate.dart';
import 'widgets/maintenance_scaffold.dart';

class MaintenanceTenantsScreen extends StatefulWidget {
  const MaintenanceTenantsScreen({super.key});

  @override
  State<MaintenanceTenantsScreen> createState() => _MaintenanceTenantsScreenState();
}

class _MaintenanceTenantsScreenState extends State<MaintenanceTenantsScreen> {
  late Future<List<MaintenanceTenantRow>> _future;

  static const _statuses = ['active', 'suspended', 'trial'];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = MaintenanceRepository.fromSupabase().listTenants();
  }

  Future<void> _updateStatus(MaintenanceTenantRow tenant, String status) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Klinik durumu'),
        content: Text('${tenant.name} → $status olarak güncellensin mi?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Kaydet')),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await MaintenanceRepository.fromSupabase().updateTenantStatus(
        tenantId: tenant.id,
        status: status,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Klinik durumu güncellendi.')),
      );
      setState(_reload);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Güncellenemedi.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaintenanceGate(
      child: MaintenanceScaffold(
        title: 'Klinikler',
        actions: [
          IconButton(
            icon: const Icon(Icons.add_business_outlined),
            tooltip: 'Yeni Klinik',
            onPressed: () => context.push('/maintenance/tenants/new'),
          ),
        ],
        child: FutureBuilder<List<MaintenanceTenantRow>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return const Center(child: Text('Klinik listesi yüklenemedi.'));
            }
            final tenants = snapshot.data!;
            return ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: tenants.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, i) {
                final t = tenants[i];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(t.name, style: Theme.of(context).textTheme.titleMedium),
                        if (t.specialty != null) Text(t.specialty!),
                        Text('Durum: ${t.status} · ${t.timezone}'),
                        MaintenanceCopyId(label: 'tenant_id', value: t.id),
                        if (t.status == 'active' || t.status == 'trial') ...[
                          const SizedBox(height: AppSpacing.sm),
                          OutlinedButton.icon(
                            onPressed: () {
                              final name = Uri.encodeComponent(t.name);
                              context.push(
                                '/maintenance/bootstrap/new?tenantId=${t.id}&tenantName=$name',
                              );
                            },
                            icon: const Icon(Icons.person_add_outlined),
                            label: const Text('İlk yönetici ekle'),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.sm),
                        OutlinedButton.icon(
                          onPressed: () {
                            final name = Uri.encodeComponent(t.name);
                            context.push(
                              '/maintenance/tenants/${t.id}/role-access?tenantName=$name',
                            );
                          },
                          icon: const Icon(Icons.admin_panel_settings_outlined),
                          label: const Text('Rol erişimleri'),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        OutlinedButton.icon(
                          onPressed: () {
                            final name = Uri.encodeComponent(t.name);
                            context.push(
                              '/maintenance/tenants/${t.id}/financial?tenantName=$name',
                            );
                          },
                          icon: const Icon(Icons.payments_outlined),
                          label: const Text('Finansal özellikler'),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        DropdownButtonFormField<String>(
                          value: t.status,
                          decoration: const InputDecoration(labelText: 'Durum güncelle'),
                          items: _statuses
                              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                              .toList(),
                          onChanged: (v) {
                            if (v != null) _updateStatus(t, v);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
