import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_spacing.dart';
import 'data/maintenance_models.dart';
import 'data/maintenance_repository.dart';
import 'widgets/maintenance_copy_id.dart';
import 'widgets/maintenance_gate.dart';
import 'widgets/maintenance_role_labels.dart';
import 'widgets/maintenance_scaffold.dart';

class MaintenanceMembershipsScreen extends StatefulWidget {
  const MaintenanceMembershipsScreen({super.key});

  @override
  State<MaintenanceMembershipsScreen> createState() =>
      _MaintenanceMembershipsScreenState();
}

class _MaintenanceMembershipsScreenState extends State<MaintenanceMembershipsScreen> {
  late Future<List<MaintenanceMembershipRow>> _future;
  String? _tenantFilter;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = MaintenanceRepository.fromSupabase().listMemberships(
      tenantId: _tenantFilter,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaintenanceGate(
      child: MaintenanceScaffold(
        title: 'Üyelikler',
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Yeni üyelik',
            onPressed: () => context.push('/maintenance/memberships/new'),
          ),
        ],
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'Tenant ID filtresi (opsiyonel)',
                      ),
                      onSubmitted: (v) {
                        _tenantFilter = v.trim().isEmpty ? null : v.trim();
                        setState(_reload);
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () => setState(_reload),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<MaintenanceMembershipRow>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: Text('Üyelik listesi yüklenemedi.'));
                  }
                  final rows = snapshot.data!;
                  return ListView.builder(
                    itemCount: rows.length,
                    itemBuilder: (context, i) {
                      final m = rows[i];
                      return Card(
                        child: ListTile(
                          title: Text('${m.tenantName} · ${m.profileEmail ?? "—"}'),
                          subtitle: Text(
                            '${MaintenanceRoleLabels.labelForDbRole(m.role)} (${m.role}) · ${m.status}',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.push('/maintenance/memberships/${m.id}'),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MaintenanceMembershipFormScreen extends StatefulWidget {
  const MaintenanceMembershipFormScreen({super.key});

  @override
  State<MaintenanceMembershipFormScreen> createState() =>
      _MaintenanceMembershipFormScreenState();
}

class _MaintenanceMembershipFormScreenState extends State<MaintenanceMembershipFormScreen> {
  final _tenantCtrl = TextEditingController();
  final _profileCtrl = TextEditingController();
  String _role = MaintenanceRoleLabels.dbRoles.first;
  String _status = 'active';

  @override
  void dispose() {
    _tenantCtrl.dispose();
    _profileCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    try {
      final id = await MaintenanceRepository.fromSupabase().createMembership(
        tenantId: _tenantCtrl.text.trim(),
        profileId: _profileCtrl.text.trim(),
        role: _role,
        status: _status,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Üyelik oluşturuldu: $id')),
      );
      context.go('/maintenance/memberships/$id');
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Üyelik oluşturulamadı.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaintenanceGate(
      child: MaintenanceScaffold(
        title: 'Yeni üyelik',
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            TextField(
              controller: _tenantCtrl,
              decoration: const InputDecoration(labelText: 'Tenant ID'),
            ),
            TextField(
              controller: _profileCtrl,
              decoration: const InputDecoration(labelText: 'Profile ID'),
            ),
            DropdownButtonFormField<String>(
              value: _role,
              decoration: const InputDecoration(labelText: 'Rol'),
              items: MaintenanceRoleLabels.dbRoles
                  .map(
                    (r) => DropdownMenuItem(
                      value: r,
                      child: Text(MaintenanceRoleLabels.labelForDbRole(r)),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _role = v ?? _role),
            ),
            DropdownButtonFormField<String>(
              value: _status,
              decoration: const InputDecoration(labelText: 'Durum'),
              items: const [
                DropdownMenuItem(value: 'active', child: Text('active')),
                DropdownMenuItem(value: 'invited', child: Text('invited')),
                DropdownMenuItem(value: 'disabled', child: Text('disabled')),
              ],
              onChanged: (v) => setState(() => _status = v ?? _status),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton(onPressed: _save, child: const Text('Kaydet')),
          ],
        ),
      ),
    );
  }
}

class MaintenanceMembershipDetailScreen extends StatefulWidget {
  final String membershipId;

  const MaintenanceMembershipDetailScreen({super.key, required this.membershipId});

  @override
  State<MaintenanceMembershipDetailScreen> createState() =>
      _MaintenanceMembershipDetailScreenState();
}

class _MaintenanceMembershipDetailScreenState
    extends State<MaintenanceMembershipDetailScreen> {
  MaintenanceMembershipRow? _row;
  String _role = MaintenanceRoleLabels.dbRoles.first;
  String _status = 'active';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final all = await MaintenanceRepository.fromSupabase().listMemberships();
      final row = all.where((m) => m.id == widget.membershipId).firstOrNull;
      if (!mounted) return;
      setState(() {
        _row = row;
        if (row != null) {
          _role = row.role;
          _status = row.status;
        }
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _saveRole() async {
    try {
      await MaintenanceRepository.fromSupabase().updateMembershipRole(
        membershipId: widget.membershipId,
        role: _role,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rol güncellendi.')),
      );
      _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rol güncellenemedi.')),
      );
    }
  }

  Future<void> _saveStatus() async {
    try {
      await MaintenanceRepository.fromSupabase().updateMembershipStatus(
        membershipId: widget.membershipId,
        status: _status,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Durum güncellendi.')),
      );
      _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Durum güncellenemedi.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaintenanceGate(
      child: MaintenanceScaffold(
        title: 'Üyelik düzenle',
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _row == null
                ? const Center(child: Text('Üyelik bulunamadı.'))
                : ListView(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    children: [
                      Text(_row!.tenantName, style: Theme.of(context).textTheme.titleMedium),
                      Text(_row!.profileEmail ?? '—'),
                      Text(_row!.profileDisplayName ?? '—'),
                      MaintenanceCopyId(label: 'membership_id', value: _row!.id),
                      const Divider(),
                      DropdownButtonFormField<String>(
                        value: _role,
                        decoration: const InputDecoration(labelText: 'Rol'),
                        items: MaintenanceRoleLabels.dbRoles
                            .map(
                              (r) => DropdownMenuItem(
                                value: r,
                                child: Text(MaintenanceRoleLabels.labelForDbRole(r)),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _role = v ?? _role),
                      ),
                      FilledButton(onPressed: _saveRole, child: const Text('Rolü kaydet')),
                      const SizedBox(height: AppSpacing.md),
                      DropdownButtonFormField<String>(
                        value: _status,
                        decoration: const InputDecoration(labelText: 'Durum'),
                        items: const [
                          DropdownMenuItem(value: 'active', child: Text('active')),
                          DropdownMenuItem(value: 'invited', child: Text('invited')),
                          DropdownMenuItem(value: 'disabled', child: Text('disabled')),
                        ],
                        onChanged: (v) => setState(() => _status = v ?? _status),
                      ),
                      FilledButton(onPressed: _saveStatus, child: const Text('Durumu kaydet')),
                    ],
                  ),
      ),
    );
  }
}
