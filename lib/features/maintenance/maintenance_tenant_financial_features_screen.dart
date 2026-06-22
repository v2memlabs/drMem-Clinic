import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_spacing.dart';
import '../settings/models/tenant_financial_feature_settings.dart';
import 'data/maintenance_repository.dart';
import 'widgets/maintenance_copy_id.dart';
import 'widgets/maintenance_gate.dart';
import 'widgets/maintenance_scaffold.dart';

class MaintenanceTenantFinancialFeaturesScreen extends StatefulWidget {
  final String tenantId;
  final String tenantName;

  const MaintenanceTenantFinancialFeaturesScreen({
    super.key,
    required this.tenantId,
    required this.tenantName,
  });

  @override
  State<MaintenanceTenantFinancialFeaturesScreen> createState() =>
      _MaintenanceTenantFinancialFeaturesScreenState();
}

class _MaintenanceTenantFinancialFeaturesScreenState
    extends State<MaintenanceTenantFinancialFeaturesScreen> {
  TenantFinancialFeatureSettings? _draft;
  bool _loading = true;
  bool _saving = false;
  String? _loadError;

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
      final settings = await MaintenanceRepository.fromSupabase()
          .getTenantFinancialSettings(widget.tenantId);
      if (!mounted) return;
      setState(() {
        _draft = settings;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadError = 'Finansal özellik ayarları yüklenemedi.';
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    final draft = _draft;
    if (draft == null || _saving) return;

    setState(() => _saving = true);
    try {
      await MaintenanceRepository.fromSupabase().updateTenantFinancialSettings(
        tenantId: widget.tenantId,
        settings: draft,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Finansal özellik ayarları kaydedildi.')),
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
        title: 'Finansal Özellikler',
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _loadError != null
                ? Center(child: Text(_loadError!))
                : _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final settings = _draft ?? TenantFinancialFeatureSettings.defaults;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Text(
          widget.tenantName,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        MaintenanceCopyId(label: 'tenant_id', value: widget.tenantId),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Klinik finansal veri kaydı ve paylaşımını tenant bazında kapatın. '
          'Kapalı özellikler uygulamada gizlenir; mevcut kayıtlar silinmez.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: AppSpacing.md),
        ...TenantFinancialFeatureCatalog.definitions.map(
          (def) => SwitchListTile(
            title: Text(def.label),
            subtitle: Text(def.description),
            value: settings.isEnabled(def.key),
            onChanged: _saving
                ? null
                : (enabled) {
                    setState(() {
                      _draft = settings.copyWithFlag(def.key, enabled);
                    });
                  },
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
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
      ],
    );
  }
}
