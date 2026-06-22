import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/tenant/tenant_financial_feature_gate.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/clinical_snack_bar.dart';
import '../../../shared/widgets/clinical_state_message.dart';
import '../../../shared/widgets/form_screen_layout.dart';
import '../../../shared/widgets/form_section_card.dart';
import '../../../shared/widgets/page_header.dart';
import '../data/clinical_encounter_lookup_data_source.dart';
import '../models/clinical_encounter.dart';
import '../models/clinical_treatment_approach.dart';
import '../../payments/data/payment_form_data_source.dart';
import '../../payments/data/payment_list_refresh.dart';
import '../../payments/data/payment_notification_data_source.dart';
import '../../payments/models/payment_record.dart';
import '../../payments/widgets/payment_ui_helpers.dart';
import 'data/patient_surgical_quote_alert_repository.dart';
import 'models/patient_surgical_quote_alert.dart';
import 'models/surgical_quote_currency.dart';
import 'post_encounter_wizard_progress.dart';

class PostEncounterPaymentStepScreen extends StatefulWidget {
  final String encounterId;
  final int progressCurrent;
  final int progressTotal;

  const PostEncounterPaymentStepScreen({
    super.key,
    required this.encounterId,
    required this.progressCurrent,
    required this.progressTotal,
  });

  @override
  State<PostEncounterPaymentStepScreen> createState() =>
      _PostEncounterPaymentStepScreenState();
}

class _PostEncounterPaymentStepScreenState
    extends State<PostEncounterPaymentStepScreen> {
  final _formKey = GlobalKey<FormState>();
  final _totalAmountCtrl = TextEditingController(text: '0');
  final _paidAmountCtrl = TextEditingController(text: '0');
  final _quoteAmountCtrl = TextEditingController();
  final _quoteNoteCtrl = TextEditingController();
  PaymentMethod paymentMethod = PaymentMethod.belirtilmedi;
  PaymentStatus paymentStatus = PaymentStatus.bekliyor;
  InvoiceStatus invoiceStatus = InvoiceStatus.belirtilmedi;
  String notes = '';
  SurgicalQuoteCurrency quoteCurrency = SurgicalQuoteCurrency.try_;
  bool _saving = false;
  ClinicalEncounter? _encounter;

  bool get _showSurgicalQuote => _showSurgicalQuoteFor(_encounter);

  @override
  void initState() {
    super.initState();
    _loadEncounter();
  }

  Future<void> _loadEncounter() async {
    final encounter =
        await ClinicalEncounterLookupDataSource.findById(widget.encounterId);
    if (!mounted) return;
    setState(() {
      _encounter = encounter;
      if (_showSurgicalQuoteFor(encounter)) {
        final recommendation = encounter?.surgeryRecommendation.trim() ?? '';
        if (recommendation.isNotEmpty) {
          _quoteNoteCtrl.text = recommendation;
        }
      }
    });
  }

  bool _showSurgicalQuoteFor(ClinicalEncounter? encounter) {
    if (!TenantFinancialFeatureGate.surgicalQuotePricingEnabled) {
      return false;
    }
    final approach = encounter?.treatmentApproach;
    return approach == ClinicalTreatmentApproach.surgical ||
        approach == ClinicalTreatmentApproach.combined;
  }

  @override
  void dispose() {
    _totalAmountCtrl.dispose();
    _paidAmountCtrl.dispose();
    _quoteAmountCtrl.dispose();
    _quoteNoteCtrl.dispose();
    super.dispose();
  }

  double? _parseAmount(String raw) {
    final normalized = raw.trim().replaceAll(',', '.');
    if (normalized.isEmpty) return null;
    return double.tryParse(normalized);
  }

  Future<void> _save() async {
    final encounter = _encounter;
    if (encounter == null || _saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    _formKey.currentState!.save();

    final totalAmount = _parseAmount(_totalAmountCtrl.text) ?? 0;
    final paidAmount = _parseAmount(_paidAmountCtrl.text) ?? 0;
    if (paidAmount > totalAmount) {
      showClinicalSnackBar(
        context,
        'Ödenen tutar toplam tutardan büyük olamaz.',
        isError: true,
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final performer = AuthSession.currentUser?.displayName ?? 'Hekim';
      final payment = PaymentRecord(
        id: 'pay-${DateTime.now().millisecondsSinceEpoch}',
        patientId: encounter.patientId,
        patientName: encounter.patientName,
        createdAt: DateTime.now(),
        serviceType: ServiceType.muayene,
        totalAmount: totalAmount,
        paidAmount: paidAmount,
        paymentMethod: paymentMethod,
        paymentStatus: paymentStatus,
        invoiceStatus: invoiceStatus,
        transactionDate: DateTime.now(),
        recordedBy: performer,
        notes: notes,
        clinicalEncounterId: encounter.id,
      );

      final paymentResult = await PaymentFormDataSource.add(payment);
      if (!mounted) return;
      if (paymentResult.hasError) {
        showClinicalSnackBar(context, paymentResult.errorMessage!, isError: true);
        return;
      }

      PaymentListRefresh.markStale();

      if (_showSurgicalQuote) {
        final quoteAmount = _parseAmount(_quoteAmountCtrl.text);
        if (TenantFinancialFeatureGate.surgicalQuoteAlertsEnabled) {
          final alert = PatientSurgicalQuoteAlert(
            id: 'surg-quote-${DateTime.now().millisecondsSinceEpoch}',
            patientId: encounter.patientId,
            patientName: encounter.patientName,
            clinicalEncounterId: encounter.id,
            procedureNote: _quoteNoteCtrl.text.trim(),
            quotedAmount: quoteAmount,
            currency: quoteCurrency,
            createdAt: DateTime.now(),
            createdByDisplay: performer,
          );
          PatientSurgicalQuoteAlertRepository.instance.add(alert);
        }
        if (TenantFinancialFeatureGate.assistantFinanceNotificationsEnabled) {
          await PaymentNotificationDataSource.notifyAssistantForSurgicalQuote(
            patientId: encounter.patientId,
            patientName: encounter.patientName,
            clinicalEncounterId: encounter.id,
            quotedAmount: quoteAmount,
            currency: quoteCurrency,
            procedureNote: _quoteNoteCtrl.text.trim(),
          );
        }
      }

      if (!mounted) return;
      showClinicalSnackBar(context, 'Ödeme kaydı tamamlandı.');
      context.pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _skipToDashboard() {
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final encounter = _encounter;
    if (encounter == null) {
      return AppShell(
        title: 'Muayene Sonrası — Ödeme',
        child: ClinicalStateMessage.empty(
          icon: Icons.assignment_outlined,
          title: 'Muayene kaydı bulunamadı',
        ),
      );
    }

    return AppShell(
      title: 'Muayene Sonrası — Ödeme',
      child: Column(
        children: [
          PostEncounterWizardProgress(
            currentStep: widget.progressCurrent,
            totalSteps: widget.progressTotal,
            label: 'Ödeme',
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = FormScreenLayout.contentWidth(constraints.maxWidth);
                return Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    width: width,
                    child: Form(
                      key: _formKey,
                      child: ListView(
                        padding: FormScreenLayout.scrollPadding(),
                        children: [
                          const PageHeader(
                            title: 'Muayene Ödemesi',
                            leadingBack: false,
                          ),
                          Text(
                            encounter.patientName,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          FormSectionCard(
                            title: 'Muayene Ödemesi',
                            icon: Icons.payments_outlined,
                            children: [
                              TextFormField(
                                initialValue: paymentServiceTypeLabel(
                                  ServiceType.muayene,
                                ),
                                readOnly: true,
                                decoration: const InputDecoration(
                                  labelText: 'Hizmet türü',
                                ),
                              ),
                              TextFormField(
                                controller: _totalAmountCtrl,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                decoration: const InputDecoration(
                                  labelText: 'Toplam tutar (TL)',
                                ),
                                validator: (value) {
                                  final amount = _parseAmount(value ?? '');
                                  if (amount == null || amount < 0) {
                                    return 'Geçerli bir tutar girin';
                                  }
                                  return null;
                                },
                              ),
                              TextFormField(
                                controller: _paidAmountCtrl,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                decoration: const InputDecoration(
                                  labelText: 'Ödenen tutar (TL)',
                                ),
                                validator: (value) {
                                  final amount = _parseAmount(value ?? '');
                                  if (amount == null || amount < 0) {
                                    return 'Geçerli bir tutar girin';
                                  }
                                  return null;
                                },
                              ),
                              DropdownButtonFormField<PaymentMethod>(
                                initialValue: paymentMethod,
                                decoration: const InputDecoration(
                                  labelText: 'Ödeme yöntemi',
                                ),
                                items: PaymentMethod.values
                                    .map(
                                      (m) => DropdownMenuItem(
                                        value: m,
                                        child: Text(paymentMethodLabel(m)),
                                      ),
                                    )
                                    .toList(),
                                onChanged: _saving
                                    ? null
                                    : (value) {
                                        if (value == null) return;
                                        setState(() => paymentMethod = value);
                                      },
                              ),
                              DropdownButtonFormField<PaymentStatus>(
                                initialValue: paymentStatus,
                                decoration: const InputDecoration(
                                  labelText: 'Ödeme durumu',
                                ),
                                items: PaymentStatus.values
                                    .map(
                                      (s) => DropdownMenuItem(
                                        value: s,
                                        child: Text(paymentStatusLabel(s)),
                                      ),
                                    )
                                    .toList(),
                                onChanged: _saving
                                    ? null
                                    : (value) {
                                        if (value == null) return;
                                        setState(() => paymentStatus = value);
                                      },
                              ),
                              DropdownButtonFormField<InvoiceStatus>(
                                initialValue: invoiceStatus,
                                decoration: const InputDecoration(
                                  labelText: 'Fatura durumu',
                                ),
                                items: InvoiceStatus.values
                                    .map(
                                      (s) => DropdownMenuItem(
                                        value: s,
                                        child: Text(
                                          paymentInvoiceStatusLabel(s),
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: _saving
                                    ? null
                                    : (value) {
                                        if (value == null) return;
                                        setState(
                                          () => invoiceStatus = value,
                                        );
                                      },
                              ),
                              TextFormField(
                                initialValue: notes,
                                maxLines: 2,
                                decoration: const InputDecoration(
                                  labelText: 'Not',
                                ),
                                onSaved: (value) => notes = value?.trim() ?? '',
                              ),
                            ],
                          ),
                          if (_showSurgicalQuote) ...[
                            const SizedBox(height: AppSpacing.md),
                            FormSectionCard(
                              title: 'Cerrahi Teklif',
                              icon: Icons.medical_services_outlined,
                              children: [
                                TextFormField(
                                  controller: _quoteNoteCtrl,
                                  maxLines: 3,
                                  decoration: const InputDecoration(
                                    labelText: 'İşlem / teklif notu',
                                  ),
                                ),
                                TextFormField(
                                  controller: _quoteAmountCtrl,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  decoration: const InputDecoration(
                                    labelText: 'Teklif tutarı (opsiyonel)',
                                  ),
                                ),
                                DropdownButtonFormField<SurgicalQuoteCurrency>(
                                  initialValue: quoteCurrency,
                                  decoration: const InputDecoration(
                                    labelText: 'Para birimi',
                                  ),
                                  items: SurgicalQuoteCurrency.values
                                      .map(
                                        (c) => DropdownMenuItem(
                                          value: c,
                                          child: Text(c.label),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: _saving
                                      ? null
                                      : (value) {
                                          if (value == null) return;
                                          setState(
                                            () => quoteCurrency = value,
                                          );
                                        },
                                ),
                                Text(
                                  'Teklif tutarı boş bırakılırsa asistana fiyat verilmesi bildirimi gider.',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: AppSpacing.lg),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _saving ? null : _skipToDashboard,
                                  child: const Text('Vazgeç'),
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
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text('Kaydet ve bitir'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
