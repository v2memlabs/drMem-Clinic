import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import 'data/maintenance_models.dart';
import 'data/maintenance_repository.dart';
import 'widgets/maintenance_gate.dart';
import 'widgets/maintenance_scaffold.dart';

class MaintenanceAuthProfileScreen extends StatefulWidget {
  const MaintenanceAuthProfileScreen({super.key});

  @override
  State<MaintenanceAuthProfileScreen> createState() =>
      _MaintenanceAuthProfileScreenState();
}

class _MaintenanceAuthProfileScreenState extends State<MaintenanceAuthProfileScreen> {
  late Future<List<MaintenanceProfileGapRow>> _gapsFuture;
  final _emailCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _profileIdCtrl = TextEditingController();
  final _authUuidCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _reloadGaps();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _nameCtrl.dispose();
    _profileIdCtrl.dispose();
    _authUuidCtrl.dispose();
    super.dispose();
  }

  void _reloadGaps() {
    _gapsFuture = MaintenanceRepository.fromSupabase().listProfileAuthGaps();
  }

  Future<void> _createProfile() async {
    try {
      final id = await MaintenanceRepository.fromSupabase().createProfile(
        email: _emailCtrl.text,
        displayName: _nameCtrl.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profil oluşturuldu: $id')),
      );
      _profileIdCtrl.text = id;
      setState(_reloadGaps);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil oluşturulamadı.')),
      );
    }
  }

  Future<void> _linkAuth() async {
    try {
      await MaintenanceRepository.fromSupabase().linkProfileAuth(
        profileId: _profileIdCtrl.text.trim(),
        authUserId: _authUuidCtrl.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Auth bağlantısı kaydedildi.')),
      );
      setState(_reloadGaps);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bağlantı yapılamadı.')),
      );
    }
  }

  Future<void> _updateName() async {
    try {
      await MaintenanceRepository.fromSupabase().updateProfileDisplayName(
        profileId: _profileIdCtrl.text.trim(),
        displayName: _nameCtrl.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Görünen ad güncellendi.')),
      );
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
        title: 'Auth / Profil',
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Text('Yeni profil', style: Theme.of(context).textTheme.titleMedium),
            TextField(
              controller: _emailCtrl,
              decoration: const InputDecoration(labelText: 'E-posta'),
            ),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Görünen ad'),
            ),
            FilledButton(
              onPressed: _createProfile,
              child: const Text('Profil oluştur'),
            ),
            const Divider(height: 32),
            Text('Auth bağla', style: Theme.of(context).textTheme.titleMedium),
            TextField(
              controller: _profileIdCtrl,
              decoration: const InputDecoration(labelText: 'Profile ID'),
            ),
            TextField(
              controller: _authUuidCtrl,
              decoration: const InputDecoration(
                labelText: 'Supabase Auth User UUID',
                hintText: 'Dashboard → Authentication → User UID',
              ),
            ),
            FilledButton(
              onPressed: _linkAuth,
              child: const Text('auth_user_id bağla'),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton(
              onPressed: _updateName,
              child: const Text('Görünen adı güncelle (profile ID)'),
            ),
            const Divider(height: 32),
            Text(
              'Auth bağlantısı eksik profiller',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            FutureBuilder<List<MaintenanceProfileGapRow>>(
              future: _gapsFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.all(AppSpacing.md),
                    child: CircularProgressIndicator(),
                  );
                }
                final gaps = snapshot.data!;
                if (gaps.isEmpty) {
                  return const Text('Tüm profillerde auth_user_id dolu.');
                }
                return Column(
                  children: gaps.map((row) {
                    return Card(
                      child: ListTile(
                        title: Text(row.email ?? '—'),
                        subtitle: Text(row.displayName ?? '—'),
                        trailing: IconButton(
                          icon: const Icon(Icons.link),
                          onPressed: () {
                            _profileIdCtrl.text = row.id;
                            setState(() {});
                          },
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
