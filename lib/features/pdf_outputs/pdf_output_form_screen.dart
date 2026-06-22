import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_session.dart';
import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/clinical_state_message.dart';
import '../../shared/widgets/clinical_form_scaffold.dart';
import '../../shared/widgets/form_section_card.dart';
import '../../shared/widgets/page_header.dart';
import '../appointments/models/appointment.dart';
import '../clinical_encounter/models/clinical_encounter.dart';
import '../exercises/models/exercise_plan.dart';
import '../imaging/data/imaging_repository.dart';
import '../patients/data/patient_selector_data_source.dart';
import '../patients/models/patient.dart';
import '../patients/widgets/patient_selector_field.dart';
import '../post_op_protocols/models/post_op_protocol.dart';
import '../physiotherapy/data/physiotherapy_referral_lookup_data_source.dart';
import 'data/pdf_output_bytes_builder.dart';
import 'data/pdf_output_list_refresh.dart';
import 'data/pdf_output_storage_orchestrator.dart';
import 'models/pdf_output.dart';
import 'pdf_clinical_encounter_prefill.dart';
import 'pdf_form_source_loader.dart';
import 'pdf_module_prefill.dart';
import 'widgets/pdf_letterhead_preview_card.dart';

class PdfOutputFormScreen extends StatefulWidget {
  final String? patientId;
  final String? source;
  final String? sourceRecordId;

  const PdfOutputFormScreen({
    super.key,
    this.patientId,
    this.source,
    this.sourceRecordId,
  });

  @override
  State<PdfOutputFormScreen> createState() => _PdfOutputFormScreenState();
}

class _PdfOutputFormScreenState extends State<PdfOutputFormScreen> {
  final _formKey = GlobalKey<FormState>();
  String? patientId;
  Patient? _resolvedPatient;
  DocumentType? docType;
  PdfStatus? status;
  String? _sourceModule;
  String? _sourceRecordId;
  String? _prefillWarning;
  ClinicalEncounter? _encounterSnapshot;

  final titleCtrl = TextEditingController();
  final relatedDiag = TextEditingController();
  final relatedPlan = TextEditingController();
  final content = TextEditingController();
  final warning = TextEditingController(
    text:
        'Bu belge, muayene ve klinik değerlendirme sonrası bilgilendirme amacıyla hazırlanmıştır. Tanı ve tedavi planı kişiye özeldir. Hekim önerisi dışında uygulanmamalıdır. Belge çıktısı alınmadan önce hekim tarafından kontrol edilmelidir.',
  );

  bool _loaded = false;
  bool _saving = false;
  String? _initError;

  bool get _lockPatientFromRoute {
    final routePid = widget.patientId?.trim();
    if (routePid != null && routePid.isNotEmpty) return true;
    if (_sourceModule != null && _sourceModule!.trim().isNotEmpty) {
      return true;
    }
    return false;
  }

  String? _effectivePatientId() {
    final stateId = patientId?.trim();
    if (stateId != null && stateId.isNotEmpty) return stateId;
    final routeId = widget.patientId?.trim();
    if (routeId != null && routeId.isNotEmpty) return routeId;
    return null;
  }

  @override
  void initState() {
    super.initState();
    patientId = widget.patientId?.trim().isNotEmpty == true
        ? widget.patientId!.trim()
        : null;
    status = PdfStatus.taslak;
    _initForm();
  }

  Future<void> _initForm() async {
    await _applySourcePrefill();

    final pid = _effectivePatientId();
    if (pid != null) {
      final patient = await PatientSelectorDataSource.getById(pid);
      if (patient == null) {
        if (mounted) {
          setState(() {
            _loaded = true;
            _initError =
                'Hasta kaydı bulunamadı veya erişim yok. Lütfen hasta detayından tekrar deneyin.';
          });
        }
        return;
      }
      _resolvedPatient = patient;
    }

    if (mounted) setState(() => _loaded = true);
  }

  Future<void> _applySourcePrefill() async {
    final source = widget.source?.trim();
    final recordId = widget.sourceRecordId?.trim();
    if (source == null ||
        source.isEmpty ||
        recordId == null ||
        recordId.isEmpty) {
      return;
    }

    switch (source) {
      case pdfSourceModuleClinicalEncounter:
        await _prefillClinicalEncounter(recordId);
      case pdfSourceModulePostOpProtocol:
        await _prefillPostOpProtocol(recordId);
      case pdfSourceModuleExercisePlan:
        await _prefillExercisePlan(recordId);
      case pdfSourceModuleSurgeryNote:
        await _prefillSurgeryNote(recordId);
      case pdfSourceModuleImagingNote:
        await _prefillImagingNote(recordId);
      case pdfSourceModulePhysiotherapyReferral:
        await _prefillPhysiotherapyReferral(recordId);
      case pdfSourceModuleAppointment:
        await _prefillAppointment(recordId);
    }
  }

  Future<void> _prefillAppointment(String recordId) async {
    final appointment = await PdfFormSourceLoader.loadAppointment(recordId);
    if (!mounted) return;
    if (appointment == null) {
      _prefillWarning =
          'Kaynak randevu bulunamadı. Formu manuel doldurabilirsiniz.';
      return;
    }

    patientId = appointment.patientId;
    _sourceModule = pdfSourceModuleAppointment;
    _sourceRecordId = appointment.id;

    docType = DocumentType.kontrolPlani;
    titleCtrl.text = PdfModulePrefill.appointmentTitle(
      appointment.patientName,
      appointment.appointmentDateTime,
    );
    relatedDiag.text =
        PdfModulePrefill.appointmentRelatedDiagnosis(appointment);
    relatedPlan.text = appointmentTypeLabel(appointment.type);
    content.text = PdfModulePrefill.appointmentContentSummary(appointment);
    warning.text = PdfModulePrefill.defaultWarningNote;
  }

  Future<void> _prefillClinicalEncounter(String recordId) async {
    final encounter = await PdfFormSourceLoader.loadClinicalEncounter(recordId);
    if (!mounted) return;
    if (encounter == null) {
      _encounterSnapshot = null;
      _prefillWarning =
          'Kaynak muayene kaydı bulunamadı. Formu manuel doldurabilirsiniz.';
      return;
    }

    _encounterSnapshot = encounter;
    patientId = encounter.patientId;
    _sourceModule = pdfSourceModuleClinicalEncounter;
    _sourceRecordId = encounter.id;

    docType = DocumentType.muayeneOzeti;
    titleCtrl.text =
        PdfClinicalEncounterPrefill.defaultTitle(encounter.patientName);
    relatedDiag.text = PdfClinicalEncounterPrefill.diagnosisLine(encounter);
    relatedPlan.text = PdfClinicalEncounterPrefill.treatmentPlanLine(encounter);
    content.text = PdfClinicalEncounterPrefill.contentSummary(encounter);
  }

  Future<void> _prefillPostOpProtocol(String recordId) async {
    final protocol = await PdfFormSourceLoader.loadPostOpProtocol(recordId);
    if (!mounted) return;
    if (protocol == null) {
      _prefillWarning =
          'Kaynak post-op protokol bulunamadı. Formu manuel doldurabilirsiniz.';
      return;
    }

    String? linkedSurgeryName;
    final surgeryNoteId = protocol.surgeryNoteId?.trim();
    if (surgeryNoteId != null && surgeryNoteId.isNotEmpty) {
      final surgery = await PdfFormSourceLoader.loadSurgeryNote(surgeryNoteId);
      linkedSurgeryName = surgery?.procedureName;
    }

    patientId = protocol.patientId;
    _sourceModule = pdfSourceModulePostOpProtocol;
    _sourceRecordId = protocol.id;

    docType = DocumentType.postOpProtokol;
    titleCtrl.text = PdfModulePrefill.postOpTitle(protocol.patientName);
    final procedureSummary = protocol.diagnosisOrProcedureSummary.trim();
    relatedDiag.text = procedureSummary.isEmpty
        ? PdfModulePrefill.unspecified
        : procedureSummary.length > 120
            ? '${procedureSummary.substring(0, 120)}…'
            : procedureSummary;
    relatedPlan.text = protocol.protocolTitle;
    content.text = PdfModulePrefill.postOpContentSummary(
      protocol,
      linkedSurgeryProcedureName: linkedSurgeryName,
    );
    warning.text = PdfModulePrefill.defaultWarningNote;
  }

  Future<void> _prefillExercisePlan(String recordId) async {
    final plan = await PdfFormSourceLoader.loadExercisePlan(recordId);
    if (!mounted) return;
    if (plan == null) {
      _prefillWarning =
          'Kaynak egzersiz programı bulunamadı. Formu manuel doldurabilirsiniz.';
      return;
    }

    patientId = plan.patientId;
    _sourceModule = pdfSourceModuleExercisePlan;
    _sourceRecordId = plan.id;

    docType = DocumentType.egzersizProgrami;
    titleCtrl.text = PdfModulePrefill.exerciseTitle(plan.patientName);
    relatedDiag.text = PdfModulePrefill.exerciseRelatedDiagnosis(plan);
    relatedPlan.text = plan.title;
    content.text = PdfModulePrefill.exerciseContentSummary(plan);
    warning.text = PdfModulePrefill.defaultWarningNote;
  }

  Future<void> _prefillSurgeryNote(String recordId) async {
    final note = await PdfFormSourceLoader.loadSurgeryNote(recordId);
    if (!mounted) return;
    if (note == null) {
      _prefillWarning =
          'Kaynak ameliyat / girişim notu bulunamadı. Formu manuel doldurabilirsiniz.';
      return;
    }

    patientId = note.patientId;
    _sourceModule = pdfSourceModuleSurgeryNote;
    _sourceRecordId = note.id;

    docType = DocumentType.ameliyatGirisimNotu;
    titleCtrl.text = PdfModulePrefill.surgeryTitle(note.patientName);
    relatedDiag.text = PdfModulePrefill.surgeryRelatedDiagnosis(note);
    relatedPlan.text = note.procedureName;
    content.text = PdfModulePrefill.surgeryContentSummary(note);
    warning.text = PdfModulePrefill.defaultWarningNote;
  }

  Future<void> _prefillImagingNote(String recordId) async {
    final note = await PdfFormSourceLoader.loadImagingNote(recordId);
    if (!mounted) return;
    if (note == null) {
      _prefillWarning =
          'Kaynak görüntüleme notu bulunamadı. Formu manuel doldurabilirsiniz.';
      return;
    }

    patientId = note.patientId;
    _sourceModule = pdfSourceModuleImagingNote;
    _sourceRecordId = note.id;

    docType = DocumentType.goruntulemeOzeti;
    titleCtrl.text = PdfModulePrefill.imagingTitle(note.patientName);
    relatedDiag.text = PdfModulePrefill.imagingRelatedDiagnosis(note);
    relatedPlan.text =
        '${ImagingRepository.typeLabel(note.imagingType)} — ${ImagingRepository.regionLabel(note.bodyRegion)}';
    content.text = PdfModulePrefill.imagingContentSummary(note);
    warning.text = PdfModulePrefill.defaultWarningNote;
  }

  Future<void> _prefillPhysiotherapyReferral(String recordId) async {
    final result =
        await PhysiotherapyReferralLookupDataSource.getById(recordId);
    if (!mounted) return;

    final referral = result.referral;
    if (referral == null) {
      _prefillWarning =
          'Kaynak fizyoterapi yönlendirmesi bulunamadı. Formu manuel doldurabilirsiniz.';
      return;
    }

    patientId = referral.patientId;
    _sourceModule = pdfSourceModulePhysiotherapyReferral;
    _sourceRecordId = referral.id;

    docType = DocumentType.fizyoterapiYonlendirme;
    titleCtrl.text =
        PdfModulePrefill.physiotherapyReferralTitle(referral.patientName);
    relatedDiag.text =
        PdfModulePrefill.physiotherapyReferralRelatedDiagnosis(referral);
    relatedPlan.text = referral.treatmentGoal.trim().isEmpty
        ? PdfModulePrefill.unspecified
        : referral.treatmentGoal.length > 120
            ? '${referral.treatmentGoal.substring(0, 120)}…'
            : referral.treatmentGoal;
    content.text =
        PdfModulePrefill.physiotherapyReferralContentSummary(referral);
    warning.text = PdfModulePrefill.defaultWarningNote;
  }

  String? _sourceChipLabel() {
    if (_sourceModule == null || _sourceRecordId == null) return null;
    return 'Kaynak: ${pdfSourceModuleLabel(_sourceModule)}';
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    relatedDiag.dispose();
    relatedPlan.dispose();
    content.dispose();
    warning.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _save() async {
    if (_saving || !_loaded || _initError != null) return;

    final effectivePid = _effectivePatientId();
    if (effectivePid != null && effectivePid.isNotEmpty) {
      patientId = effectivePid;
    }

    if (!(_formKey.currentState?.validate() ?? false)) return;

    final pid = _effectivePatientId();
    if (pid == null || pid.isEmpty) {
      return;
    }

    setState(() => _saving = true);

    try {
      final patient =
          _resolvedPatient ?? await PatientSelectorDataSource.getById(pid);
      if (patient == null) {
        if (!mounted) return;
        _showMessage(
          'Hasta kaydı bulunamadı veya erişim yok. Lütfen tekrar seçin.',
        );
        return;
      }

      final createdBy = AuthSession.currentUser?.displayName ?? 'Doktor';

      final draft = PdfOutput(
        id: 'pdf${DateTime.now().millisecondsSinceEpoch}',
        patientId: patient.id,
        patientName: patient.fullName,
        createdAt: DateTime.now(),
        documentType: docType ?? DocumentType.muayeneOzeti,
        title: titleCtrl.text.isEmpty ? 'Yeni PDF' : titleCtrl.text.trim(),
        relatedDiagnosis:
            relatedDiag.text.trim().isEmpty ? null : relatedDiag.text.trim(),
        relatedTreatmentPlan:
            relatedPlan.text.trim().isEmpty ? null : relatedPlan.text.trim(),
        contentSummary: content.text.trim(),
        warningNote: warning.text.trim(),
        createdBy: createdBy,
        status: status ?? PdfStatus.taslak,
        sourceModule: _sourceModule,
        sourceRecordId: _sourceRecordId,
      );

      final bytes = await PdfOutputBytesBuilder.buildForSave(
        draft: draft,
        encounterSnapshot: _encounterSnapshot,
        patientFileNumber: patient.fileNumber,
      );

      if (bytes == null || bytes.isEmpty) {
        if (!mounted) return;
        _showMessage(PdfOutputStorageException.contentCouldNotBeCreatedMessage);
        return;
      }

      await PdfOutputStorageOrchestrator.saveGeneratedPdf(
        draft: draft,
        pdfBytes: bytes,
      );
      PdfOutputListRefresh.markStale();
      if (!mounted) return;
      _showMessage('PDF güvenli alana kaydedildi.');
      await context.push('/pdf-outputs');
    } on PdfOutputStorageException catch (e) {
      if (!mounted) return;
      if (e.message ==
          PdfOutputStorageException.contentCouldNotBeCreatedMessage) {
        _showMessage(e.message);
      } else {
        _showMessage('Kayıt kaydedilemedi. Lütfen tekrar deneyin.');
      }
    } catch (_) {
      if (!mounted) return;
      _showMessage('Kayıt kaydedilemedi. Lütfen tekrar deneyin.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _cancel() {
    if (_saving) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.push('/pdf-outputs');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const AppShell(
        title: 'Yeni PDF Çıktısı',
        child: Center(child: CircularProgressIndicator.adaptive()),
      );
    }

    if (_initError != null) {
      return AppShell(
        title: 'Yeni PDF Çıktısı',
        child: Center(
          child: ClinicalStateMessage.error(
            icon: Icons.error_outline,
            title: 'Form yüklenemedi',
            description: 'Form yüklenemedi. Lütfen tekrar deneyin.',
          ),
        ),
      );
    }

    return ClinicalFormScaffold.sections(
      shellTitle: 'Yeni PDF Çıktısı',
      onSave: _save,
      onCancel: _cancel,
      saveLabel: 'Kaydet',
      saving: _saving,
      formKey: _formKey,
      header: const PageHeader(
        title: 'Yeni PDF Çıktı',
        icon: Icons.picture_as_pdf_outlined,
        leadingBack: true,
        fallbackRoute: '/pdf-outputs',
      ),
      sections: [
        if (_prefillWarning != null) ...[
          Card(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(_prefillWarning!)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (_sourceChipLabel() != null) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: Chip(
              avatar: const Icon(Icons.link, size: 16),
              label: Text(_sourceChipLabel()!),
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(height: 12),
        ],
        const PdfLetterheadPreviewCard(),
        const SizedBox(height: 12),
        FormSectionCard(
          title: 'Hasta ve Belge',
          icon: Icons.person_outline,
          children: [
            PatientSelectorField(
              selectedPatientId: patientId,
              lockSelection: _lockPatientFromRoute,
              enabled: !_saving && !_lockPatientFromRoute,
              isDense: true,
              onChanged: _saving || _lockPatientFromRoute
                  ? null
                  : (v) => setState(() => patientId = v),
              onPatientSelected: (p) => setState(
                () => _resolvedPatient = p,
              ),
            ),
            DropdownButtonFormField<DocumentType>(
              initialValue: docType,
              decoration: const InputDecoration(
                labelText: 'Belge Tipi',
                isDense: true,
              ),
              isExpanded: true,
              items: DocumentType.values
                  .map(
                    (d) => DropdownMenuItem(
                      value: d,
                      child: Text(
                        documentTypeLabel(d),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: _saving ? null : (v) => setState(() => docType = v),
            ),
            DropdownButtonFormField<PdfStatus>(
              initialValue: status,
              decoration: const InputDecoration(
                labelText: 'Durum',
                isDense: true,
              ),
              isExpanded: true,
              items: PdfStatus.values
                  .map(
                    (s) => DropdownMenuItem(
                      value: s,
                      child: Text(
                        pdfStatusLabel(s),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: _saving ? null : (v) => setState(() => status = v),
            ),
          ],
        ),
        FormSectionCard(
          title: 'Belge İçeriği',
          icon: Icons.description_outlined,
          children: [
            TextFormField(
              controller: titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Başlık',
                isDense: true,
              ),
              enabled: !_saving,
            ),
            TextFormField(
              controller: relatedDiag,
              decoration: const InputDecoration(
                labelText: 'İlgili Tanı',
                isDense: true,
              ),
              enabled: !_saving,
            ),
            TextFormField(
              controller: relatedPlan,
              decoration: const InputDecoration(
                labelText: 'İlgili Tedavi Planı',
                isDense: true,
              ),
              enabled: !_saving,
            ),
            TextFormField(
              controller: content,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'İçerik Özeti',
                alignLabelWithHint: true,
                isDense: true,
              ),
              enabled: !_saving,
            ),
            TextFormField(
              controller: warning,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Uyarı Notu',
                alignLabelWithHint: true,
                isDense: true,
              ),
              enabled: !_saving,
            ),
          ],
        ),
      ],
    );
  }
}
