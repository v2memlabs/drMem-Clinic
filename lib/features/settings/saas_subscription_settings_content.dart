import 'package:flutter/material.dart';

import '../../core/product/demo_freemium_config.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/clinical_notice.dart';
import '../../shared/widgets/clinical_notice_tone.dart';
import '../../shared/widgets/dashboard_status_badge.dart';
import 'data/saas_subscription_data_source.dart';
import 'models/tenant_subscription_summary.dart';
import 'settings_widgets.dart';

/// SaaS / Abonelik içeriği — salt okunur özet (ödeme entegrasyonu yok).
class SaasSubscriptionSettingsContent extends StatefulWidget {
  final bool compact;

  const SaasSubscriptionSettingsContent({super.key, this.compact = false});

  @override
  State<SaasSubscriptionSettingsContent> createState() =>
      _SaasSubscriptionSettingsContentState();
}

class _SaasSubscriptionSettingsContentState
    extends State<SaasSubscriptionSettingsContent> {
  TenantSubscriptionSummary? _summary;
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    final result = await SaasSubscriptionDataSource.load();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _summary = result.summary;
      _errorMessage = result.errorMessage;
    });
  }

  String _statusBadgeLabel(TenantSubscriptionSummary summary) {
    switch (summary.status) {
      case 'past_due':
        return 'Ödeme gecikmiş';
      case 'canceled':
        return 'İptal';
      case 'trialing':
        return 'Deneme';
      default:
        return summary.statusLabel;
    }
  }

  bool _statusBadgeMuted(TenantSubscriptionSummary summary) {
    return summary.status == 'canceled' || summary.status == 'past_due';
  }

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final summary = _summary;

    if (_loading) {
      return const SettingsSectionCard(
        title: 'Abonelik özeti',
        icon: Icons.workspace_premium_outlined,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      );
    }

    if (_errorMessage != null) {
      return SettingsSectionCard(
        title: 'Abonelik özeti',
        icon: Icons.workspace_premium_outlined,
        children: [
          ClinicalNotice(
            tone: ClinicalNoticeTone.danger,
            dense: true,
            message: _errorMessage!,
            actions: [
              ClinicalNoticeAction(label: 'Yeniden dene', onPressed: _load),
            ],
          ),
        ],
      );
    }

    if (summary == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsSectionCard(
          title: 'Abonelik özeti',
          icon: Icons.workspace_premium_outlined,
          children: [
            SettingsReadOnlyRow(
              label: 'Plan',
              value: summary.planLabel,
              trailing: DashboardStatusBadge(label: summary.statusLabel),
            ),
            if (summary.renewalLabel != null)
              SettingsReadOnlyRow(
                label: 'Dönem bitişi',
                value: summary.renewalLabel!,
              ),
            Row(
              children: [
                Text(
                  'Faturalama',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: muted,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(width: AppSpacing.xs),
                DashboardStatusBadge(
                  label: _statusBadgeLabel(summary),
                  muted: _statusBadgeMuted(summary),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              summary.fromRemoteRecord
                  ? 'Bu özet aktif klinik abonelik kaydından okunur. Plan yükseltme ve ödeme yönetimi sonraki sürümde eklenecektir.'
                  : 'Yerel demo modunda çalışıyorsunuz. Uzak sunucuya bağlandığınızda abonelik kaydı burada görünür.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: muted),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SettingsSectionCard(
          title: 'Kullanım',
          icon: Icons.pie_chart_outline,
          children: [
            SettingsReadOnlyRow(
              label: 'Kullanıcı / koltuk',
              value: summary.formatUsage(
                used: summary.seatUsed,
                limit: summary.seatLimit,
              ),
            ),
            SettingsReadOnlyRow(
              label: 'Hasta kaydı',
              value: summary.formatUsage(
                used: summary.patientCount,
                limit: summary.patientLimit,
              ),
            ),
            SettingsReadOnlyRow(
              label: 'Temel modüller',
              value: 'Aktif',
            ),
            Text(
              'Kullanım limitleri bilgilendirme amaçlıdır; hasta kaydı akışı bu sürümde engellenmez.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: muted),
            ),
          ],
        ),
        if (!widget.compact) ...[
          const SizedBox(height: 12),
          SettingsSectionCard(
            title: 'Planlanan ek servisler',
            icon: Icons.bolt_outlined,
            children: [
              Text(
                'Kontörlü veya paketli olarak sunulacak servisler:',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: muted),
              ),
              const SizedBox(height: AppSpacing.xs),
              ...DemoFreemiumConfig.futureMeteredServices.map(
                (s) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.circle, size: 6, color: muted),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          s,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: muted,
                              ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      const DashboardStatusBadge(label: 'Planlanan', muted: true),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
