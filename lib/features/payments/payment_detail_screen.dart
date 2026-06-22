import '../../../shared/widgets/clinical_stacked_sections.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_spacing.dart';
import '../../shared/layout/responsive_page_body.dart';
import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/clinical_state_message.dart';
import '../../shared/widgets/detail_header_card.dart';
import '../../shared/widgets/info_section_card.dart'
    show InfoSectionCard, InfoSectionRow, kDisplayUnspecified;
import '../../shared/widgets/page_header.dart';
import '../patients/widgets/patient_lookup_builder.dart';
import 'data/payment_permissions.dart';
import 'data/payment_detail_data_source.dart';
import 'data/payment_detail_load_result.dart';
import 'data/payment_detail_user_messages.dart';
import 'data/payment_list_refresh.dart';
import 'models/payment_record.dart';
import 'widgets/payment_ui_helpers.dart';

class PaymentDetailScreen extends StatefulWidget {
  final String id;
  const PaymentDetailScreen({super.key, required this.id});

  @override
  State<PaymentDetailScreen> createState() => _PaymentDetailScreenState();
}

class _PaymentDetailScreenState extends State<PaymentDetailScreen> {
  late Future<PaymentDetailLoadResult> _loadFuture;
  PaymentDetailLoadResult? _cachedResult;
  bool _activatedOnce = false;
  int _lastRefreshVersion = PaymentListRefresh.version;

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
    _lastRefreshVersion = PaymentListRefresh.version;
    setState(() {
      _loadFuture = PaymentDetailDataSource.loadById(widget.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PaymentDetailLoadResult>(
      future: _loadFuture,
      builder: (context, snapshot) {
        final waiting = snapshot.connectionState == ConnectionState.waiting;
        final result = snapshot.data;

        if (waiting && _cachedResult == null) {
          return AppShell(
            title: 'Ödeme Detayı',
            child: ClinicalStateMessage.loading(
              message: PaymentDetailUserMessages.loading,
            ),
          );
        }

        if (result != null && !result.hasError && result.record != null) {
          _cachedResult = result;
        }

        final active = _cachedResult ?? result;
        if (active == null) {
          return AppShell(
            title: 'Ödeme Detayı',
            child: ClinicalStateMessage.loading(
              message: PaymentDetailUserMessages.loading,
            ),
          );
        }

        if (active.hasError) {
          return AppShell(
            title: 'Ödeme Detayı',
            child: ClinicalStateMessage.error(
              icon: Icons.error_outline,
              title: PaymentDetailUserMessages.errorTitle,
              description: ClinicalStateMessage.safeErrorDescription(
                active.errorMessage,
              ),
              onRetry: _reload,
            ),
          );
        }

        if (active.notFound || active.record == null) {
          return AppShell(
            title: 'Ödeme Detayı',
            child: ClinicalStateMessage.empty(
              icon: Icons.error_outline,
              title: PaymentDetailUserMessages.notFoundTitle,
              description: PaymentDetailUserMessages.notFoundDescription,
            ),
          );
        }

        return _buildContent(context, active.record!);
      },
    );
  }

  Widget _buildContent(BuildContext context, PaymentRecord p) {
    return PatientLookupBuilder(
      patientId: p.patientId,
      builder: (context, patient) {
        final fileLine = patient != null ? 'Dosya ${patient.fileNumber}' : '';
        return _buildPaymentDetailBody(context, p, fileLine);
      },
    );
  }

  Widget _buildPaymentDetailBody(
    BuildContext context,
    PaymentRecord p,
    String fileLine,
  ) {
    final dateStr = _formatDate(p.transactionDate);
    final createdStr = _formatDate(p.createdAt);

    return AppShell(
      title: 'Ödeme Detayı',
      child: ResponsiveDetailPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PageHeader(
              title: 'Ödeme Detayı',
              icon: Icons.payments_outlined,
              leadingBack: true,
              fallbackRoute: '/payments',
              trailing: PaymentPermissions.canEditPayment(p)
                  ? IconButton(
                      tooltip: 'Düzenle',
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => context.push('/payments/${p.id}/edit'),
                    )
                  : null,
            ),
            DetailHeaderCard(
              title: p.patientName,
              subtitle: '$dateStr • ${paymentServiceTypeLabel(p.serviceType)}',
            ),
            ClinicalStackedSections(
              children: [
                InfoSectionCard(
                  title: 'Özet',
                  rows: [
                    if (fileLine.isNotEmpty) InfoSectionRow('Dosya', fileLine),
                    InfoSectionRow(
                      'Toplam',
                      formatPaymentAmount(p.totalAmount),
                      emphasize: true,
                    ),
                    InfoSectionRow('Ödenen', formatPaymentAmount(p.paidAmount)),
                    InfoSectionRow(
                      'Kalan',
                      formatPaymentAmount(p.remainingAmount),
                      emphasize: p.remainingAmount > 0,
                    ),
                    InfoSectionRow('Ödeme durumu', p.paymentStatusLabel),
                    InfoSectionRow('Fatura durumu', p.invoiceStatusLabel),
                  ],
                ),
                InfoSectionCard(
                  title: 'Hizmet ve Ödeme',
                  rows: [
                    InfoSectionRow('Hizmet', p.serviceTypeLabel),
                if (p.rehabBillingSummary != null)
                  InfoSectionRow(
                    'Rehabilitasyon',
                    p.rehabBillingSummary!,
                  ),
                    InfoSectionRow('Ödeme yöntemi', p.paymentMethodLabel),
                    InfoSectionRow('İşlem tarihi', dateStr),
                  ],
                ),
                InfoSectionCard(
                  title: 'Kayıt Bilgisi',
                  rows: [
                    InfoSectionRow('Kayıt tarihi', createdStr),
                    InfoSectionRow('Kaydeden', p.recordedBy),
                  ],
                ),
                InfoSectionCard(
                  title: 'Notlar',
                  rows: [
                    InfoSectionRow(
                      'Notlar',
                      p.notes.isEmpty ? kDisplayUnspecified : p.notes,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}

String _formatDate(DateTime date) {
  final local = date.toLocal();
  final d = local.day.toString().padLeft(2, '0');
  final m = local.month.toString().padLeft(2, '0');
  return '$d.$m.${local.year}';
}
