import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_session.dart';
import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/clinical_snack_bar.dart';
import '../../shared/widgets/clinical_form_scaffold.dart';
import '../../shared/widgets/form_section_card.dart';
import '../../shared/widgets/page_header.dart';
import '../patients/data/patient_selector_data_source.dart';
import '../patients/widgets/patient_selector_field.dart';
import 'data/radiology_order_encounter_prefill.dart';
import 'data/radiology_order_form_data_source.dart';
import 'models/radiology_order.dart';
import '../clinical_encounter/post_encounter_wizard/models/post_encounter_document_kind.dart';
import '../clinical_encounter/post_encounter_wizard/post_encounter_form_save_navigation.dart';

class RadiologyOrderFormScreen extends StatefulWidget {
  final String? patientId;
  final String? clinicalEncounterId;
  final String? orderId;
  final bool encounterWizardMode;

  const RadiologyOrderFormScreen({
    super.key,
    this.patientId,
    this.clinicalEncounterId,
    this.orderId,
    this.encounterWizardMode = false,
  });

  bool get isEditMode => orderId != null && orderId!.trim().isNotEmpty;

  @override
  State<RadiologyOrderFormScreen> createState() =>
      _RadiologyOrderFormScreenState();
}

class _ModalityDraft {
  bool enabled = false;
  final bodyRegion = TextEditingController();
  RadiologySide side = RadiologySide.belirtilmedi;
  final indication = TextEditingController();
  bool withContrast = false;
  final notes = TextEditingController();

  void dispose() {
    bodyRegion.dispose();
    indication.dispose();
    notes.dispose();
  }
}

class _RadiologyOrderFormScreenState extends State<RadiologyOrderFormScreen> {
  final _formKey = GlobalKey<FormState>();
  String? patientId;
  String? patientName;
  String? clinicalEncounterId;
  String? clinicalEncounterProtocolNumber;
  RadiologyOrderStatus status = RadiologyOrderStatus.taslak;
  RadiologyPriority priority = RadiologyPriority.rutin;
  final diagnosisCtrl = TextEditingController();
  final additionalNotesCtrl = TextEditingController();
  final Map<RadiologyModality, _ModalityDraft> _drafts = {
    for (final m in RadiologyModality.values) m: _ModalityDraft(),
  };
  bool _loaded = false;
  bool _saving = false;
  RadiologyOrder? _existing;

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

  Future<void> _initForm() async {
    if (widget.isEditMode) {
      final existing =
          await RadiologyOrderFormDataSource.loadForEdit(widget.orderId!);
      if (existing == null) {
        if (mounted) setState(() => _loaded = true);
        return;
      }
      _existing = existing;
      patientId = existing.patientId;
      patientName = existing.patientName;
      clinicalEncounterId = existing.clinicalEncounterId;
      clinicalEncounterProtocolNumber =
          existing.clinicalEncounterProtocolNumber;
      status = existing.status;
      priority = existing.priority;
      diagnosisCtrl.text = existing.diagnosis;
      additionalNotesCtrl.text = existing.additionalNotes ?? '';
      for (final line in existing.lines) {
        final draft = _drafts[line.modality]!;
        draft.enabled = true;
        draft.bodyRegion.text = line.bodyRegion;
        draft.side = line.side;
        draft.indication.text = line.clinicalIndication;
        draft.withContrast = line.withContrast;
        draft.notes.text = line.notes ?? '';
      }
    } else {
      final encounter =
          await RadiologyOrderEncounterPrefill.loadEncounter(clinicalEncounterId);
      if (encounter != null) {
        patientId ??= encounter.patientId;
        patientName ??= encounter.patientName;
        clinicalEncounterProtocolNumber ??=
            RadiologyOrderEncounterPrefill.protocolFromEncounter(encounter);
        if (diagnosisCtrl.text.trim().isEmpty) {
          diagnosisCtrl.text =
              RadiologyOrderEncounterPrefill.diagnosisFromEncounter(encounter);
        }
      }
      if (patientId != null && patientName == null) {
        final patient = await PatientSelectorDataSource.getById(patientId!);
        patientName = patient?.fullName;
      }
    }
    if (mounted) setState(() => _loaded = true);
  }

  @override
  void dispose() {
    diagnosisCtrl.dispose();
    additionalNotesCtrl.dispose();
    for (final draft in _drafts.values) {
      draft.dispose();
    }
    super.dispose();
  }

  List<RadiologyOrderLine> _buildLines() {
    final lines = <RadiologyOrderLine>[];
    for (final entry in _drafts.entries) {
      if (!entry.value.enabled) continue;
      lines.add(
        RadiologyOrderLine(
          modality: entry.key,
          bodyRegion: entry.value.bodyRegion.text.trim(),
          side: entry.value.side,
          clinicalIndication: entry.value.indication.text.trim(),
          withContrast: entry.value.withContrast,
          notes: entry.value.notes.text.trim().isEmpty
              ? null
              : entry.value.notes.text.trim(),
        ),
      );
    }
    return lines;
  }

  Future<void> _save() async {
    if (patientId == null || patientId!.trim().isEmpty) {
      showClinicalSnackBar(context, 'Lütfen hasta seçin.', isError: true);
      return;
    }
    final lines = _buildLines();
    if (lines.isEmpty) {
      showClinicalSnackBar(context, 'En az bir görüntüleme seçin.', isError: true);
      return;
    }
    for (final line in lines) {
      if (line.bodyRegion.trim().isEmpty || line.clinicalIndication.trim().isEmpty) {
        showClinicalSnackBar(
          context,
          '${radiologyModalityLabel(line.modality)} için bölge ve endikasyon zorunlu.',
          isError: true,
        );
        return;
      }
    }

    setState(() => _saving = true);
    final performer = AuthSession.currentUser?.displayName ?? 'Kullanıcı';
    final now = DateTime.now();
    final record = RadiologyOrder(
      id: _existing?.id ?? '',
      patientId: patientId!.trim(),
      patientName: patientName ?? 'Hasta',
      clinicalEncounterId: clinicalEncounterId,
      clinicalEncounterProtocolNumber: clinicalEncounterProtocolNumber,
      createdAt: _existing?.createdAt ?? now,
      updatedAt: now,
      createdBy: _existing?.createdBy ?? performer,
      status: status,
      priority: priority,
      diagnosis: diagnosisCtrl.text.trim(),
      lines: lines,
      additionalNotes: additionalNotesCtrl.text.trim().isEmpty
          ? null
          : additionalNotesCtrl.text.trim(),
    );

    try {
      final saved = widget.isEditMode
          ? await RadiologyOrderFormDataSource.update(record)
          : await RadiologyOrderFormDataSource.create(record);

      if (!mounted) return;
      setState(() => _saving = false);
      showClinicalSnackBar(context, 'Radyoloji istemi kaydedildi.');
      navigateAfterDocumentSave(
        context,
        encounterWizardMode: widget.encounterWizardMode,
        kind: PostEncounterDocumentKind.radiology,
        documentId: saved.id,
        detailPath: '/radiology-orders/${saved.id}',
      );
    } on RadiologyOrderFormException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showClinicalSnackBar(context, e.message, isError: true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      showClinicalSnackBar(
        context,
        'Radyoloji istemi kaydedilemedi.',
        isError: true,
      );
    }
  }

  Widget _modalitySection(RadiologyModality modality) {
    final draft = _drafts[modality]!;
    final showContrast =
        modality == RadiologyModality.mri || modality == RadiologyModality.bt;
    final isXRay = modality == RadiologyModality.xRay;

    return FormSectionCard(
      title: radiologyModalityLabel(modality),
      icon: Icons.medical_information_outlined,
      children: [
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('${radiologyModalityLabel(modality)} iste'),
          value: draft.enabled,
          onChanged: (v) => setState(() => draft.enabled = v ?? false),
        ),
        if (draft.enabled) ...[
          TextFormField(
            controller: draft.bodyRegion,
            decoration: InputDecoration(
              labelText: isXRay ? 'İstenen grafi' : 'Bölge / anatomik alan',
            ),
          ),
          DropdownButtonFormField<RadiologySide>(
            initialValue: draft.side,
            decoration: const InputDecoration(labelText: 'Taraf'),
            items: RadiologySide.values
                .map(
                  (s) => DropdownMenuItem(
                    value: s,
                    child: Text(radiologySideLabel(s)),
                  ),
                )
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => draft.side = v);
            },
          ),
          TextFormField(
            controller: draft.indication,
            decoration: InputDecoration(
              labelText: isXRay ? 'Klinik bilgi' : 'Klinik endikasyon',
            ),
            maxLines: 2,
          ),
          if (showContrast)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Kontrastlı çekim'),
              value: draft.withContrast,
              onChanged: (v) => setState(() => draft.withContrast = v ?? false),
            ),
          TextFormField(
            controller: draft.notes,
            decoration: const InputDecoration(labelText: 'Ek not'),
            maxLines: 2,
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const AppShell(
        title: 'Radyoloji İstemi',
        child: Center(child: CircularProgressIndicator.adaptive()),
      );
    }

    return ClinicalFormScaffold.sections(
      shellTitle:
          widget.isEditMode ? 'İstem Düzenle' : 'Yeni Radyoloji İstemi',
      onSave: _save,
      onCancel: () => context.pop(),
      saveLabel: widget.isEditMode ? 'Güncelle' : 'Kaydet',
      saving: _saving,
      formKey: _formKey,
      header: PageHeader(
        title: widget.isEditMode
            ? 'Radyoloji İstemi Düzenle'
            : 'Yeni Radyoloji İstemi',
        icon: Icons.radar_outlined,
        leadingBack: true,
        fallbackRoute: '/radiology-orders',
      ),
      sections: [
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
                              DropdownButtonFormField<RadiologyOrderStatus>(
                                initialValue: status,
                                decoration: const InputDecoration(labelText: 'Durum'),
                                items: RadiologyOrderStatus.values
                                    .map(
                                      (s) => DropdownMenuItem(
                                        value: s,
                                        child: Text(radiologyOrderStatusLabel(s)),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) {
                                  if (v != null) setState(() => status = v);
                                },
                              ),
                              DropdownButtonFormField<RadiologyPriority>(
                                initialValue: priority,
                                decoration: const InputDecoration(labelText: 'Öncelik'),
                                items: RadiologyPriority.values
                                    .map(
                                      (p) => DropdownMenuItem(
                                        value: p,
                                        child: Text(radiologyPriorityLabel(p)),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) {
                                  if (v != null) setState(() => priority = v);
                                },
                              ),
                            ],
                          ),
                          for (final modality in RadiologyModality.values)
                            _modalitySection(modality),
                          FormSectionCard(
                            title: 'Ek Notlar',
                            icon: Icons.notes_outlined,
                            children: [
                              TextFormField(
                                controller: additionalNotesCtrl,
                                maxLines: 3,
                                decoration: const InputDecoration(labelText: 'Not'),
                              ),
                            ],
                          ),
      ],
    );
  }
}
