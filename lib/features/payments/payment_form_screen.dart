import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_session.dart';
import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/clinical_snack_bar.dart';
import '../../shared/widgets/clinical_form_scaffold.dart';
import '../../shared/widgets/form_section_card.dart';
import '../../shared/widgets/page_header.dart';
import '../patients/data/patient_lookup_data_source.dart';
import '../patients/widgets/patient_selector_field.dart';
import 'data/payment_form_data_source.dart';
import 'data/payment_list_refresh.dart';
import 'data/payment_service_type_catalog.dart';
import 'models/payment_record.dart';
import 'models/payment_rehab_billing_mode.dart';
import 'widgets/payment_ui_helpers.dart';

class PaymentFormScreen extends StatefulWidget {
  final String? patientId;
  final String? paymentId;

  const PaymentFormScreen({
    super.key,
    this.patientId,
    this.paymentId,
  });

  bool get isEditMode => paymentId != null && paymentId!.trim().isNotEmpty;

  @override
  State<PaymentFormScreen> createState() => _PaymentFormScreenState();
}

class _PaymentFormScreenState extends State<PaymentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedPatientId;
  String? _selectedPatientName;
  String? patientName;
  ServiceType serviceType = ServiceType.muayene;
  PaymentRehabBillingMode? rehabBillingMode;
  int? packageSessionCount;
  double totalAmount = 0;
  double paidAmount = 0;
  PaymentMethod paymentMethod = PaymentMethod.belirtilmedi;
  PaymentStatus paymentStatus = PaymentStatus.bekliyor;
  InvoiceStatus invoiceStatus = InvoiceStatus.belirtilmedi;
  DateTime transactionDate = DateTime.now();
  String notes = '';
  String? _existingId;
  String? _createdByUserId;
  bool _loading = false;
  late bool _loaded;

  List<ServiceType> get _serviceTypes =>
      PaymentServiceTypeCatalog.allowedForCurrentUser();

  bool get _showRehabOptions => serviceType == ServiceType.rehabilitasyon;

  @override
  void initState() {
    super.initState();
    _loaded = !widget.isEditMode;
    if (_serviceTypes.isNotEmpty &&
        !_serviceTypes.contains(serviceType)) {
      serviceType = _serviceTypes.first;
    }
    if (widget.isEditMode) {
      _loadExisting();
    } else if (widget.patientId != null && widget.patientId!.isNotEmpty) {
      _applyPatient(widget.patientId!);
    }
  }

  Future<void> _loadExisting() async {
    setState(() => _loading = true);
    final existing =
        await PaymentFormDataSource.loadForEdit(widget.paymentId!.trim());
    if (!mounted) return;
    if (existing == null) {
      setState(() => _loading = false);
      showClinicalSnackBar(context, 'Ödeme kaydı bulunamadı.', isError: true);
      context.pop();
      return;
    }

    setState(() {
      _existingId = existing.id;
      _createdByUserId = existing.createdByUserId;
      _selectedPatientId = existing.patientId;
      patientName = existing.patientName;
      _selectedPatientName = existing.patientName;
      serviceType = existing.serviceType;
      rehabBillingMode = existing.rehabBillingMode;
      packageSessionCount = existing.packageSessionCount;
      totalAmount = existing.totalAmount;
      paidAmount = existing.paidAmount;
      paymentMethod = existing.paymentMethod;
      paymentStatus = existing.paymentStatus;
      invoiceStatus = existing.invoiceStatus;
      transactionDate = existing.transactionDate;
      notes = existing.notes;
      _loading = false;
      _loaded = true;
    });
  }

  Future<void> _applyPatient(String? id) async {
    if (id == null || id.isEmpty) {
      setState(() {
        _selectedPatientId = null;
        _selectedPatientName = null;
        patientName = null;
      });
      return;
    }
    _selectedPatientId = id;
    final patient = await PatientLookupDataSource.findById(id);
    if (!mounted) return;
    setState(() {
      if (patient != null) {
        _selectedPatientName = patient.fullName;
        patientName = patient.fullName;
      }
    });
  }

  PaymentRecord _buildRecord() {
    final pid = _selectedPatientId ?? widget.patientId ?? 'unknown';
    final pname = patientName ?? _selectedPatientName ?? 'Hasta';
    final performer = AuthSession.currentUser?.displayName ?? 'Kullanıcı';

    return PaymentRecord(
      id: _existingId ?? 'pay-${DateTime.now().millisecondsSinceEpoch}',
      patientId: pid,
      patientName: pname,
      createdAt: DateTime.now(),
      serviceType: serviceType,
      totalAmount: totalAmount,
      paidAmount: paidAmount,
      paymentMethod: paymentMethod,
      paymentStatus: paymentStatus,
      invoiceStatus: invoiceStatus,
      transactionDate: transactionDate,
      recordedBy: performer,
      notes: notes,
      rehabBillingMode: _showRehabOptions ? rehabBillingMode : null,
      packageSessionCount: _showRehabOptions &&
              rehabBillingMode == PaymentRehabBillingMode.paket
          ? packageSessionCount
          : null,
      createdByUserId: _createdByUserId ?? AuthSession.currentUser?.id,
    );
  }

  Future<void> save() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    if (_showRehabOptions && rehabBillingMode == null) {
      showClinicalSnackBar(
        context,
        'Rehabilitasyon için seans tipi seçin.',
        isError: true,
      );
      return;
    }
    if (_showRehabOptions &&
        rehabBillingMode == PaymentRehabBillingMode.paket &&
        (packageSessionCount == null || packageSessionCount! <= 0)) {
      showClinicalSnackBar(
        context,
        'Paket için seans sayısı girin.',
        isError: true,
      );
      return;
    }

    final record = _buildRecord();
    final result = widget.isEditMode
        ? await PaymentFormDataSource.update(record)
        : await PaymentFormDataSource.add(record);

    if (!mounted) return;
    if (result.hasError) {
      showClinicalSnackBar(context, result.errorMessage!, isError: true);
      return;
    }

    PaymentListRefresh.markStale();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.isEditMode ? 'Kayıt güncellendi.' : 'Kayıt kaydedildi.'),
      ),
    );
    if (widget.isEditMode) {
      context.pop();
    } else {
      context.push(
        '/payments${widget.patientId != null ? '?patientId=${widget.patientId}' : ''}',
      );
    }
  }

  void _cancel() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.push('/payments');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || !_loaded) {
      return const AppShell(
        title: 'Ödeme',
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return ClinicalFormScaffold.sections(
      shellTitle:
          widget.isEditMode ? 'Ödeme Düzenle' : 'Yeni Ödeme Kaydı',
      onSave: save,
      onCancel: _cancel,
      saveLabel: widget.isEditMode ? 'Güncelle' : 'Kaydet',
      formKey: _formKey,
      header: PageHeader(
        title: widget.isEditMode ? 'Ödeme Düzenle' : 'Yeni Ödeme',
        icon: Icons.payments_outlined,
        leadingBack: true,
        fallbackRoute: '/payments',
      ),
      sections: [
                          if (!widget.isEditMode)
                            FormSectionCard(
                              title: 'Hasta Bilgisi',
                              icon: Icons.person_outline,
                              children: [
                                PatientSelectorField(
                                  selectedPatientId: _selectedPatientId,
                                  isDense: true,
                                  onChanged: _applyPatient,
                                  onPatientSelected: (p) {
                                    setState(() {
                                      _selectedPatientId = p?.id;
                                      _selectedPatientName = p?.fullName;
                                      patientName = p?.fullName;
                                    });
                                  },
                                ),
                              ],
                            ),
                          FormSectionCard(
                            title: 'Ödeme Bilgisi',
                            icon: Icons.payments_outlined,
                            children: [
                              DropdownButtonFormField<ServiceType>(
                                initialValue: _serviceTypes.contains(serviceType)
                                    ? serviceType
                                    : _serviceTypes.first,
                                decoration: const InputDecoration(
                                  labelText: 'Hizmet Tipi',
                                  isDense: true,
                                ),
                                isExpanded: true,
                                items: _serviceTypes
                                    .map(
                                      (s) => DropdownMenuItem(
                                        value: s,
                                        child: Text(
                                          paymentServiceTypeLabel(s),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) => setState(() {
                                  serviceType = v!;
                                  if (serviceType != ServiceType.rehabilitasyon) {
                                    rehabBillingMode = null;
                                    packageSessionCount = null;
                                  }
                                }),
                              ),
                              if (_showRehabOptions) ...[
                                DropdownButtonFormField<PaymentRehabBillingMode>(
                                  initialValue: rehabBillingMode,
                                  decoration: const InputDecoration(
                                    labelText: 'Rehabilitasyon tipi',
                                    isDense: true,
                                  ),
                                  isExpanded: true,
                                  items: PaymentRehabBillingMode.values
                                      .map(
                                        (m) => DropdownMenuItem(
                                          value: m,
                                          child: Text(
                                            paymentRehabBillingModeLabel(m),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (v) => setState(() {
                                    rehabBillingMode = v;
                                    if (v != PaymentRehabBillingMode.paket) {
                                      packageSessionCount = null;
                                    }
                                  }),
                                ),
                                if (rehabBillingMode ==
                                    PaymentRehabBillingMode.paket)
                                  TextFormField(
                                    initialValue: packageSessionCount?.toString(),
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Paket seans sayısı',
                                      isDense: true,
                                    ),
                                    validator: (v) {
                                      if (rehabBillingMode !=
                                          PaymentRehabBillingMode.paket) {
                                        return null;
                                      }
                                      final n = int.tryParse(v ?? '');
                                      if (n == null || n <= 0) {
                                        return 'Seans sayısı girin';
                                      }
                                      return null;
                                    },
                                    onSaved: (v) =>
                                        packageSessionCount = int.tryParse(v ?? ''),
                                  ),
                              ],
                              TextFormField(
                                initialValue: totalAmount == 0
                                    ? ''
                                    : totalAmount.toString(),
                                keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                decoration: const InputDecoration(
                                  labelText: 'Toplam Tutar (TL)',
                                  isDense: true,
                                ),
                                validator: (v) =>
                                    (v == null || v.isEmpty) ? 'Toplam tutar girin' : null,
                                onSaved: (v) =>
                                    totalAmount = double.tryParse(v ?? '0') ?? 0,
                              ),
                              TextFormField(
                                initialValue:
                                    paidAmount == 0 ? '' : paidAmount.toString(),
                                keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                decoration: const InputDecoration(
                                  labelText: 'Ödenen Tutar (TL)',
                                  isDense: true,
                                ),
                                onSaved: (v) =>
                                    paidAmount = double.tryParse(v ?? '0') ?? 0,
                              ),
                              DropdownButtonFormField<PaymentMethod>(
                                initialValue: paymentMethod,
                                decoration: const InputDecoration(
                                  labelText: 'Ödeme Yöntemi',
                                  isDense: true,
                                ),
                                isExpanded: true,
                                items: PaymentMethod.values
                                    .map(
                                      (s) => DropdownMenuItem(
                                        value: s,
                                        child: Text(
                                          paymentMethodLabel(s),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) => setState(() => paymentMethod = v!),
                              ),
                              DropdownButtonFormField<PaymentStatus>(
                                initialValue: paymentStatus,
                                decoration: const InputDecoration(
                                  labelText: 'Ödeme Durumu',
                                  isDense: true,
                                ),
                                isExpanded: true,
                                items: PaymentStatus.values
                                    .map(
                                      (s) => DropdownMenuItem(
                                        value: s,
                                        child: Text(
                                          paymentStatusLabel(s),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) => setState(() => paymentStatus = v!),
                              ),
                              DropdownButtonFormField<InvoiceStatus>(
                                initialValue: invoiceStatus,
                                decoration: const InputDecoration(
                                  labelText: 'Fatura Durumu',
                                  isDense: true,
                                ),
                                isExpanded: true,
                                items: InvoiceStatus.values
                                    .map(
                                      (s) => DropdownMenuItem(
                                        value: s,
                                        child: Text(
                                          paymentInvoiceStatusLabel(s),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) => setState(() => invoiceStatus = v!),
                              ),
                              TextFormField(
                                decoration: const InputDecoration(
                                  labelText: 'İşlem Tarihi (YYYY-MM-DD)',
                                  isDense: true,
                                ),
                                initialValue: transactionDate
                                    .toLocal()
                                    .toString()
                                    .split(' ')
                                    .first,
                                onSaved: (v) {
                                  if (v != null && v.isNotEmpty) {
                                    transactionDate =
                                        DateTime.tryParse(v) ?? DateTime.now();
                                  }
                                },
                              ),
                            ],
                          ),
                          FormSectionCard(
                            title: 'Açıklama / Not',
                            children: [
                              TextFormField(
                                initialValue: notes,
                                decoration: const InputDecoration(
                                  labelText: 'Notlar',
                                  alignLabelWithHint: true,
                                  isDense: true,
                                ),
                                maxLines: 4,
                                onSaved: (v) => notes = v ?? '',
                              ),
                            ],
                          ),
      ],
    );
  }
}
