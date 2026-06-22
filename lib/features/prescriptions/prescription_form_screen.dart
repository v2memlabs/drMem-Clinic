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
import 'data/prescription_encounter_prefill.dart';
import 'data/prescription_form_data_source.dart';
import 'data/prescription_list_refresh.dart';
import 'models/prescription.dart';
import '../clinical_encounter/post_encounter_wizard/models/post_encounter_document_kind.dart';
import '../clinical_encounter/post_encounter_wizard/post_encounter_form_save_navigation.dart';

class PrescriptionFormScreen extends StatefulWidget {
  final String? patientId;
  final String? clinicalEncounterId;
  final String? prescriptionId;
  final bool encounterWizardMode;

  const PrescriptionFormScreen({
    super.key,
    this.patientId,
    this.clinicalEncounterId,
    this.prescriptionId,
    this.encounterWizardMode = false,
  });

  bool get isEditMode =>
      prescriptionId != null && prescriptionId!.trim().isNotEmpty;

  @override
  State<PrescriptionFormScreen> createState() => _PrescriptionFormScreenState();
}

class _MedicationDraft {
  final TextEditingController name = TextEditingController();
  final TextEditingController boxCount = TextEditingController();
  final TextEditingController dose = TextEditingController();
  final TextEditingController frequency = TextEditingController();
  final TextEditingController duration = TextEditingController();
  final TextEditingController notes = TextEditingController();

  void dispose() {
    name.dispose();
    boxCount.dispose();
    dose.dispose();
    frequency.dispose();
    duration.dispose();
    notes.dispose();
  }
}

class _PrescriptionFormScreenState extends State<PrescriptionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  String? patientId;
  String? patientName;
  String? clinicalEncounterId;
  PrescriptionStatus status = PrescriptionStatus.taslak;
  final diagnosisCtrl = TextEditingController();
  final additionalNotesCtrl = TextEditingController();
  final List<_MedicationDraft> _medications = [_MedicationDraft()];
  bool _loaded = false;
  bool _saving = false;
  Prescription? _existing;

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
          await PrescriptionFormDataSource.loadForEdit(widget.prescriptionId!);
      if (existing == null) {
        if (mounted) setState(() => _loaded = true);
        return;
      }
      _existing = existing;
      patientId = existing.patientId;
      patientName = existing.patientName;
      clinicalEncounterId = existing.clinicalEncounterId;
      status = existing.status;
      diagnosisCtrl.text = existing.diagnosis;
      additionalNotesCtrl.text = existing.additionalNotes ?? '';
      _medications.clear();
      for (final med in existing.medications) {
        final draft = _MedicationDraft();
        draft.name.text = med.name;
        draft.dose.text = med.dose;
        draft.frequency.text = med.frequency;
        draft.duration.text = med.duration;
        draft.notes.text = med.notes ?? '';
        _medications.add(draft);
      }
      if (_medications.isEmpty) _medications.add(_MedicationDraft());
    } else {
      final encounter =
          await PrescriptionEncounterPrefill.loadEncounter(clinicalEncounterId);
      if (encounter != null) {
        patientId ??= encounter.patientId;
        patientName ??= encounter.patientName;
        if (diagnosisCtrl.text.trim().isEmpty) {
          diagnosisCtrl.text =
              PrescriptionEncounterPrefill.diagnosisFromEncounter(encounter);
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
    for (final med in _medications) {
      med.dispose();
    }
    super.dispose();
  }

  void _addMedication() {
    setState(() => _medications.add(_MedicationDraft()));
  }

  void _removeMedication(int index) {
    if (_medications.length <= 1) return;
    setState(() {
      _medications[index].dispose();
      _medications.removeAt(index);
    });
  }

  List<PrescriptionMedication> _buildMedications() {
    return _medications
        .map(
          (draft) {
            final parsedBox = int.tryParse(draft.boxCount.text.trim());
            return PrescriptionMedication(
              name: draft.name.text.trim(),
              dose: draft.dose.text.trim(),
              frequency: draft.frequency.text.trim(),
              duration: draft.duration.text.trim(),
              notes: draft.notes.text.trim().isEmpty ? null : draft.notes.text.trim(),
              boxCount: parsedBox != null && parsedBox > 0 ? parsedBox : null,
            );
          },
        )
        .where((m) => m.name.isNotEmpty)
        .toList();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (patientId == null || patientId!.trim().isEmpty) {
      showClinicalSnackBar(context, 'Lütfen hasta seçin.', isError: true);
      return;
    }

    final meds = _buildMedications();
    if (meds.isEmpty) {
      showClinicalSnackBar(context, 'En az bir ilaç satırı girin.', isError: true);
      return;
    }

    setState(() => _saving = true);
    final performer = AuthSession.currentUser?.displayName ?? 'Hekim';
    final now = DateTime.now();
    final record = Prescription(
      id: _existing?.id ?? '',
      patientId: patientId!.trim(),
      patientName: patientName ?? 'Hasta',
      clinicalEncounterId: clinicalEncounterId,
      createdAt: _existing?.createdAt ?? now,
      updatedAt: now,
      createdBy: _existing?.createdBy ?? performer,
      status: status,
      diagnosis: diagnosisCtrl.text.trim(),
      medications: meds,
      additionalNotes: additionalNotesCtrl.text.trim().isEmpty
          ? null
          : additionalNotesCtrl.text.trim(),
    );

    try {
      final saved = widget.isEditMode
          ? await PrescriptionFormDataSource.update(record)
          : await PrescriptionFormDataSource.create(record);

      if (!mounted) return;
      setState(() => _saving = false);
      showClinicalSnackBar(context, 'Reçete kaydedildi.');
      navigateAfterDocumentSave(
        context,
        encounterWizardMode: widget.encounterWizardMode,
        kind: PostEncounterDocumentKind.prescription,
        documentId: saved.id,
        detailPath: '/prescriptions/${saved.id}',
      );
    } on PrescriptionFormException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showClinicalSnackBar(context, e.message, isError: true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      showClinicalSnackBar(
        context,
        'Reçete kaydedilemedi.',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const AppShell(
        title: 'Reçete',
        child: Center(child: CircularProgressIndicator.adaptive()),
      );
    }

    if (widget.isEditMode && _existing == null) {
      return AppShell(
        title: 'Reçete',
        child: Center(
          child: Text(
            'Reçete kaydı bulunamadı.',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      );
    }

    return ClinicalFormScaffold.sections(
      shellTitle: widget.isEditMode ? 'Reçete Düzenle' : 'Yeni Reçete',
      onSave: _save,
      onCancel: () => context.pop(),
      saveLabel: widget.isEditMode ? 'Güncelle' : 'Kaydet',
      saving: _saving,
      formKey: _formKey,
      header: PageHeader(
        title: widget.isEditMode ? 'Reçete Düzenle' : 'Yeni Reçete',
        icon: Icons.medication_outlined,
        leadingBack: true,
        fallbackRoute: '/prescriptions',
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
                              TextFormField(
                                controller: diagnosisCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Ön Tanı / Tanı',
                                ),
                                maxLines: 2,
                              ),
                              DropdownButtonFormField<PrescriptionStatus>(
                                initialValue: status,
                                decoration: const InputDecoration(labelText: 'Durum'),
                                items: PrescriptionStatus.values
                                    .map(
                                      (s) => DropdownMenuItem(
                                        value: s,
                                        child: Text(prescriptionStatusLabel(s)),
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
                            title: 'İlaçlar',
                            icon: Icons.medication_outlined,
                            children: [
                              for (var i = 0; i < _medications.length; i++) ...[
                                if (i > 0) const Divider(height: 24),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'İlaç ${i + 1}',
                                        style: Theme.of(context).textTheme.titleSmall,
                                      ),
                                    ),
                                    if (_medications.length > 1)
                                      IconButton(
                                        tooltip: 'Satırı kaldır',
                                        onPressed: () => _removeMedication(i),
                                        icon: const Icon(Icons.delete_outline),
                                      ),
                                  ],
                                ),
                                TextFormField(
                                  controller: _medications[i].name,
                                  decoration: const InputDecoration(labelText: 'İlaç adı'),
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty) ? 'Zorunlu' : null,
                                ),
                                TextFormField(
                                  controller: _medications[i].boxCount,
                                  decoration: const InputDecoration(
                                    labelText: 'Kutu sayısı',
                                    hintText: 'ör. 2',
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                                TextFormField(
                                  controller: _medications[i].dose,
                                  decoration: const InputDecoration(
                                    labelText: 'Doz (opsiyonel)',
                                    hintText: 'D satırı için serbest metin',
                                  ),
                                ),
                                TextFormField(
                                  controller: _medications[i].frequency,
                                  decoration: const InputDecoration(
                                    labelText: 'S: kullanım',
                                    hintText: 'ör. 3 x 1',
                                  ),
                                ),
                                TextFormField(
                                  controller: _medications[i].duration,
                                  decoration: const InputDecoration(
                                    labelText: 'Süre',
                                    hintText: 'ör. 7 gün',
                                  ),
                                ),
                                TextFormField(
                                  controller: _medications[i].notes,
                                  decoration: const InputDecoration(labelText: 'Not'),
                                  maxLines: 2,
                                ),
                              ],
                              OutlinedButton.icon(
                                onPressed: _addMedication,
                                icon: const Icon(Icons.add_rounded, size: 18),
                                label: const Text('İlaç Ekle'),
                              ),
                            ],
                          ),
                          FormSectionCard(
                            title: 'Ek Notlar',
                            icon: Icons.notes_outlined,
                            children: [
                              TextFormField(
                                controller: additionalNotesCtrl,
                                maxLines: 4,
                                decoration: const InputDecoration(
                                  labelText: 'Hekim notu / uyarı',
                                ),
                              ),
                            ],
                          ),
      ],
    );
  }
}
