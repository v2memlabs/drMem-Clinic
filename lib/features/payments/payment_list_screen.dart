import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_session.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/layout/responsive_page_body.dart';
import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/clinical_separated_list_body.dart';
import '../../shared/widgets/clinical_status_legend.dart';
import '../../shared/widgets/clinical_state_message.dart';
import '../../shared/widgets/filter_bar.dart';
import '../../shared/widgets/page_header.dart';
import 'data/payment_list_data_source.dart';
import 'data/payment_list_period_filter.dart';
import 'data/payment_outstanding_balance.dart';
import 'data/payment_list_load_result.dart';
import 'data/payment_list_refresh.dart';
import 'data/payment_list_user_messages.dart';
import 'models/payment_record.dart';
import 'widgets/payment_clinical_list_row.dart';
import 'widgets/payment_list_legend.dart';
import 'widgets/payment_summary_kpi_strip.dart';
import 'widgets/payment_ui_helpers.dart';

class PaymentListScreen extends StatefulWidget {
  final String? patientId;
  const PaymentListScreen({super.key, this.patientId});

  @override
  State<PaymentListScreen> createState() => _PaymentListScreenState();
}

class _PaymentListScreenState extends State<PaymentListScreen> {
  String _query = '';
  ServiceType? _serviceFilter;
  PaymentStatus? _statusFilter;
  PaymentMethod? _methodFilter;
  late Future<PaymentListLoadResult> _loadFuture;
  PaymentListLoadResult? _cachedResult;
  bool _activatedOnce = false;
  int _lastRefreshVersion = PaymentListRefresh.version;
  Timer? _searchDebounce;

  int get _paymentActiveFilterCount {
    var n = 0;
    if (_serviceFilter != null) n++;
    if (_statusFilter != null) n++;
    if (_methodFilter != null) n++;
    return n;
  }

  void _clearPaymentFilters() {
    setState(() {
      _serviceFilter = null;
      _statusFilter = null;
      _methodFilter = null;
    });
    _reload();
  }

  void _scheduleSearchReload() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) {
        _reload();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void activate() {
    super.activate();
    if (!_activatedOnce) {
      _activatedOnce = true;
      return;
    }
    if (PaymentListRefresh.isStale(_lastRefreshVersion)) {
      _reload();
    }
  }

  void _reload() {
    _searchDebounce?.cancel();
    _lastRefreshVersion = PaymentListRefresh.version;
    setState(() {
      _loadFuture = PaymentListDataSource.load(
        patientId: widget.patientId,
        query: _query,
        serviceTypeFilter: _serviceFilter,
        paymentStatusFilter: _statusFilter,
        paymentMethodFilter: _methodFilter,
      );
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _openPaymentDetail(String id) async {
    await context.push('/payments/$id');
    if (mounted && PaymentListRefresh.isStale(_lastRefreshVersion)) {
      _reload();
    }
  }

  Future<void> _openNewPayment() async {
    await context.push(
      '/payments/new${widget.patientId != null ? '?patientId=${widget.patientId}' : ''}',
    );
    if (mounted && PaymentListRefresh.isStale(_lastRefreshVersion)) {
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Ödeme / Tahsilat Takibi',
      child: ResponsiveListPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PageHeader(
              title: 'Ödemeler',
              icon: Icons.payments_outlined,
            ),
            if (widget.patientId == null || widget.patientId!.trim().isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Text(
                  '${PaymentListPeriodFilter.currentMonthLabel()} dönemi gösteriliyor. '
                  'Ödemesi tamamlanan geçmiş ay kayıtları listeden kalkar; '
                  'açık bakiyeli hastalar görünmeye devam eder.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            FilterBar(
              searchHint: 'Hasta, not veya hizmet ara',
              onSearchChanged: (v) {
                _query = v;
                _scheduleSearchReload();
              },
              collapsible: true,
              activeFilterCount: _paymentActiveFilterCount,
              onClearFilters:
                  _paymentActiveFilterCount > 0 ? _clearPaymentFilters : null,
              trailing: AuthSession.canCreatePayments
                  ? FilledButton.icon(
                      onPressed: _openNewPayment,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Yeni Kayıt'),
                    )
                  : null,
              filters: [
                SizedBox(
                  width: 200,
                  child: DropdownButtonFormField<ServiceType?>(
                    key: ValueKey(_serviceFilter),
                    initialValue: _serviceFilter,
                    decoration: const InputDecoration(
                      labelText: 'Hizmet',
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Tümü')),
                      ...ServiceType.values.map(
                        (s) => DropdownMenuItem(
                          value: s,
                          child: Text(paymentServiceTypeLabel(s)),
                        ),
                      ),
                    ],
                    onChanged: (v) {
                      setState(() => _serviceFilter = v);
                      _reload();
                    },
                  ),
                ),
                SizedBox(
                  width: 200,
                  child: DropdownButtonFormField<PaymentStatus?>(
                    key: ValueKey(_statusFilter),
                    initialValue: _statusFilter,
                    decoration: const InputDecoration(
                      labelText: 'Ödeme Durumu',
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Tümü')),
                      ...PaymentStatus.values.map(
                        (s) => DropdownMenuItem(
                          value: s,
                          child: Text(paymentStatusLabel(s)),
                        ),
                      ),
                    ],
                    onChanged: (v) {
                      setState(() => _statusFilter = v);
                      _reload();
                    },
                  ),
                ),
                SizedBox(
                  width: 200,
                  child: DropdownButtonFormField<PaymentMethod?>(
                    key: ValueKey(_methodFilter),
                    initialValue: _methodFilter,
                    decoration: const InputDecoration(
                      labelText: 'Yöntem',
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Tümü')),
                      ...PaymentMethod.values.map(
                        (s) => DropdownMenuItem(
                          value: s,
                          child: Text(paymentMethodLabel(s)),
                        ),
                      ),
                    ],
                    onChanged: (v) {
                      setState(() => _methodFilter = v);
                      _reload();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(child: _buildBody(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return FutureBuilder<PaymentListLoadResult>(
      future: _loadFuture,
      builder: (context, snapshot) {
        final waiting = snapshot.connectionState == ConnectionState.waiting;
        final result = snapshot.data;

        if (waiting && _cachedResult == null) {
          return ClinicalStateMessage.loading(
            message: PaymentListUserMessages.loading,
          );
        }

        if (result != null && !result.hasError) {
          _cachedResult = result;
        }

        final active = result ?? _cachedResult;
        if (active == null) {
          return ClinicalStateMessage.loading(
            message: PaymentListUserMessages.loading,
          );
        }

        if (active.hasError) {
          return ClinicalStateMessage.error(
            icon: Icons.error_outline,
            title: PaymentListUserMessages.errorTitle,
            description: ClinicalStateMessage.safeErrorDescription(
              active.errorMessage,
            ),
            onRetry: _reload,
          );
        }

        final list = active.records;
        final totalAccrual = _totalAmount(list);
        final totalPaid = _totalPaid(list);
        final pendingAmount = _totalRemaining(list);
        final pendingCount = _pendingCount(list);

        if (list.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PaymentSummaryKpiStrip(
                totalAccrual: formatPaymentAmount(totalAccrual),
                totalPaid: formatPaymentAmount(totalPaid),
                pendingAmount: formatPaymentAmount(pendingAmount),
                pendingCount: '$pendingCount',
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: ClinicalStateMessage.empty(
                  icon: Icons.payments_outlined,
                  title: 'Bu dönem için ödeme kaydı yok',
                  description:
                      'Açık bakiyeli hasta kaydı bulunmuyor. Yeni kayıt ekleyebilir '
                      'veya filtreleri temizleyebilirsiniz.',
                ),
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PaymentSummaryKpiStrip(
              totalAccrual: formatPaymentAmount(totalAccrual),
              totalPaid: formatPaymentAmount(totalPaid),
              pendingAmount: formatPaymentAmount(pendingAmount),
              pendingCount: '$pendingCount',
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: ClinicalSeparatedListBody(
                legend: const ClinicalStatusLegend(
                  items: PaymentListLegend.items,
                ),
                children: [
                  for (final record in list)
                    PaymentClinicalListRow(
                      record: record,
                      onTap: () => _openPaymentDetail(record.id),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  static double _totalAmount(List<PaymentRecord> records) =>
      records.fold<double>(0, (s, p) => s + p.totalAmount);

  static double _totalPaid(List<PaymentRecord> records) =>
      records.fold<double>(0, (s, p) => s + p.paidAmount);

  static double _totalRemaining(List<PaymentRecord> records) =>
      records.fold<double>(0, (s, p) => s + p.remainingAmount);

  static int _pendingCount(List<PaymentRecord> records) =>
      records.where(PaymentOutstandingBalance.hasOutstanding).length;
}

