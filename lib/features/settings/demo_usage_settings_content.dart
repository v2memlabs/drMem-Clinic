import 'package:flutter/material.dart';

import '../../core/auth/auth_session.dart';
import '../../core/product/demo_freemium_config.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/dashboard_status_badge.dart';
import '../patients/data/patient_count_data_source.dart';
import '../patients/data/patient_demo_count_label.dart';
import 'settings_backend_labels.dart';
import 'settings_product_labels.dart';
import 'settings_widgets.dart';

/// Demo / Kullanım Durumu içeriği — teknik ID göstermez.
class DemoUsageSettingsContent extends StatefulWidget {
  const DemoUsageSettingsContent({super.key});

  @override
  State<DemoUsageSettingsContent> createState() => _DemoUsageSettingsContentState();
}

class _DemoUsageSettingsContentState extends State<DemoUsageSettingsContent> {
  int? _patientCount;
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await PatientCountDataSource.load();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _patientCount = result.count;
      _errorMessage = result.errorMessage;
    });
  }

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final limit = DemoFreemiumConfig.demoPatientRecordLimit;
    final user = AuthSession.currentUser;

    String countLabel;
    if (_loading) {
      countLabel = '…';
    } else if (_errorMessage != null) {
      countLabel = _errorMessage!;
    } else {
      countLabel = PatientDemoCountLabel.format(
        count: _patientCount ?? 0,
        limit: limit,
      );
    }

    final limitNote = PatientDemoCountLabel.limitNote(
      count: _patientCount ?? 0,
      limit: limit,
    );

    return SettingsSectionCard(
      title: 'Demo ve Kullanım Durumu',
      icon: Icons.science_outlined,
      children: [
        SettingsReadOnlyRow(
          label: 'Demo modu',
          value: DemoFreemiumConfig.productModeLabel,
          trailing: const DashboardStatusBadge(label: 'Demo'),
        ),
        SettingsReadOnlyRow(
          label: 'Backend',
          value: SettingsBackendLabels.backendModeLabel,
        ),
        SettingsReadOnlyRow(
          label: 'Aktif klinik',
          value: SettingsBackendLabels.activeClinicDisplayName,
        ),
        SettingsReadOnlyRow(
          label: 'Aktif rol',
          value: SettingsProductLabels.roleLabel(user?.role),
        ),
        SettingsReadOnlyRow(
          label: 'Hasta kaydı',
          value: countLabel,
          trailing: _loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                )
              : null,
        ),
        Text(
          limitNote,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: muted),
        ),
        const SizedBox(height: AppSpacing.xs),
        SettingsReadOnlyRow(
          label: 'Demo süre / limit',
          value: 'İleride gösterilecek',
        ),
        SettingsReadOnlyRow(
          label: 'Sistem durumu',
          value: SettingsBackendLabels.systemStatusLabel,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Bu ortam demo/seed verisi içerebilir. Gerçek hasta verisi kullanmayın.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: muted),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Ek servisler (bildirim, PDF paylaşımı, AI özet vb.) ileride kontörlü veya abonelikli olabilir.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: muted),
        ),
      ],
    );
  }
}
