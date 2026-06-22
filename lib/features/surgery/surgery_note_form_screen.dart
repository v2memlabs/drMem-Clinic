import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_spacing.dart';
import 'data/surgery_note_ownership.dart';
import 'data/surgery_note_template_apply.dart';
import 'data/surgery_note_template_list_refresh.dart';
import 'data/surgery_note_template_repository_provider.dart';
import 'models/surgery_note_template.dart';
import '../../shared/widgets/clinical_form_scaffold.dart';
import '../../shared/widgets/clinical_stacked_sections.dart';
import '../../shared/widgets/form_section_card.dart';
import '../../shared/widgets/page_header.dart';
import '../patients/data/patient_lookup_data_source.dart';
import '../patients/widgets/patient_selector_field.dart';
import 'data/surgery_note_form_data_source.dart';
import 'models/surgery_procedure_note.dart';
import 'widgets/surgery_implant_material_fields.dart';
import 'widgets/surgery_procedure_date_field.dart';

class SurgeryNoteFormScreen extends StatefulWidget {
  final String? patientId;
  final String? noteId;

  const SurgeryNoteFormScreen({super.key, this.patientId, this.noteId});

  bool get isEditMode => noteId != null && noteId!.trim().isNotEmpty;

  @override
  State<SurgeryNoteFormScreen> createState() => _SurgeryNoteFormScreenState();
}

class _SurgeryNoteFormScreenState extends State<SurgeryNoteFormScreen> {
  String? patientId;
  DateTime? procedureDate;
  ProcedureType? procedureType;
  SurgeryBodyRegion? bodyRegion;
  SurgerySide? side;
  String? asaScore;
  bool? tourniquetUsed;

  final diagnosis = TextEditingController();
  final procedureName = TextEditingController();
  final anesthesiaType = TextEditingController();
  final procedureDetails = TextEditingController();
  final complications = TextEditingController();
  final surgeonName = TextEditingController();
  final assistantInfo = TextEditingController();
  final postOpRecommendations = TextEditingController();
  final physiotherapyStart = TextEditingController();
  final controlSchedule = TextEditingController();
  final notes = TextEditingController();
  final List<TextEditingController> _implantControllers = [
    TextEditingController(),
  ];

  @override
  void dispose() {
    diagnosis.dispose();
    procedureName.dispose();
    anesthesiaType.dispose();
    procedureDetails.dispose();
    complications.dispose();
    surgeonName.dispose();
    assistantInfo.dispose();
    postOpRecommendations.dispose();
    physiotherapyStart.dispose();
    controlSchedule.dispose();
    notes.dispose();
    for (final c in _implantControllers) {
      c.dispose();
    }
    super.dispose();
  }

  ProcedureType get _effectiveType => procedureType ?? ProcedureType.diger;

  Future<void> _pickProcedureDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: procedureDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => procedureDate = picked);
  }

  void _addImplantRow() {
    setState(() => _implantControllers.add(TextEditingController()));
  }

  void _removeImplantRow(int index) {
    if (_implantControllers.length <= 1) return;
    setState(() {
      _implantControllers[index].dispose();
      _implantControllers.removeAt(index);
    });
  }

  bool _saving = false;
  bool _loading = false;
  SurgeryProcedureNote? _existing;
  String _arthroscopyFindings = '';
  List<SurgeryNoteTemplate> _templates = const [];
  bool _loadingTemplates = true;

  @override
  void initState() {
    super.initState();
    patientId = widget.patientId;
    if (!widget.isEditMode) {
      procedureDate = DateTime.now();
      surgeonName.text = SurgeryNoteOwnership.currentSurgeonDisplayName();
    }
    _loadTemplates();
    if (widget.isEditMode) {
      _loadExisting();
    }
  }

  Future<void> _loadExisting() async {
    setState(() => _loading = true);
    try {
      final existing = await SurgeryNoteFormDataSource.loadForEdit(widget.noteId!);
      if (!mounted) return;
      _existing = existing;
      _populateFromNote(existing);
      setState(() => _loading = false);
    } on SurgeryNoteFormException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/surgery-notes');
      }
    }
  }

  void _populateFromNote(SurgeryProcedureNote note) {
    patientId = note.patientId;
    procedureDate = note.procedureDate;
    procedureType = note.procedureType;
    bodyRegion = note.bodyRegion;
    side = note.side;
    asaScore = note.asaScore.trim().isEmpty ? null : note.asaScore.trim();
    tourniquetUsed = note.tourniquetUsed;
    diagnosis.text = note.diagnosis == '-' ? '' : note.diagnosis;
    procedureName.text = note.procedureName == '-' ? '' : note.procedureName;
    anesthesiaType.text = note.anesthesiaType;
    procedureDetails.text = note.procedureDetails;
    complications.text = note.complications;
    surgeonName.text = note.surgeonName;
    assistantInfo.text = note.assistantInfo;
    postOpRecommendations.text = note.postOpRecommendations;
    physiotherapyStart.text = note.physiotherapyStartRecommendation;
    controlSchedule.text = note.controlSchedule;
    notes.text = note.notes;
    _arthroscopyFindings = note.arthroscopyFindings;
    _setImplantLines(decodeImplantMaterialLines(note.implantOrMaterialInfo));
  }

  Future<void> _loadTemplates() async {
    try {
      final items =
          await SurgeryNoteTemplateRepositoryProvider.asyncRepository.getAll();
      if (!mounted) return;
      setState(() {
        _templates = items;
        _loadingTemplates = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingTemplates = false);
    }
  }

  void _applyTemplate(SurgeryNoteTemplate? template) {
    if (template == null) return;
    setState(() {
      SurgeryNoteTemplateApply.applyContent(
        template.content,
        (
          setProcedureType: (v) => procedureType = v,
          setBodyRegion: (v) => bodyRegion = v,
          setSide: (v) => side = v,
          setAsaScore: (v) => asaScore = v,
          setTourniquetUsed: (v) => tourniquetUsed = v,
          setDiagnosis: (v) => diagnosis.text = v,
          setProcedureName: (v) => procedureName.text = v,
          setAnesthesiaType: (v) => anesthesiaType.text = v,
          setProcedureDetails: (v) => procedureDetails.text = v,
          setComplications: (v) => complications.text = v,
          setAssistantInfo: (v) => assistantInfo.text = v,
          setImplantLines: _setImplantLines,
          setPostOpRecommendations: (v) => postOpRecommendations.text = v,
          setPhysiotherapyStart: (v) => physiotherapyStart.text = v,
          setControlSchedule: (v) => controlSchedule.text = v,
          setNotes: (v) => notes.text = v,
        ),
      );
    });
  }

  void _setImplantLines(List<String> lines) {
    for (final c in _implantControllers) {
      c.dispose();
    }
    _implantControllers
      ..clear()
      ..addAll(
        (lines.isEmpty ? [''] : lines)
            .map((line) => TextEditingController(text: line)),
      );
  }

  Future<void> _saveAsTemplate() async {
    final nameCtrl = TextEditingController();
    final descriptionCtrl = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Şablon olarak kaydet'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Şablon adı'),
            ),
            TextField(
              controller: descriptionCtrl,
              decoration: const InputDecoration(labelText: 'Açıklama'),
              minLines: 1,
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
    if (saved != true || !mounted) {
      nameCtrl.dispose();
      descriptionCtrl.dispose();
      return;
    }

    if (nameCtrl.text.trim().isEmpty) {
      nameCtrl.dispose();
      descriptionCtrl.dispose();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Şablon adı zorunlu.')),
      );
      return;
    }

    final profileId = SurgeryNoteOwnership.currentProfileId();
    if (profileId == null || profileId.isEmpty) {
      nameCtrl.dispose();
      descriptionCtrl.dispose();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Oturum bilgisi bulunamadı.')),
      );
      return;
    }

    final now = DateTime.now();
    final template = SurgeryNoteTemplate(
      id: 'snt${now.millisecondsSinceEpoch}',
      profileId: profileId,
      name: nameCtrl.text.trim(),
      description: descriptionCtrl.text.trim(),
      createdAt: now,
      content: SurgeryNoteTemplateApply.captureContent(
        procedureType: procedureType,
        bodyRegion: bodyRegion,
        side: side,
        asaScore: asaScore,
        tourniquetUsed: tourniquetUsed,
        diagnosis: diagnosis.text,
        procedureName: procedureName.text,
        anesthesiaType: anesthesiaType.text,
        procedureDetails: procedureDetails.text,
        complications: complications.text,
        assistantInfo: assistantInfo.text,
        implantLines: encodeImplantMaterialLines(
          _implantControllers.map((c) => c.text),
        ).split('\n').where((l) => l.trim().isNotEmpty).toList(),
        postOpRecommendations: postOpRecommendations.text,
        physiotherapyStart: physiotherapyStart.text,
        controlSchedule: controlSchedule.text,
        notes: notes.text,
      ),
    );
    nameCtrl.dispose();
    descriptionCtrl.dispose();

    try {
      await SurgeryNoteTemplateRepositoryProvider.asyncRepository.create(
        template,
      );
      SurgeryNoteTemplateListRefresh.markStale();
      if (!mounted) return;
      await _loadTemplates();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Şablon kaydedildi.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Şablon kaydedilemedi.')),
      );
    }
  }

  Future<void> _save() async {
    if (_saving || _loading) return;
    if (patientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen hasta seçin')),
      );
      return;
    }

    if (procedureDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen işlem tarihi seçin')),
      );
      return;
    }

    final patient = widget.isEditMode
        ? null
        : await PatientLookupDataSource.findById(patientId!);
    if (!mounted) return;
    if (!widget.isEditMode && patient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen hasta seçin')),
      );
      return;
    }

    if (widget.isEditMode && _existing == null) {
      return;
    }

    final implantLines = encodeImplantMaterialLines(
      _implantControllers.map((c) => c.text),
    );

    setState(() => _saving = true);

    final resolvedPatientId =
        widget.isEditMode ? _existing!.patientId : patient!.id;
    final resolvedPatientName =
        widget.isEditMode ? _existing!.patientName : patient!.fullName;

    final draft = SurgeryProcedureNote(
      id: widget.isEditMode ? _existing!.id : 'sn${DateTime.now().millisecondsSinceEpoch}',
      patientId: resolvedPatientId,
      patientName: resolvedPatientName,
      procedureDate: procedureDate!,
      procedureType: _effectiveType,
      bodyRegion: bodyRegion ?? SurgeryBodyRegion.diger,
      side: side ?? SurgerySide.uygunDegil,
      diagnosis: diagnosis.text.trim().isEmpty ? '-' : diagnosis.text.trim(),
      procedureName:
          procedureName.text.trim().isEmpty ? '-' : procedureName.text.trim(),
      anesthesiaType: anesthesiaType.text.trim(),
      asaScore: asaScore?.trim() ?? '',
      tourniquetUsed: tourniquetUsed,
      implantOrMaterialInfo: implantLines,
      arthroscopyFindings: _arthroscopyFindings,
      procedureDetails: procedureDetails.text.trim(),
      complications: complications.text.trim(),
      postOpRecommendations: postOpRecommendations.text.trim(),
      physiotherapyStartRecommendation: physiotherapyStart.text.trim(),
      controlSchedule: controlSchedule.text.trim(),
      surgeonName: widget.isEditMode
          ? _existing!.surgeonName
          : SurgeryNoteOwnership.currentSurgeonDisplayName(),
      assistantInfo: assistantInfo.text.trim(),
      notes: notes.text.trim(),
      createdByProfileId:
          widget.isEditMode ? _existing!.createdByProfileId : null,
    );

    try {
      final saved = widget.isEditMode
          ? await SurgeryNoteFormDataSource.update(draft)
          : await SurgeryNoteFormDataSource.create(draft);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEditMode
                ? 'Ameliyat / girişim notu güncellendi.'
                : 'Ameliyat / girişim notu kaydedildi.',
          ),
        ),
      );
      context.go('/surgery-notes/${saved.id}');
    } on SurgeryNoteFormException catch (e) {
      if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
    );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _cancel() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/surgery-notes');
    }
  }

  Widget _anesthesiaRow(BuildContext context) {
    final anesthesiaField = TextFormField(
      controller: anesthesiaType,
      decoration: const InputDecoration(
        labelText: 'Anestezi Tipi',
        isDense: true,
      ),
    );
    final asaField = DropdownButtonFormField<String?>(
      initialValue: asaScore,
      decoration: const InputDecoration(
        labelText: 'ASA Skor',
        isDense: true,
      ),
      isExpanded: true,
      items: [
        const DropdownMenuItem<String?>(
          value: null,
          child: Text('Seçiniz', overflow: TextOverflow.ellipsis),
        ),
        ...asaScoreOptions.map(
          (score) => DropdownMenuItem<String?>(
            value: score,
            child: Text(score, overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
      onChanged: (v) => setState(() => asaScore = v),
    );
    final tourniquetField = DropdownButtonFormField<bool?>(
      initialValue: tourniquetUsed,
      decoration: const InputDecoration(
        labelText: 'Turnike',
        isDense: true,
      ),
      isExpanded: true,
      items: const [
        DropdownMenuItem<bool?>(
          value: null,
          child: Text('Seçiniz', overflow: TextOverflow.ellipsis),
        ),
        DropdownMenuItem<bool?>(
          value: true,
          child: Text('Var', overflow: TextOverflow.ellipsis),
        ),
        DropdownMenuItem<bool?>(
          value: false,
          child: Text('Yok', overflow: TextOverflow.ellipsis),
        ),
      ],
      onChanged: (v) => setState(() => tourniquetUsed = v),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 480;
        if (stacked) {
          return Column(
            children: [
              anesthesiaField,
              asaField,
              tourniquetField,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 2, child: anesthesiaField),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: asaField),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: tourniquetField),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final noteLabel = procedureNoteFieldLabel(_effectiveType);
    final screenTitle = widget.isEditMode
        ? 'Ameliyat / Girişim Notunu Düzenle'
        : 'Yeni Ameliyat / Girişim Notu';

    return ClinicalFormScaffold(
      shellTitle: screenTitle,
      onSave: _save,
      onCancel: _cancel,
      saveLabel: widget.isEditMode ? 'Güncelle' : 'Kaydet',
      saving: _saving,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageHeader(
            title: screenTitle,
            icon: Icons.medical_services_outlined,
            leadingBack: true,
            fallbackRoute: widget.isEditMode && _existing != null
                ? '/surgery-notes/${_existing!.id}'
                : '/surgery-notes',
          ),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
              if (_loadingTemplates)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                DropdownButton<SurgeryNoteTemplate?>(
                  hint: const Text('Şablon yükle'),
                  value: null,
                  items: [
                    for (final template in _templates)
                      DropdownMenuItem(
                        value: template,
                        child: Text(template.name),
                      ),
                  ],
                  onChanged: _applyTemplate,
                ),
              OutlinedButton.icon(
                onPressed: _saveAsTemplate,
                icon: const Icon(Icons.save_outlined, size: 18),
                label: const Text('Şablon olarak kaydet'),
              ),
              TextButton.icon(
                onPressed: () => context.push('/surgery-note-templates'),
                icon: const Icon(Icons.library_books_outlined, size: 18),
                label: const Text('Şablonlarım'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClinicalStackedSections(
            children: [
                        FormSectionCard(
                          title: 'Hasta ve İşlem',
                          icon: Icons.person_outline,
                          children: [
                            PatientSelectorField(
                              selectedPatientId: patientId,
                              labelText: 'Hasta',
                    lockSelection: widget.isEditMode,
                    enabled: !widget.isEditMode,
                    onChanged: widget.isEditMode
                        ? null
                        : (v) => setState(() => patientId = v),
                  ),
                  SurgeryProcedureDateField(
                    selectedDate: procedureDate,
                    onTap: _pickProcedureDate,
                            ),
                            DropdownButtonFormField<ProcedureType>(
                              initialValue: procedureType,
                              decoration: const InputDecoration(
                                labelText: 'İşlem Tipi',
                                isDense: true,
                              ),
                              isExpanded: true,
                              items: ProcedureType.values
                                  .map(
                                    (t) => DropdownMenuItem(
                                      value: t,
                                      child: Text(
                                        procedureTypeLabel(t),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) => setState(() => procedureType = v),
                            ),
                            LayoutBuilder(
                              builder: (context, rowConstraints) {
                                final stacked = rowConstraints.maxWidth < 480;
                      final regionField =
                          DropdownButtonFormField<SurgeryBodyRegion>(
                                  initialValue: bodyRegion,
                                  decoration: const InputDecoration(
                                    labelText: 'Bölge',
                                    isDense: true,
                                  ),
                                  isExpanded: true,
                                  items: SurgeryBodyRegion.values
                                      .map(
                                        (r) => DropdownMenuItem(
                                          value: r,
                                          child: Text(
                                            surgeryBodyRegionLabel(r),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (v) => setState(() => bodyRegion = v),
                                );
                                final sideField = DropdownButtonFormField<SurgerySide>(
                                  initialValue: side,
                                  decoration: const InputDecoration(
                                    labelText: 'Taraf',
                                    isDense: true,
                                  ),
                                  isExpanded: true,
                                  items: SurgerySide.values
                                      .map(
                                        (s) => DropdownMenuItem(
                                          value: s,
                                          child: Text(
                                            surgerySideLabel(s),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (v) => setState(() => side = v),
                                );
                                if (stacked) {
                                  return Column(
                                    children: [regionField, sideField],
                                  );
                                }
                                return Row(
                                  children: [
                                    Expanded(child: regionField),
                          const SizedBox(width: AppSpacing.sm),
                                    Expanded(child: sideField),
                                  ],
                                );
                              },
                            ),
                            TextFormField(
                              controller: diagnosis,
                              decoration: const InputDecoration(
                                labelText: 'Tanı',
                                isDense: true,
                              ),
                            ),
                            TextFormField(
                              controller: procedureName,
                              decoration: const InputDecoration(
                                labelText: 'İşlem Adı',
                                isDense: true,
                              ),
                            ),
                          ],
                        ),
                        FormSectionCard(
                          title: 'İşlem Detayları',
                          icon: Icons.medical_services_outlined,
                          children: [
                  _anesthesiaRow(context),
                            TextFormField(
                              controller: procedureDetails,
                    minLines: 3,
                    maxLines: 6,
                    decoration: InputDecoration(
                      labelText: noteLabel,
                                isDense: true,
                      alignLabelWithHint: true,
                              ),
                            ),
                            TextFormField(
                              controller: complications,
                    minLines: 2,
                    maxLines: 4,
                              decoration: const InputDecoration(
                                labelText: 'Komplikasyon',
                                isDense: true,
                      alignLabelWithHint: true,
                              ),
                            ),
                            TextFormField(
                              controller: surgeonName,
                    readOnly: true,
                              decoration: const InputDecoration(
                                labelText: 'Cerrah',
                                isDense: true,
                      helperText: 'Oturumdaki cerrah adına kaydedilir',
                              ),
                            ),
                            TextFormField(
                              controller: assistantInfo,
                              decoration: const InputDecoration(
                      labelText: 'Ekip',
                                isDense: true,
                              ),
                            ),
                          ],
                        ),
              FormSectionCard(
                title: 'İmplant / Materyal Bilgisi',
                icon: Icons.construction_outlined,
                children: [
                  SurgeryImplantMaterialFields(
                    controllers: _implantControllers,
                    onAddRow: _addImplantRow,
                    onRemoveRow: _removeImplantRow,
                            ),
                          ],
                        ),
                        FormSectionCard(
                          title: 'Post-op ve Takip',
                          icon: Icons.event_note_outlined,
                          children: [
                            TextFormField(
                              controller: postOpRecommendations,
                    minLines: 3,
                    maxLines: 6,
                              decoration: const InputDecoration(
                                labelText: 'Post-op Öneriler',
                                isDense: true,
                      alignLabelWithHint: true,
                              ),
                            ),
                            TextFormField(
                              controller: physiotherapyStart,
                    minLines: 2,
                    maxLines: 4,
                              decoration: const InputDecoration(
                                labelText: 'Fizyoterapi Başlangıç Önerisi',
                                isDense: true,
                      alignLabelWithHint: true,
                              ),
                            ),
                            TextFormField(
                              controller: controlSchedule,
                    minLines: 2,
                    maxLines: 4,
                              decoration: const InputDecoration(
                                labelText: 'Kontrol Takvimi',
                                isDense: true,
                      alignLabelWithHint: true,
                              ),
                            ),
                            TextFormField(
                              controller: notes,
                    minLines: 1,
                    maxLines: 4,
                              decoration: const InputDecoration(
                                labelText: 'Notlar',
                                isDense: true,
                      alignLabelWithHint: true,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}
