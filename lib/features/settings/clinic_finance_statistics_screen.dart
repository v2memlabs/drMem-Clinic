import 'package:flutter/material.dart';

import '../../core/auth/auth_session.dart';
import '../../core/tenant/tenant_financial_feature_gate.dart';
import '../../core/theme/app_spacing.dart';
import '../payments/data/payment_statistics_calculator.dart';
import '../payments/data/payment_statistics_data_source.dart';
import '../payments/models/payment_record.dart';
import '../payments/models/payment_statistics_snapshot.dart';
import '../payments/widgets/payment_ui_helpers.dart';
import 'settings_subpage_scaffold.dart';
import 'settings_widgets.dart';

class ClinicFinanceStatisticsScreen extends StatefulWidget {
  const ClinicFinanceStatisticsScreen({super.key});

  @override
  State<ClinicFinanceStatisticsScreen> createState() =>
      _ClinicFinanceStatisticsScreenState();
}

class _ClinicFinanceStatisticsScreenState
    extends State<ClinicFinanceStatisticsScreen> {
  PaymentStatisticsScope _scope = PaymentStatisticsScope.month;
  late DateTime _selectedMonth;
  late int _selectedYear;
  late Future<PaymentStatisticsLoadResult> _loadFuture;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month, 1);
    _selectedYear = now.year;
    _reload();
  }

  void _reload() {
    setState(() {
      _loadFuture = PaymentStatisticsDataSource.load(
        scope: _scope,
        year: _scope == PaymentStatisticsScope.month
            ? _selectedMonth.year
            : _selectedYear,
        month: _scope == PaymentStatisticsScope.month ? _selectedMonth.month : null,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return SettingsSubpageScaffold(
      title: 'Finansal İstatistikler',
      icon: Icons.insights_outlined,
      children: [
        Text(
          'Aylık ve yıllık ciro, tahsilat ve hasta özetleri.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: muted),
        ),
        const SizedBox(height: AppSpacing.sm),
        SegmentedButton<PaymentStatisticsScope>(
          segments: const [
            ButtonSegment(
              value: PaymentStatisticsScope.month,
              label: Text('Aylık'),
            ),
            ButtonSegment(
              value: PaymentStatisticsScope.year,
              label: Text('Yıllık'),
            ),
          ],
          selected: {_scope},
          onSelectionChanged: (values) {
            setState(() => _scope = values.first);
            _reload();
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        if (_scope == PaymentStatisticsScope.month)
          DropdownButtonFormField<DateTime>(
            value: _selectedMonth,
            decoration: const InputDecoration(
              labelText: 'Dönem',
              isDense: true,
            ),
            isExpanded: true,
            items: PaymentStatisticsCalculator.recentMonths()
                .map(
                  (month) => DropdownMenuItem(
                    value: month,
                    child: Text(PaymentStatisticsCalculator.monthYearLabel(month)),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() => _selectedMonth = value);
              _reload();
            },
          )
        else
          DropdownButtonFormField<int>(
            value: _selectedYear,
            decoration: const InputDecoration(
              labelText: 'Yıl',
              isDense: true,
            ),
            isExpanded: true,
            items: PaymentStatisticsCalculator.recentYears()
                .map(
                  (year) => DropdownMenuItem(
                    value: year,
                    child: Text('$year'),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() => _selectedYear = value);
              _reload();
            },
          ),
        const SizedBox(height: AppSpacing.md),
        FutureBuilder<PaymentStatisticsLoadResult>(
          future: _loadFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final result = snapshot.data;
            if (result == null) {
              return const Center(child: CircularProgressIndicator());
            }

            if (result.hasError) {
              return SettingsSectionCard(
                title: 'Yüklenemedi',
                icon: Icons.error_outline,
                children: [
                  Text(result.errorMessage!),
                  const SizedBox(height: AppSpacing.sm),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton(
                      onPressed: _reload,
                      child: const Text('Tekrar dene'),
                    ),
                  ),
                ],
              );
            }

            final stats = result.snapshot!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  stats.periodLabel,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SettingsSectionCard(
                  title: 'Ciro özeti',
                  icon: Icons.payments_outlined,
                  children: [
                    SettingsReadOnlyRow(
                      label: 'Toplam tahakkuk',
                      value: formatPaymentAmount(stats.totalAccrual),
                    ),
                    SettingsReadOnlyRow(
                      label: 'Tahsil edilen',
                      value: formatPaymentAmount(stats.totalCollected),
                    ),
                    SettingsReadOnlyRow(
                      label: 'Güncel açık bakiye',
                      value: formatPaymentAmount(stats.openBalanceAllTime),
                    ),
                    SettingsReadOnlyRow(
                      label: 'Açık bakiyeli hasta',
                      value: '${stats.outstandingPatientCount}',
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                SettingsSectionCard(
                  title: 'Dönem özeti',
                  icon: Icons.analytics_outlined,
                  children: [
                    SettingsReadOnlyRow(
                      label: 'Ödeme kaydı',
                      value: '${stats.paymentCount}',
                    ),
                    SettingsReadOnlyRow(
                      label: 'Ödemeli hasta',
                      value: '${stats.patientCount}',
                    ),
                    SettingsReadOnlyRow(
                      label: 'Tahsilat oranı',
                      value:
                          '${(stats.collectionRate * 100).toStringAsFixed(1)} %',
                    ),
                    SettingsReadOnlyRow(
                      label: 'Hasta başına ort. tahsilat',
                      value: formatPaymentAmount(stats.averageCollectedPerPatient),
                    ),
                    SettingsReadOnlyRow(
                      label: 'Güncel açık bakiye (tüm dönemler)',
                      value: formatPaymentAmount(stats.openBalanceAllTime),
                    ),
                    SettingsReadOnlyRow(
                      label: 'Açık bakiyeli hasta',
                      value: '${stats.outstandingPatientCount}',
                    ),
                  ],
                ),
                if (stats.collectedByService.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  SettingsSectionCard(
                    title: 'Hizmet tipine göre tahsilat',
                    icon: Icons.category_outlined,
                    children: [
                      for (final entry in _sortedServiceEntries(stats))
                        SettingsReadOnlyRow(
                          label: paymentServiceTypeLabel(entry.key),
                          value: formatPaymentAmount(entry.value),
                        ),
                    ],
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  List<MapEntry<ServiceType, double>> _sortedServiceEntries(
    PaymentStatisticsSnapshot stats,
  ) {
    final entries = stats.collectedByService.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }
}

bool clinicFinanceStatisticsVisible() =>
    AuthSession.canViewDoctorOnlySettings &&
    TenantFinancialFeatureGate.paymentRecordsEnabled;
