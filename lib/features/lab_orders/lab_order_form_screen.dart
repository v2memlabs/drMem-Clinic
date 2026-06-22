import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_session.dart';
import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/clinical_form_scaffold.dart';
import '../../shared/widgets/clinical_snack_bar.dart';
import '../../shared/widgets/form_section_card.dart';
import '../../shared/widgets/page_header.dart';
import '../patients/data/patient_selector_data_source.dart';
import '../patients/widgets/patient_selector_field.dart';
import 'data/lab_order_encounter_prefill.dart';
import 'data/lab_order_form_data_source.dart';
import 'data/lab_order_template_lookup_data_source.dart';
import 'data/lab_test_selection.dart';
import 'models/lab_order.dart';
import 'models/lab_order_template.dart';
import 'models/lab_test_catalog.dart';
import '../clinical_encounter/post_encounter_wizard/models/post_encounter_document_kind.dart';
import '../clinical_encounter/post_encounter_wizard/post_encounter_form_save_navigation.dart';
import 'widgets/lab_test_selector.dart';

class LabOrderFormScreen extends StatefulWidget {
  final String? patientId;
  final String? clinicalEncounterId;
  final String? templateId;
  final String? orderId;
  final bool encounterWizardMode;

  const LabOrderFormScreen({
    super.key,
    this.patientId,
    this.clinicalEncounterId,
    this.templateId,
    this.orderId,
    this.encounterWizardMode = false,
  });

  bool get isEditMode => orderId != null && orderId!.trim().isNotEmpty;

  @override
  State<LabOrderFormScreen> createState() => _LabOrderFormScreenState();
}

class _LabOrderFormScreenState extends State<LabOrderFormScreen> {
  final _formKey = GlobalKey<FormState>();
  String? patientId;
  String? patientName;
  String? clinicalEncounterId;
  String? clinicalEncounterProtocolNumber;
  LabOrderStatus status = LabOrderStatus.taslak;
  LabOrderReason orderReason = LabOrderReason.preoperatifHazirlik;
  final diagnosisCtrl = TextEditingController();
  final infectionNotesCtrl = TextEditingController();
  final preopNotesCtrl = TextEditingController();
  final ekgNotesCtrl = TextEditingController();
  final additionalNotesCtrl = TextEditingController();
  final Set<LabTestCode> _selectedTests = {};
  final Set<String> _selectedCustomTestIds = {};
  InfectionContext infectionContext = InfectionContext.yok;
  String? _appliedTemplateId;
  String? _appliedTemplateName;
  bool _loaded = false;
  bool _saving = false;
  LabOrder? _existing;
  List<LabOrderTemplate> _templates = const [];

  bool get _lockPatient =>
      widget.patientId?.trim().isNotEmpty == true ||
      clinicalEncounterId?.trim().isNotEmpty == true;

  @override
  void initState() {
    super.initState();
    patientId = widget.patientId?.trim();
    clinicalEncounterId = widget.clinicalEncounterId?.trim();
    _initForm();
  }

  Future<void> _applyTemplate(String? templateId) async {
    if (templateId == null || templateId.isEmpty) return;
    final template = await LabOrderTemplateLookupDataSource.findById(templateId);
    if (template == null || !mounted) return;
    setState(() {
      _appliedTemplateId = template.id;
      _appliedTemplateName = template.name;
      _selectedTests
        ..clear()
        ..addAll(LabTestSelection.expandForEditing(template.selectedTests));
      _selectedCustomTestIds
        ..clear()
        ..addAll(template.selectedCustomTestIds);
      orderReason = template.defaultOrderReason;
      if (diagnosisCtrl.text.trim().isEmpty &&
          (template.defaultDiagnosis?.trim().isNotEmpty ?? false)) {
        diagnosisCtrl.text = template.defaultDiagnosis!.trim();
      }
      infectionContext = template.defaultInfectionContext;
      if (template.preoperativeNotes?.trim().isNotEmpty ?? false) {
        preopNotesCtrl.text = template.preoperativeNotes!.trim();
      }
      if (template.ekgNotes?.trim().isNotEmpty ?? false) {
        ekgNotesCtrl.text = template.ekgNotes!.trim();
      }
      if (template.additionalNotes?.trim().isNotEmpty ?? false) {
        additionalNotesCtrl.text = template.additionalNotes!.trim();
      }
    });
  }

  Future<void> _initForm() async {
    _templates = await LabOrderTemplateLookupDataSource.listAll();

    if (widget.isEditMode) {
      final existing = await LabOrderFormDataSource.loadForEdit(widget.orderId!);
      if (existing == null) {
        if (mounted) setState(() => _loaded = true);
        return;
      }
      _existing = existing;
      patientId = existing.patientId;
      patientName = existing.patientName;
      clinicalEncounterId = existing.clinicalEncounterId;
      clinicalEncounterProtocolNumber = existing.clinicalEncounterProtocolNumber;
      status = existing.status;
      orderReason = existing.orderReason;
      diagnosisCtrl.text = existing.diagnosis;
      _selectedTests.addAll(LabTestSelection.expandForEditing(existing.selectedTests));
      _selectedCustomTestIds.addAll(existing.selectedCustomTestIds);
      infectionContext = existing.infectionContext;
      infectionNotesCtrl.text = existing.infectionNotes ?? '';
      preopNotesCtrl.text = existing.preoperativeNotes ?? '';
      ekgNotesCtrl.text = existing.ekgNotes ?? '';
      additionalNotesCtrl.text = existing.additionalNotes ?? '';
      _appliedTemplateId = existing.templateId;
      _appliedTemplateName = existing.templateName;
    } else {
      final encounter = await LabOrderEncounterPrefill.loadEncounter(clinicalEncounterId);
      if (encounter != null) {
        patientId ??= encounter.patientId;
        patientName ??= encounter.patientName;
        clinicalEncounterProtocolNumber ??=
            LabOrderEncounterPrefill.protocolFromEncounter(encounter);
        if (diagnosisCtrl.text.trim().isEmpty) {
          diagnosisCtrl.text =
              LabOrderEncounterPrefill.diagnosisFromEncounter(encounter);
        }
      }
      if (patientId != null && patientName == null) {
        final patient = await PatientSelectorDataSource.getById(patientId!);
        patientName = patient?.fullName;
      }
      await _applyTemplate(widget.templateId);
    }
    if (mounted) setState(() => _loaded = true);
  }

  @override
  void dispose() {
    diagnosisCtrl.dispose();
    infectionNotesCtrl.dispose();
    preopNotesCtrl.dispose();
    ekgNotesCtrl.dispose();
    additionalNotesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (patientId == null || patientId!.trim().isEmpty) {
      showClinicalSnackBar(context, 'Lütfen hasta seçin.', isError: true);
      return;
    }
    if (_selectedTests.isEmpty && _selectedCustomTestIds.isEmpty) {
      showClinicalSnackBar(context, 'En az bir tahlil seçin.', isError: true);
      return;
    }

    setState(() => _saving = true);
    final performer = AuthSession.currentUser?.displayName ?? 'Kullanıcı';
    final now = DateTime.now();

    String? protocolNumber = clinicalEncounterProtocolNumber?.trim();
    if ((protocolNumber == null || protocolNumber.isEmpty) &&
        clinicalEncounterId != null &&
        clinicalEncounterId!.trim().isNotEmpty) {
      final encounter = await LabOrderEncounterPrefill.loadEncounter(
        clinicalEncounterId,
      );
      protocolNumber =
          LabOrderEncounterPrefill.protocolFromEncounter(encounter);
    }
    if (protocolNumber != null && protocolNumber.isEmpty) {
      protocolNumber = null;
    }

    final record = LabOrder(
      id: _existing?.id ?? '',
      patientId: patientId!.trim(),
      patientName: patientName ?? 'Hasta',
      clinicalEncounterId: clinicalEncounterId,
      clinicalEncounterProtocolNumber: protocolNumber,
      createdAt: _existing?.createdAt ?? now,
      updatedAt: now,
      createdBy: _existing?.createdBy ?? performer,
      status: status,
      diagnosis: diagnosisCtrl.text.trim(),
      orderReason: orderReason,
      selectedTests:
          LabTestSelection.normalizeForStorage(_selectedTests),
      selectedCustomTestIds: _selectedCustomTestIds.toList(),
      infectionContext: infectionContext,
      infectionNotes: infectionNotesCtrl.text.trim().isEmpty
          ? null
          : infectionNotesCtrl.text.trim(),
      preoperativeNotes: preopNotesCtrl.text.trim().isEmpty
          ? null
          : preopNotesCtrl.text.trim(),
      ekgNotes: ekgNotesCtrl.text.trim().isEmpty ? null : ekgNotesCtrl.text.trim(),
      additionalNotes: additionalNotesCtrl.text.trim().isEmpty
          ? null
          : additionalNotesCtrl.text.trim(),
      templateId: _appliedTemplateId,
      templateName: _appliedTemplateName,
    );

    try {
      final saved = widget.isEditMode
          ? await LabOrderFormDataSource.update(record)
          : await LabOrderFormDataSource.create(record);

      if (!mounted) return;
      setState(() => _saving = false);
      showClinicalSnackBar(context, 'Laboratuvar istemi kaydedildi.');
      navigateAfterDocumentSave(
        context,
        encounterWizardMode: widget.encounterWizardMode,
        kind: PostEncounterDocumentKind.lab,
        documentId: saved.id,
        detailPath: '/lab-orders/${saved.id}',
      );
    } on LabOrderFormException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showClinicalSnackBar(context, e.message, isError: true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      showClinicalSnackBar(
        context,
        'Laboratuvar istemi kaydedilemedi.',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const AppShell(
        title: 'Laboratuvar İstemi',
        child: Center(child: CircularProgressIndicator.adaptive()),
      );
    }

    final templates = _templates;

    return ClinicalFormScaffold.sections(
      shellTitle:
          widget.isEditMode ? 'İstem Düzenle' : 'Yeni Laboratuvar İstemi',
      onSave: _save,
      onCancel: () => context.pop(),
      saveLabel: widget.isEditMode ? 'Güncelle' : 'Kaydet',
      saving: _saving,
      formKey: _formKey,
      header: PageHeader(
        title: widget.isEditMode
            ? 'Laboratuvar İstemi Düzenle'
            : 'Yeni Laboratuvar İstemi',
        icon: Icons.biotech_outlined,
        leadingBack: true,
        fallbackRoute: '/lab-orders',
      ),
      sections: [
                          if (templates.isNotEmpty)
                            FormSectionCard(
                              title: 'Şablon',
                              icon: Icons.library_books_outlined,
                              children: [
                                DropdownButtonFormField<String?>(
                                  initialValue: _appliedTemplateId,
                                  decoration: const InputDecoration(
                                    labelText: 'Şablon uygula',
                                  ),
                                  items: [
                                    const DropdownMenuItem(
                                      value: null,
                                      child: Text('Şablon seçilmedi'),
                                    ),
                                    ...templates.map(
                                      (t) => DropdownMenuItem(
                                        value: t.id,
                                        child: Text(t.name),
                                      ),
                                    ),
                                  ],
                                  onChanged: (v) => _applyTemplate(v),
                                ),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: TextButton.icon(
                                    onPressed: () =>
                                        context.push('/lab-order-templates'),
                                    icon: const Icon(Icons.settings_outlined, size: 18),
                                    label: const Text('Şablonları yönet'),
                                  ),
                                ),
                              ],
                            ),
                          FormSectionCard(
                            title: 'Hasta ve Tanı',
                            icon: Icons.person_outline,
                            children: [
                              PatientSelectorField(
                                selectedPatientId: patientId,
                                lockSelection: _lockPatient,
                                onChanged: (v) => setState(() => patientId = v),
                                onPatientSelected: (p) => setState(() {
                                  patientId = p?.id;
                                  patientName = p?.fullName;
                                }),
                              ),
                              if (clinicalEncounterProtocolNumber != null &&
                                  clinicalEncounterProtocolNumber!
                                      .trim()
                                      .isNotEmpty) ...[
                                const SizedBox(height: 12),
                                InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'Muayene protokol no',
                                    isDense: true,
                                  ),
                                  child: Text(
                                    clinicalEncounterProtocolNumber!.trim(),
                                    style:
                                        Theme.of(context).textTheme.bodyLarge,
                                  ),
                                ),
                              ],
                              TextFormField(
                                controller: diagnosisCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Ön Tanı / Tanı',
                                ),
                                maxLines: 2,
                              ),
                              DropdownButtonFormField<LabOrderReason>(
                                initialValue: orderReason,
                                decoration: const InputDecoration(
                                  labelText: 'İstem sebebi',
                                ),
                                items: LabOrderReason.values
                                    .map(
                                      (r) => DropdownMenuItem(
                                        value: r,
                                        child: Text(labOrderReasonLabel(r)),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) {
                                  if (v != null) setState(() => orderReason = v);
                                },
                              ),
                              DropdownButtonFormField<LabOrderStatus>(
                                initialValue: status,
                                decoration: const InputDecoration(labelText: 'Durum'),
                                items: LabOrderStatus.values
                                    .map(
                                      (s) => DropdownMenuItem(
                                        value: s,
                                        child: Text(labOrderStatusLabel(s)),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) {
                                  if (v != null) setState(() => status = v);
                                },
                              ),
                            ],
                          ),
                          FormSectionCard(
                            title: 'Enfeksiyon bağlamı',
                            icon: Icons.coronavirus_outlined,
                            children: [
                              DropdownButtonFormField<InfectionContext>(
                                initialValue: infectionContext,
                                decoration: const InputDecoration(
                                  labelText: 'Ön tanı / bağlam',
                                ),
                                items: InfectionContext.values
                                    .map(
                                      (c) => DropdownMenuItem(
                                        value: c,
                                        child: Text(infectionContextLabel(c)),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) {
                                  if (v != null) setState(() => infectionContext = v);
                                },
                              ),
                              TextFormField(
                                controller: infectionNotesCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Enfeksiyon notu',
                                ),
                                maxLines: 2,
                              ),
                            ],
                          ),
                          LabTestSelector(
                            selectedTests: _selectedTests,
                            selectedCustomTestIds: _selectedCustomTestIds,
                            onTestsChanged: (next) =>
                                setState(() => _selectedTests..clear()..addAll(next)),
                            onCustomTestsChanged: (next) => setState(() {
                              _selectedCustomTestIds
                                ..clear()
                                ..addAll(next);
                            }),
                          ),
                          FormSectionCard(
                            title: 'Ek notlar',
                            icon: Icons.notes_outlined,
                            children: [
                              TextFormField(
                                controller: preopNotesCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Preoperatif not',
                                ),
                                maxLines: 2,
                              ),
                              TextFormField(
                                controller: ekgNotesCtrl,
                                decoration: const InputDecoration(labelText: 'EKG notu'),
                                maxLines: 2,
                              ),
                              TextFormField(
                                controller: additionalNotesCtrl,
                                decoration: const InputDecoration(labelText: 'Genel not'),
                                maxLines: 2,
                              ),
                            ],
                          ),
      ],
    );
  }
}
