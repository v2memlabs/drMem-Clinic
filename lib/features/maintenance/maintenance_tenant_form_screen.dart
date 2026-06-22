import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/widgets/form_section_card.dart';
import '../../shared/widgets/page_header.dart';
import 'data/maintenance_provision_errors.dart';
import 'data/maintenance_provision_models.dart';
import 'data/maintenance_repository.dart';
import 'widgets/maintenance_form_scaffold.dart';
import 'widgets/maintenance_gate.dart';

typedef MaintenanceTenantCreateFn = Future<MaintenanceTenantCreateResult> Function(
  MaintenanceTenantCreateRequest request,
);

/// Maintenance operator tenant oluşturma formu (v2a-1).
class MaintenanceTenantFormScreen extends StatefulWidget {
  const MaintenanceTenantFormScreen({
    super.key,
    this.createTenantOverride,
    this.bypassGateForTesting = false,
  });

  @visibleForTesting
  final MaintenanceTenantCreateFn? createTenantOverride;

  @visibleForTesting
  final bool bypassGateForTesting;

  @override
  State<MaintenanceTenantFormScreen> createState() =>
      _MaintenanceTenantFormScreenState();
}

class _MaintenanceTenantFormScreenState extends State<MaintenanceTenantFormScreen> {
  final _nameCtrl = TextEditingController();
  final _specialtyCtrl = TextEditingController();

  String _timezone = 'Europe/Istanbul';
  String _status = 'active';
  bool _busy = false;
  String? _errorMessage;

  static const _timezones = ['Europe/Istanbul', 'UTC', 'Europe/London'];
  static const _statuses = ['active', 'trial', 'suspended'];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _specialtyCtrl.dispose();
    super.dispose();
  }

  void _cancel() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/maintenance/tenants');
    }
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _errorMessage = 'Klinik adı zorunludur.');
      return;
    }

    setState(() {
      _busy = true;
      _errorMessage = null;
    });

    final request = MaintenanceTenantCreateRequest(
      name: name,
      specialty: _specialtyCtrl.text.trim().isEmpty
          ? null
          : _specialtyCtrl.text.trim(),
      timezone: _timezone,
      status: _status,
    );

    try {
      final create = widget.createTenantOverride ??
          (req) => MaintenanceRepository.fromSupabase().createTenantV2(req);
      await create(request);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Klinik oluşturuldu.')),
      );
      context.go('/maintenance/tenants');
    } on MaintenanceProvisionException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _errorMessage = MaintenanceProvisionErrorMapper.userMessage(e.reason);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _errorMessage = 'Klinik oluşturulamadı.';
      });
    }
  }

  Widget? _errorBanner() {
    if (_errorMessage == null) return null;
    return MaterialBanner(
      content: Text(_errorMessage!),
      leading: const Icon(Icons.error_outline),
      actions: [
        TextButton(
          onPressed: () => setState(() => _errorMessage = null),
          child: const Text('Kapat'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final form = MaintenanceFormScaffold.sections(
      title: 'Yeni Klinik',
      onSave: _save,
      onCancel: _cancel,
      saveLabel: 'Kaydet',
      saving: _busy,
      headerBanner: _errorBanner(),
      header: const PageHeader(
        title: 'Yeni Klinik',
        icon: Icons.add_business_outlined,
        leadingBack: true,
        fallbackRoute: '/maintenance/tenants',
      ),
      sections: [
        FormSectionCard(
          title: 'Klinik Bilgisi',
          icon: Icons.business_outlined,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Klinik adı *',
                isDense: true,
              ),
              textInputAction: TextInputAction.next,
              enabled: !_busy,
            ),
            TextField(
              controller: _specialtyCtrl,
              decoration: const InputDecoration(
                labelText: 'Branş',
                isDense: true,
              ),
              textInputAction: TextInputAction.next,
              enabled: !_busy,
            ),
          ],
        ),
        FormSectionCard(
          title: 'Yapılandırma',
          icon: Icons.settings_outlined,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _timezone,
              decoration: const InputDecoration(
                labelText: 'Saat dilimi',
                isDense: true,
              ),
              isExpanded: true,
              items: _timezones
                  .map((tz) => DropdownMenuItem(value: tz, child: Text(tz)))
                  .toList(),
              onChanged: _busy
                  ? null
                  : (v) => setState(() => _timezone = v ?? _timezone),
            ),
            DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: const InputDecoration(
                labelText: 'Durum',
                isDense: true,
              ),
              isExpanded: true,
              items: _statuses
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: _busy
                  ? null
                  : (v) => setState(() => _status = v ?? _status),
            ),
          ],
        ),
      ],
    );

    if (widget.bypassGateForTesting) return form;
    return MaintenanceGate(child: form);
  }
}
