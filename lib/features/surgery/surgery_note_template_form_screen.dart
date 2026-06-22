import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/clinical_form_scaffold.dart';
import '../../shared/widgets/clinical_snack_bar.dart';
import '../../shared/widgets/clinical_stacked_sections.dart';
import '../../shared/widgets/form_section_card.dart';
import '../../shared/widgets/page_header.dart';
import 'data/surgery_note_template_apply.dart';
import 'data/surgery_note_template_list_refresh.dart';
import 'data/surgery_note_template_repository_provider.dart';
import 'data/surgery_note_ownership.dart';
import 'models/surgery_note_template.dart';
import 'models/surgery_procedure_note.dart';
import 'widgets/surgery_implant_material_fields.dart';

class SurgeryNoteTemplateFormScreen extends StatefulWidget {
  final String? templateId;

  const SurgeryNoteTemplateFormScreen({super.key, this.templateId});

  bool get isEditMode => templateId != null && templateId!.trim().isNotEmpty;

  @override
  State<SurgeryNoteTemplateFormScreen> createState() =>
      _SurgeryNoteTemplateFormScreenState();
}

class _SurgeryNoteTemplateFormScreenState
    extends State<SurgeryNoteTemplateFormScreen> {
  final nameCtrl = TextEditingController();
  final descriptionCtrl = TextEditingController();
  final diagnosis = TextEditingController();
  final procedureName = TextEditingController();
  final anesthesiaType = TextEditingController();
  final procedureDetails = TextEditingController();
  final complications = TextEditingController();
  final assistantInfo = TextEditingController();
  final postOpRecommendations = TextEditingController();
  final physiotherapyStart = TextEditingController();
  final controlSchedule = TextEditingController();
  final notes = TextEditingController();
  final List<TextEditingController> _implantControllers = [
    TextEditingController(),
  ];

  ProcedureType? procedureType;
  SurgeryBodyRegion? bodyRegion;
  SurgerySide? side;
  String? asaScore;
  bool? tourniquetUsed;
  bool _loading = false;
  bool _saving = false;
  SurgeryNoteTemplate? _existing;

  @override
  void initState() {
    super.initState();
    if (widget.isEditMode) {
      _loadExisting();
    }
  }

  Future<void> _loadExisting() async {
    setState(() => _loading = true);
    final existing = await SurgeryNoteTemplateRepositoryProvider.asyncRepository
        .getById(widget.templateId!);
    if (!mounted) return;
    if (existing == null) {
      setState(() => _loading = false);
      showClinicalSnackBar(context, 'Şablon bulunamadı.', isError: true);
      context.go('/surgery-note-templates');
      return;
    }

    _existing = existing;
    nameCtrl.text = existing.name;
    descriptionCtrl.text = existing.description;
    _applyContent(existing.content);
    setState(() => _loading = false);
  }

  void _applyContent(SurgeryNoteTemplateContent content) {
    SurgeryNoteTemplateApply.applyContent(
      content,
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

  @override
  void dispose() {
    nameCtrl.dispose();
    descriptionCtrl.dispose();
    diagnosis.dispose();
    procedureName.dispose();
    anesthesiaType.dispose();
    procedureDetails.dispose();
    complications.dispose();
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

  SurgeryNoteTemplateContent _captureContent() {
    return SurgeryNoteTemplateApply.captureContent(
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
    );
  }

  Future<void> _save() async {
    if (_saving) return;
    if (nameCtrl.text.trim().isEmpty) {
      showClinicalSnackBar(context, 'Şablon adı zorunlu.', isError: true);
      return;
    }

    final profileId = SurgeryNoteOwnership.currentProfileId();
    if (profileId == null || profileId.isEmpty) {
      showClinicalSnackBar(context, 'Oturum bilgisi bulunamadı.', isError: true);
      return;
    }

    setState(() => _saving = true);
    final now = DateTime.now();
    final record = SurgeryNoteTemplate(
      id: _existing?.id ?? 'snt${now.millisecondsSinceEpoch}',
      profileId: _existing?.profileId ?? profileId,
      name: nameCtrl.text.trim(),
      description: descriptionCtrl.text.trim(),
      createdAt: _existing?.createdAt ?? now,
      updatedAt: now,
      content: _captureContent(),
    );

    try {
      if (widget.isEditMode) {
        await SurgeryNoteTemplateRepositoryProvider.asyncRepository.update(
          record,
        );
      } else {
        await SurgeryNoteTemplateRepositoryProvider.asyncRepository.create(
          record,
        );
      }
      SurgeryNoteTemplateListRefresh.markStale();
      if (!mounted) return;
      showClinicalSnackBar(context, 'Şablon kaydedildi.');
      context.go('/surgery-note-templates');
    } catch (_) {
      if (!mounted) return;
      showClinicalSnackBar(context, 'Şablon kaydedilemedi.', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _cancel() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/surgery-note-templates');
    }
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final noteLabel = procedureNoteFieldLabel(procedureType ?? ProcedureType.diger);

    return ClinicalFormScaffold(
      shellTitle: widget.isEditMode ? 'Şablonu Düzenle' : 'Yeni Şablon',
      onSave: _save,
      onCancel: _cancel,
      saveLabel: 'Kaydet',
      saving: _saving,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageHeader(
            title: widget.isEditMode ? 'Şablonu Düzenle' : 'Yeni Şablon',
            icon: Icons.library_books_outlined,
            leadingBack: true,
            fallbackRoute: '/surgery-note-templates',
          ),
          ClinicalStackedSections(
            children: [
              FormSectionCard(
                title: 'Şablon Bilgisi',
                icon: Icons.label_outline,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Şablon adı',
                      isDense: true,
                    ),
                  ),
                  TextFormField(
                    controller: descriptionCtrl,
                    minLines: 1,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Açıklama',
                      isDense: true,
                      alignLabelWithHint: true,
                    ),
                  ),
                ],
              ),
              FormSectionCard(
                title: 'İşlem Varsayılanları',
                icon: Icons.medical_services_outlined,
                children: [
                  DropdownButtonFormField<ProcedureType?>(
                    initialValue: procedureType,
                    decoration: const InputDecoration(
                      labelText: 'İşlem tipi',
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Seçilmedi'),
                      ),
                      ...ProcedureType.values.map(
                        (t) => DropdownMenuItem(
                          value: t,
                          child: Text(procedureTypeLabel(t)),
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() => procedureType = v),
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
                      labelText: 'İşlem adı',
                      isDense: true,
                    ),
                  ),
                  TextFormField(
                    controller: anesthesiaType,
                    decoration: const InputDecoration(
                      labelText: 'Anestezi tipi',
                      isDense: true,
                    ),
                  ),
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
                    controller: assistantInfo,
                    decoration: const InputDecoration(
                      labelText: 'Ekip',
                      isDense: true,
                    ),
                  ),
                ],
              ),
              FormSectionCard(
                title: 'İmplant / Materyal',
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
                      labelText: 'Post-op öneriler',
                      isDense: true,
                      alignLabelWithHint: true,
                    ),
                  ),
                  TextFormField(
                    controller: physiotherapyStart,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Fizyoterapi başlangıç önerisi',
                      isDense: true,
                      alignLabelWithHint: true,
                    ),
                  ),
                  TextFormField(
                    controller: controlSchedule,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Kontrol takvimi',
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
