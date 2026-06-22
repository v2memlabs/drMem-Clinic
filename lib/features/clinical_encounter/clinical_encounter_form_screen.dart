import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_session.dart';
import '../../core/data/repository_registry.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/clinical_state_message.dart';
import '../../shared/widgets/clinical_form_scaffold.dart';
import '../../shared/widgets/clinical_stacked_sections.dart';
import '../../shared/widgets/clinical_notice.dart';
import '../../shared/widgets/clinical_notice_tone.dart';
import '../../shared/widgets/page_header.dart';
import '../icd/widgets/icd_code_field.dart';
import 'models/clinical_treatment_approach.dart';
import 'data/clinical_encounter_diagnosis_display.dart';
import 'data/clinical_encounter_form_completion.dart';
import 'data/clinical_encounter_form_section_id.dart';
import 'data/assistant_clinical_summary_list_refresh.dart';
import 'data/clinical_encounter_list_refresh.dart';
import 'widgets/clinical_encounter_form_action_bar.dart';
import 'widgets/clinical_encounter_form_section.dart';
import 'widgets/clinical_encounter_form_section_index.dart';
import 'widgets/clinical_encounter_identity_band.dart';
import '../patients/data/quick_patient_create_data_source.dart';
import '../patients/models/patient.dart';
import '../patients/widgets/patient_selector_field.dart';
import '../patients/widgets/quick_patient_create_dialog.dart';
import 'data/clinical_encounter_form_data_source.dart';
import 'data/clinical_encounter_form_user_messages.dart';
import 'data/clinical_encounter_repository_failure.dart';
import 'data/clinical_encounter_repository_provider.dart';
import 'models/clinical_encounter.dart';
import 'post_encounter_wizard/post_encounter_wizard_coordinator.dart';
import 'post_encounter_wizard/widgets/patient_surgical_quote_banner.dart';

class ClinicalEncounterFormScreen extends StatefulWidget {
  final String? patientId;
  final String? appointmentId;
  final String? encounterId;

  const ClinicalEncounterFormScreen({
    super.key,
    this.patientId,
    this.appointmentId,
    this.encounterId,
  });

  bool get isEditMode => encounterId != null && encounterId!.isNotEmpty;

  @override
  State<ClinicalEncounterFormScreen> createState() => _ClinicalEncounterFormScreenState();
}

class _ClinicalEncounterFormScreenState extends State<ClinicalEncounterFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  late final Map<String, GlobalKey> _sectionKeys = {
    ClinicalEncounterFormSectionId.identity: GlobalKey(),
    for (final section in ClinicalEncounterFormSectionId.clinicalSections)
      section.id: GlobalKey(),
  };
  String? _activeSectionId = ClinicalEncounterFormSectionId.complaint;

  String? _patientId;
  ClinicalVisitType _visitType = ClinicalVisitType.ilkMuayene;
  ClinicalEncounterStatus _status = ClinicalEncounterStatus.taslak;
  ClinicalBodyRegion _bodyRegion = ClinicalBodyRegion.diz;
  ClinicalSide _side = ClinicalSide.sag;
  ClinicalDiagnosisType _diagnosisType = ClinicalDiagnosisType.dejeneratif;

  bool _traumaHistory = false;
  int _vasScore = 3;
  bool _nightPain = false;
  bool _sportsSectionEnabled = false;
  bool _sportsRelated = false;
  bool _physiotherapyReferral = false;
  DateTime? _controlDate;

  final _chiefComplaint = TextEditingController();
  final _complaintDuration = TextEditingController();
  final _painLocation = TextEditingController();
  final _painCharacter = TextEditingController();
  final _activityRelation = TextEditingController();
  final _previousTreatments = TextEditingController();
  final _medications = TextEditingController();
  final _allergies = TextEditingController();
  final _comorbidities = TextEditingController();
  final _previousSurgeries = TextEditingController();
  final _generalNotes = TextEditingController();
  final _sportBranch = TextEditingController();
  final _amateurOrProfessional = TextEditingController();
  final _trainingFrequency = TextEditingController();
  final _patientExpectation = TextEditingController();
  final _returnToSportGoal = TextEditingController();
  final _returnToSportPlan = TextEditingController();
  final _inspection = TextEditingController();
  final _palpation = TextEditingController();
  final _rangeOfMotion = TextEditingController();
  final _muscleStrength = TextEditingController();
  final _stabilityTests = TextEditingController();
  final _specialTests = TextEditingController();
  final _neurovascularStatus = TextEditingController();
  final _comparisonWithOtherSide = TextEditingController();
  final _clinicalImpression = TextEditingController();
  final _imagingSummary = TextEditingController();
  final _imagingDoctorComment = TextEditingController();
  final _attachedFileNote = TextEditingController();
  final _preliminaryDiagnosis = TextEditingController();
  final _finalDiagnosis = TextEditingController();
  final _differentialDiagnosis = TextEditingController();
  String _icdCode = '';
  String _icdTitle = '';
  final _conservativeTreatment = TextEditingController();
  final _medicationNotes = TextEditingController();
  final _injectionOrProcedurePlan = TextEditingController();
  final _exerciseRecommendation = TextEditingController();
  final _imagingRequest = TextEditingController();
  final _surgeryRecommendation = TextEditingController();
  final _patientInformationNote = TextEditingController();
  final _warningNotes = TextEditingController();
  final _internalDoctorNote = TextEditingController();
  final _orthosisNotes = TextEditingController();

  ClinicalTreatmentApproach? _treatmentApproach;

  DateTime? _createdAt;
  String? _doctorName;
  ClinicalEncounter? _existing;
  Patient? _resolvedPatientForName;
  bool _showQuickCreatedProfileHint = false;

  bool _loaded = false;
  bool _saving = false;
  String? _initError;

  bool get _usesRemote => RepositoryRegistry.usesRemoteClinicalEncounters;

  bool get _lockPatientFromRoute =>
      !widget.isEditMode &&
      widget.patientId != null &&
      widget.patientId!.trim().isNotEmpty;

  bool get _canShowQuickPatientCreate =>
      !widget.isEditMode &&
      !_lockPatientFromRoute &&
      !_saving &&
      AuthSession.canEditClinicalEncounters &&
      AuthSession.canEditPatients;

  String? _effectivePatientId() {
    final stateId = _patientId?.trim();
    if (stateId != null && stateId.isNotEmpty) return stateId;
    final routeId = widget.patientId?.trim();
    if (routeId != null && routeId.isNotEmpty) return routeId;
    return null;
  }

  bool get _locksPreliminaryDiagnosis =>
      _finalDiagnosis.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _finalDiagnosis.addListener(_onFinalDiagnosisChanged);
    _patientId = widget.patientId?.trim().isNotEmpty == true
        ? widget.patientId!.trim()
        : null;
    _initForm();
  }

  void _onFinalDiagnosisChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _initForm() async {
    if (!widget.isEditMode) {
      final pid = _effectivePatientId();
      if (pid != null) {
        final exists = await ClinicalEncounterFormDataSource.patientExists(pid);
        if (!exists && mounted) {
          setState(() {
            _loaded = true;
            _initError =
                'Hasta kaydı bulunamadı veya erişim yok. Lütfen hasta detayından tekrar deneyin.';
          });
          return;
        }
      }
      if (mounted) setState(() => _loaded = true);
      return;
    }

    try {
      final existing =
          await ClinicalEncounterFormDataSource.loadForEdit(widget.encounterId!);
      if (existing == null) {
        if (mounted) {
          setState(() {
            _loaded = true;
            _initError = 'Muayene kaydı bulunamadı.';
          });
        }
        return;
      }

      _existing = existing;
      _populateFromEncounter(existing);
      if (mounted) setState(() => _loaded = true);
    } on ClinicalEncounterRepositoryException catch (e) {
      if (mounted) {
        setState(() {
          _loaded = true;
          _initError = ClinicalEncounterFormUserMessages.forFailure(
            e.reason,
            isEdit: true,
          );
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loaded = true;
          _initError = ClinicalEncounterFormUserMessages.loadFailure;
        });
      }
    }
  }

  void _populateFromEncounter(ClinicalEncounter e) {
    _patientId = e.patientId;
    _createdAt = e.createdAt;
    _doctorName = e.doctorName;
    _visitType = e.visitType;
    _status = e.status;
    _bodyRegion = e.bodyRegion;
    _side = e.side;
    _diagnosisType = e.diagnosisType;
    _traumaHistory = e.traumaHistory;
    _vasScore = e.vasScore;
    _nightPain = e.nightPain;
    _sportsSectionEnabled = e.sportsSectionEnabled;
    _sportsRelated = e.sportsRelated;
    _physiotherapyReferral = e.physiotherapyReferral;
    _controlDate = e.controlDate;
    _chiefComplaint.text = e.chiefComplaint;
    _complaintDuration.text = e.complaintDuration;
    _painLocation.text = e.painLocation;
    _painCharacter.text = e.painCharacter;
    _activityRelation.text = e.activityRelation;
    _previousTreatments.text = e.previousTreatments;
    _medications.text = e.medications;
    _allergies.text = e.allergies;
    _comorbidities.text = e.comorbidities;
    _previousSurgeries.text = e.previousSurgeries;
    _generalNotes.text = e.generalNotes;
    _sportBranch.text = e.sportBranch;
    _amateurOrProfessional.text = e.amateurOrProfessional;
    _trainingFrequency.text = e.trainingFrequency;
    _patientExpectation.text = e.patientExpectation;
    _returnToSportGoal.text = e.returnToSportGoal;
    _returnToSportPlan.text = e.returnToSportPlan;
    _inspection.text = e.inspection;
    _palpation.text = e.palpation;
    _rangeOfMotion.text = e.rangeOfMotion;
    _muscleStrength.text = e.muscleStrength;
    _stabilityTests.text = e.stabilityTests;
    _specialTests.text = e.specialTests;
    _neurovascularStatus.text = e.neurovascularStatus;
    _comparisonWithOtherSide.text = e.comparisonWithOtherSide;
    _clinicalImpression.text = e.clinicalImpression;
    _imagingSummary.text = e.imagingSummary;
    _imagingDoctorComment.text = e.imagingDoctorComment;
    _attachedFileNote.text = e.attachedFileNote;
    _preliminaryDiagnosis.text = e.preliminaryDiagnosis;
    _finalDiagnosis.text = e.finalDiagnosis;
    _differentialDiagnosis.text = e.differentialDiagnosis;
    _icdCode = e.icdCode;
    _icdTitle = e.icdTitle;
    _conservativeTreatment.text = e.conservativeTreatment;
    _medicationNotes.text = e.medicationNotes;
    _injectionOrProcedurePlan.text = e.injectionOrProcedurePlan;
    _exerciseRecommendation.text = e.exerciseRecommendation;
    _imagingRequest.text = e.imagingRequest;
    _surgeryRecommendation.text = e.surgeryRecommendation;
    _patientInformationNote.text = e.patientInformationNote;
    _warningNotes.text = e.warningNotes;
    _internalDoctorNote.text = e.internalDoctorNote;
    _orthosisNotes.text = e.orthosisNotes;
    _treatmentApproach = e.treatmentApproach;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    for (final c in [
      _chiefComplaint,
      _complaintDuration,
      _painLocation,
      _painCharacter,
      _activityRelation,
      _previousTreatments,
      _medications,
      _allergies,
      _comorbidities,
      _previousSurgeries,
      _generalNotes,
      _sportBranch,
      _amateurOrProfessional,
      _trainingFrequency,
      _patientExpectation,
      _returnToSportGoal,
      _returnToSportPlan,
      _inspection,
      _palpation,
      _rangeOfMotion,
      _muscleStrength,
      _stabilityTests,
      _specialTests,
      _neurovascularStatus,
      _comparisonWithOtherSide,
      _clinicalImpression,
      _imagingSummary,
      _imagingDoctorComment,
      _attachedFileNote,
      _preliminaryDiagnosis,
      _finalDiagnosis,
      _differentialDiagnosis,
      _conservativeTreatment,
      _medicationNotes,
      _injectionOrProcedurePlan,
      _exerciseRecommendation,
      _imagingRequest,
      _surgeryRecommendation,
      _patientInformationNote,
      _warningNotes,
      _internalDoctorNote,
      _orthosisNotes,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickControlDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _controlDate ?? DateTime.now().add(const Duration(days: 21)),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) setState(() => _controlDate = picked);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _openQuickPatientCreate() async {
    if (!_canShowQuickPatientCreate) return;

    final created = await showQuickPatientCreateDialog(context);
    if (!mounted || created == null) return;

    setState(() {
      _patientId = created.id;
      _resolvedPatientForName = created;
      _showQuickCreatedProfileHint =
          QuickPatientCreateDataSource.isProfilePartiallyComplete(created);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _formKey.currentState?.validate();
    });

    _showMessage(
      'Hasta oluşturuldu ve muayene formuna eklendi. '
      'Hasta profilindeki eksik bilgileri daha sonra tamamlayabilirsiniz.',
    );
  }

  Future<ClinicalEncounter?> _buildEncounterFromForm() async {
    if (!widget.isEditMode) {
      final pid = _effectivePatientId();
      if (pid == null || pid.isEmpty) {
        _showMessage('Lütfen hasta seçin.');
        return null;
      }
      if (!await ClinicalEncounterFormDataSource.patientExists(pid)) {
        _showMessage('Seçilen hasta bulunamadı. Lütfen tekrar seçin.');
        return null;
      }
    }

    final now = DateTime.now();
    final pid = widget.isEditMode ? _existing!.patientId : _effectivePatientId()!;
    final patientName = widget.isEditMode
        ? _existing!.patientName
        : await ClinicalEncounterFormDataSource.resolvePatientName(
            patientId: pid,
            selectedPatient: _resolvedPatientForName,
          );

    return ClinicalEncounter(
      id: widget.isEditMode ? _existing!.id : '',
      protocolNumber: widget.isEditMode ? _existing!.protocolNumber : '',
      patientId: pid,
      patientName: patientName,
      createdAt: widget.isEditMode ? (_createdAt ?? now) : now,
      updatedAt: now,
      doctorName: _doctorName ?? ClinicalEncounterFormDataSource.defaultDoctorName(),
      status: _status,
      visitType: _visitType,
      bodyRegion: _bodyRegion,
      side: _side,
      chiefComplaint: _chiefComplaint.text.trim(),
      complaintDuration: _complaintDuration.text.trim(),
      traumaHistory: _traumaHistory,
      painLocation: _painLocation.text.trim(),
      painCharacter: _painCharacter.text.trim(),
      vasScore: _vasScore,
      nightPain: _nightPain,
      activityRelation: _activityRelation.text.trim(),
      previousTreatments: _previousTreatments.text.trim(),
      medications: _medications.text.trim(),
      allergies: _allergies.text.trim(),
      comorbidities: _comorbidities.text.trim(),
      previousSurgeries: _previousSurgeries.text.trim(),
      generalNotes: _generalNotes.text.trim(),
      sportsSectionEnabled: _sportsSectionEnabled,
      sportBranch: _sportBranch.text.trim(),
      amateurOrProfessional: _amateurOrProfessional.text.trim(),
      trainingFrequency: _trainingFrequency.text.trim(),
      patientExpectation: _patientExpectation.text.trim(),
      returnToSportGoal: _returnToSportGoal.text.trim(),
      sportsRelated: _sportsRelated,
      returnToSportPlan: _returnToSportPlan.text.trim(),
      inspection: _inspection.text.trim(),
      palpation: _palpation.text.trim(),
      rangeOfMotion: _rangeOfMotion.text.trim(),
      muscleStrength: _muscleStrength.text.trim(),
      stabilityTests: _stabilityTests.text.trim(),
      specialTests: _specialTests.text.trim(),
      neurovascularStatus: _neurovascularStatus.text.trim(),
      comparisonWithOtherSide: _comparisonWithOtherSide.text.trim(),
      clinicalImpression: _clinicalImpression.text.trim(),
      imagingSummary: _imagingSummary.text.trim(),
      imagingDoctorComment: _imagingDoctorComment.text.trim(),
      attachedFileNote: _attachedFileNote.text.trim(),
      preliminaryDiagnosis: _preliminaryDiagnosis.text.trim(),
      finalDiagnosis: _finalDiagnosis.text.trim(),
      differentialDiagnosis: _differentialDiagnosis.text.trim(),
      diagnosisType: _diagnosisType,
      icdCode: _icdCode.trim(),
      icdTitle: _icdTitle.trim(),
      planTitle: '',
      conservativeTreatment: _conservativeTreatment.text.trim(),
      medicationNotes: _medicationNotes.text.trim(),
      injectionOrProcedurePlan: _injectionOrProcedurePlan.text.trim(),
      physiotherapyReferral: _physiotherapyReferral,
      exerciseRecommendation: _exerciseRecommendation.text.trim(),
      imagingRequest: _imagingRequest.text.trim(),
      controlDate: _controlDate,
      surgeryRecommendation: _surgeryRecommendation.text.trim(),
      patientInformationNote: _patientInformationNote.text.trim(),
      warningNotes: _warningNotes.text.trim(),
      internalDoctorNote: AuthSession.canViewFullClinicalEncounter
          ? _internalDoctorNote.text.trim()
          : '',
      orthosisNotes: _orthosisNotes.text.trim(),
      treatmentApproach: _treatmentApproach,
    );
  }

  Future<void> _save() async {
    if (_saving || !_loaded) return;
    if (_initError != null) return;

    final effectivePid = _effectivePatientId();
    if (effectivePid != null && effectivePid.isNotEmpty) {
      _patientId = effectivePid;
    }

    final pidForSave = _effectivePatientId();
    if (pidForSave == null || pidForSave.isEmpty) {
      _showMessage('Lütfen hasta seçin.');
      _scrollToSection(ClinicalEncounterFormSectionId.identity);
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) {
      _showMessage('Lütfen eksik veya hatalı alanları kontrol edin.');
      _scrollToValidationTarget();
      return;
    }

    if (widget.isEditMode && _existing == null) {
      _showMessage('Muayene kaydı bulunamadı.');
      return;
    }

    final draft = await _buildEncounterFromForm();
    if (draft == null) return;

    ClinicalEncounterRepositoryProvider.resetCache();
    setState(() => _saving = true);

    try {
      final saved = widget.isEditMode
          ? await ClinicalEncounterFormDataSource.update(draft)
          : await ClinicalEncounterFormDataSource.create(draft);

      if (!mounted) return;
      ClinicalEncounterListRefresh.markStale();
      AssistantClinicalSummaryListRefresh.markStale();
      _showMessage(
        ClinicalEncounterFormUserMessages.successMessage(
          isEdit: widget.isEditMode,
          usesRemote: _usesRemote,
        ),
      );
      if (widget.isEditMode) {
        context.go('/clinical-records/${saved.id}');
      } else {
        await PostEncounterWizardCoordinator.start(context, saved);
      }
    } on ClinicalEncounterRepositoryException catch (e) {
      if (!mounted) return;
      _showMessage(
        ClinicalEncounterFormUserMessages.forFailure(
          e.reason,
          isEdit: widget.isEditMode,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      _showMessage(
        ClinicalEncounterFormUserMessages.forFailure(
          ClinicalEncounterRepositoryFailure.unknown,
          isEdit: widget.isEditMode,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _cancel() {
    if (_saving) return;
    if (context.canPop()) {
      context.pop();
      return;
    }
    if (widget.isEditMode && widget.encounterId != null) {
      context.go('/clinical-records/${widget.encounterId}');
      return;
    }
    context.go('/clinical-records');
  }

  String get _savingStatusText =>
      ClinicalEncounterFormUserMessages.savingMessage(isEdit: widget.isEditMode);

  void _scrollToSection(String sectionId) {
    final key = _sectionKeys[sectionId];
    final context = key?.currentContext;
    if (context == null) return;
    setState(() => _activeSectionId = sectionId);
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
      alignment: 0.08,
    );
  }

  void _scrollToValidationTarget() {
    final pid = _effectivePatientId();
    if (pid == null || pid.isEmpty) {
      _scrollToSection(ClinicalEncounterFormSectionId.identity);
      return;
    }
    _scrollToSection(ClinicalEncounterFormSectionId.complaint);
  }

  bool _isSectionFilled(String sectionId) {
    return ClinicalEncounterFormCompletion.isSectionFilled(
      sectionId,
      showPrivateNoteSection: AuthSession.canViewFullClinicalEncounter,
      chiefComplaint: _chiefComplaint.text,
      generalNotes: _generalNotes.text,
      medications: _medications.text,
      complaintDuration: _complaintDuration.text,
      painLocation: _painLocation.text,
      painCharacter: _painCharacter.text,
      activityRelation: _activityRelation.text,
      previousTreatments: _previousTreatments.text,
      allergies: _allergies.text,
      comorbidities: _comorbidities.text,
      previousSurgeries: _previousSurgeries.text,
      traumaHistory: _traumaHistory,
      nightPain: _nightPain,
      sportsSectionEnabled: _sportsSectionEnabled,
      sportBranch: _sportBranch.text,
      amateurOrProfessional: _amateurOrProfessional.text,
      trainingFrequency: _trainingFrequency.text,
      patientExpectation: _patientExpectation.text,
      returnToSportGoal: _returnToSportGoal.text,
      returnToSportPlan: _returnToSportPlan.text,
      sportsRelated: _sportsRelated,
      inspection: _inspection.text,
      palpation: _palpation.text,
      rangeOfMotion: _rangeOfMotion.text,
      muscleStrength: _muscleStrength.text,
      stabilityTests: _stabilityTests.text,
      specialTests: _specialTests.text,
      neurovascularStatus: _neurovascularStatus.text,
      comparisonWithOtherSide: _comparisonWithOtherSide.text,
      clinicalImpression: _clinicalImpression.text,
      imagingSummary: _imagingSummary.text,
      imagingDoctorComment: _imagingDoctorComment.text,
      attachedFileNote: _attachedFileNote.text,
      preliminaryDiagnosis: _preliminaryDiagnosis.text,
      finalDiagnosis: _finalDiagnosis.text,
      differentialDiagnosis: _differentialDiagnosis.text,
      icdCode: _icdCode,
      planTitle: '',
      conservativeTreatment: _conservativeTreatment.text,
      medicationNotes: _medicationNotes.text,
      injectionOrProcedurePlan: _injectionOrProcedurePlan.text,
      orthosisNotes: _orthosisNotes.text,
      surgeryRecommendation: _surgeryRecommendation.text,
      treatmentApproach: _treatmentApproach,
      physiotherapyReferral: _physiotherapyReferral,
      exerciseRecommendation: _exerciseRecommendation.text,
      imagingRequest: _imagingRequest.text,
      controlDate: _controlDate,
      status: _status,
      patientInformationNote: _patientInformationNote.text,
      warningNotes: _warningNotes.text,
      internalDoctorNote: _internalDoctorNote.text,
    );
  }

  List<({String id, String label, bool isFilled})> _indexSections() {
    return [
      for (final section in ClinicalEncounterFormSectionId.clinicalSections)
        if (section.id != ClinicalEncounterFormSectionId.privateNote ||
            AuthSession.canViewFullClinicalEncounter)
          (
            id: section.id,
            label: section.label,
            isFilled: _isSectionFilled(section.id),
          ),
    ];
  }

  Widget _clinicalSection({
    required String sectionId,
    required String title,
    String? subtitle,
    IconData? icon,
    required List<Widget> children,
  }) {
    return ClinicalEncounterFormSection(
      sectionKey: _sectionKeys[sectionId],
      title: title,
      subtitle: subtitle,
      icon: icon,
      showFilledIndicator: _isSectionFilled(sectionId),
      children: children,
    );
  }

  Widget _field(
    TextEditingController c,
    String label, {
    int maxLines = 1,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextFormField(
        controller: c,
        maxLines: maxLines,
        enabled: enabled,
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          alignLabelWithHint: maxLines > 1,
        ),
      ),
    );
  }

  Widget _dropdown<T>({
    required T value,
    required String label,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DropdownButtonFormField<T>(
        value: value,
        isExpanded: true,
        decoration: InputDecoration(labelText: label, isDense: true),
        items: items,
        onChanged: onChanged,
      ),
    );
  }

  Widget _treatmentApproachDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DropdownButtonFormField<ClinicalTreatmentApproach?>(
        value: _treatmentApproach,
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'Tedavi Yaklaşımı',
          isDense: true,
        ),
        items: [
          const DropdownMenuItem<ClinicalTreatmentApproach?>(
            value: null,
            child: Text('Belirtilmedi'),
          ),
          ...ClinicalTreatmentApproach.values.map(
            (a) => DropdownMenuItem(
              value: a,
              child: Text(a.label, overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
        onChanged: (v) => setState(() => _treatmentApproach = v),
      ),
    );
  }

  Widget _regionSideRow() {
    return LayoutBuilder(
      builder: (context, rowConstraints) {
        final stacked = rowConstraints.maxWidth < 480;
        final regionDropdown = _dropdown<ClinicalBodyRegion>(
          value: _bodyRegion,
          label: 'Bölge',
          items: ClinicalBodyRegion.values
              .map(
                (r) => DropdownMenuItem(
                  value: r,
                  child: Text(r.label, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) setState(() => _bodyRegion = v);
          },
        );
        final sideDropdown = _dropdown<ClinicalSide>(
          value: _side,
          label: 'Taraf',
          items: ClinicalSide.values
              .map(
                (s) => DropdownMenuItem(
                  value: s,
                  child: Text(s.label, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) setState(() => _side = v);
          },
        );
        if (stacked) {
          return Column(children: [regionDropdown, sideDropdown]);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: regionDropdown),
            const SizedBox(width: 12),
            Expanded(child: sideDropdown),
          ],
        );
      },
    );
  }

  Widget _buildFormIdentityBand() {
    final patientName = _resolvedPatientForName?.fullName ??
        _existing?.patientName ??
        'Hasta seçin';
    final dateLabel = widget.isEditMode && _createdAt != null
        ? '${_createdAt!.day.toString().padLeft(2, '0')}.${_createdAt!.month.toString().padLeft(2, '0')}.${_createdAt!.year}'
        : 'Yeni kayıt';

    final fileNo = _resolvedPatientForName?.fileNumber?.trim();
    return ClinicalEncounterIdentityBand(
      patientName: patientName,
      demographicLine:
          fileNo != null && fileNo.isNotEmpty ? 'Dosya: $fileNo' : null,
      encounterDateLabel: dateLabel,
      compact: true,
    );
  }

  String _encounterFormFallbackRoute() {
    final pid = _patientId ?? widget.patientId;
    if (pid != null && pid.isNotEmpty) {
      return '/patients/$pid';
    }
    return '/clinical-records';
  }

  @override
  Widget build(BuildContext context) {
    final screenTitle =
        widget.isEditMode ? 'Muayene Kaydı Düzenle' : 'Yeni Muayene Kaydı';

    if (!_loaded) {
      return AppShell(
        title: screenTitle,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator.adaptive(),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  widget.isEditMode
                      ? 'Muayene formu yükleniyor...'
                      : 'Yeni muayene formu hazırlanıyor...',
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_initError != null) {
      return AppShell(
        title: screenTitle,
        child: ClinicalStateMessage.error(
          icon: Icons.error_outline,
          title: 'Form yüklenemedi',
          description: ClinicalStateMessage.safeErrorDescription(_initError),
        ),
      );
    }

    final savingBanner = _saving
        ? Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.xs,
              AppSpacing.md,
              AppSpacing.xs,
            ),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Row(
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    _savingStatusText,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          )
        : null;

    return ClinicalFormScaffold(
      shellTitle: screenTitle,
      formKey: _formKey,
      scrollController: _scrollController,
      scrollViewKey: const Key('clinical_encounter_form_scroll'),
      listCacheExtent: 12000,
      listPadding: const EdgeInsets.only(bottom: AppSpacing.xl),
      absorbPointer: _saving,
      headerBanner: savingBanner,
      bottomBar: ClinicalEncounterFormActionBar(
        isEditMode: widget.isEditMode,
        saving: _saving,
        onSave: _save,
        onCancel: _cancel,
      ),
      onSave: _save,
      onCancel: _cancel,
      saveLabel:
          widget.isEditMode ? 'Değişiklikleri Kaydet' : 'Muayene Kaydet',
      saving: _saving,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
                          PageHeader(
                            title: widget.isEditMode
                                ? 'Muayene Kaydı Düzenle'
                                : 'Yeni Muayene Kaydı',
                            icon: Icons.assignment_outlined,
                            leadingBack: true,
                            fallbackRoute: _encounterFormFallbackRoute(),
                          ),
                          if (_patientId != null && _patientId!.isNotEmpty)
                            PatientSurgicalQuoteBanner(
                              patientId: _patientId!,
                            ),
                          ClinicalStackedSections(
                            children: [
                          ClinicalEncounterFormSection(
                            sectionKey: _sectionKeys[ClinicalEncounterFormSectionId.identity],
                            title: 'Hasta / Muayene Kimlik',
                            subtitle: 'Hasta ve muayene kimlik bilgileri',
                            icon: Icons.badge_outlined,
                            children: [
                              PatientSelectorField(
                                selectedPatientId: _patientId,
                                selectedPatientPreview: _resolvedPatientForName,
                                lockSelection: _lockPatientFromRoute,
                                enabled: !widget.isEditMode &&
                                    !_saving &&
                                    !_lockPatientFromRoute,
                                onChanged: widget.isEditMode || _saving
                                    ? null
                                    : (v) => setState(() {
                                          _patientId = v;
                                          _showQuickCreatedProfileHint = false;
                                        }),
                                onPatientSelected: (p) => setState(
                                  () => _resolvedPatientForName = p,
                                ),
                              ),
                              if (_canShowQuickPatientCreate) ...[
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: TextButton.icon(
                                    key: const Key('clinical_encounter_quick_patient_create'),
                                    onPressed: _openQuickPatientCreate,
                                    icon: const Icon(Icons.person_add_outlined, size: 18),
                                    label: const Text('Yeni Hasta'),
                                  ),
                                ),
                              ],
                              if (_showQuickCreatedProfileHint) ...[
                                ClinicalNotice(
                                  tone: ClinicalNoticeTone.info,
                                  dense: true,
                                  message:
                                      'Bu hasta hızlı oluşturuldu. Profil bilgileri daha sonra hasta kartından tamamlanabilir.',
                                ),
                                const SizedBox(height: AppSpacing.xs),
                              ],
                              _buildFormIdentityBand(),
                              if (widget.isEditMode &&
                                  _existing != null &&
                                  _existing!.hasProtocolNumber) ...[
                                InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'Protokol No',
                                    isDense: true,
                                  ),
                                  child: Text(
                                    _existing!.displayProtocolNumber,
                                    style:
                                        Theme.of(context).textTheme.bodyLarge,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                              ],
                              _dropdown<ClinicalVisitType>(
                                value: _visitType,
                                label: 'Başvuru Tipi',
                                items: ClinicalVisitType.values
                                    .map(
                                      (v) => DropdownMenuItem(
                                        value: v,
                                        child: Text(
                                          v.label,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) {
                                  if (v != null) setState(() => _visitType = v);
                                },
                              ),
                              _regionSideRow(),
                            ],
                          ),
                            ],
                          ),
                          ClinicalEncounterFormSectionIndex(
                            sections: _indexSections(),
                            activeSectionId: _activeSectionId,
                            onSectionSelected: _scrollToSection,
                          ),
                          ClinicalStackedSections(
                            children: [
                          _clinicalSection(
                            sectionId: ClinicalEncounterFormSectionId.complaint,
                            title: 'Şikayet / Hikaye',
                            subtitle: 'Şikayet, hikaye ve ilaç bilgileri',
                            icon: Icons.record_voice_over_outlined,
                            children: [
                            _field(_chiefComplaint, 'Ana Şikayet', maxLines: 2),
                            _field(_generalNotes, 'Hikaye', maxLines: 4),
                            _field(_medications, 'Kullandığı İlaçlar', maxLines: 2),
                            _field(_complaintDuration, 'Şikayet Süresi'),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              title: const Text('Travma Öyküsü'),
                              value: _traumaHistory,
                              onChanged: (v) => setState(() => _traumaHistory = v),
                            ),
                            _field(_painLocation, 'Ağrı Yeri'),
                            _field(_painCharacter, 'Ağrı Karakteri'),
                            Row(
                              children: [
                                Text(
                                  'VAS Skoru',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                Expanded(
                                  child: Slider(
                                    value: _vasScore.toDouble(),
                                    min: 0,
                                    max: 10,
                                    divisions: 10,
                                    label: '$_vasScore',
                                    onChanged: (v) => setState(() => _vasScore = v.round()),
                                  ),
                                ),
                              ],
                            ),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              title: const Text('Gece Ağrısı'),
                              value: _nightPain,
                              onChanged: (v) => setState(() => _nightPain = v),
                            ),
                            _field(_activityRelation, 'Aktivite ile İlişki'),
                            _field(_previousTreatments, 'Önceki Tedaviler', maxLines: 2),
                            _field(_allergies, 'Alerjiler'),
                            _field(_comorbidities, 'Eşlik Eden Hastalıklar', maxLines: 2),
                            _field(_previousSurgeries, 'Önceki Cerrahiler', maxLines: 2),
                            const Divider(height: 20),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              title: const Text('Spor / Aktivite Bilgisi (opsiyonel)'),
                              value: _sportsSectionEnabled,
                              onChanged: (v) => setState(() => _sportsSectionEnabled = v),
                            ),
                            if (_sportsSectionEnabled) ...[
                              _field(_sportBranch, 'Spor Branşı'),
                              _field(_amateurOrProfessional, 'Amatör / Profesyonel'),
                              _field(_trainingFrequency, 'Antrenman Sıklığı'),
                              _field(_patientExpectation, 'Hasta Beklentisi', maxLines: 2),
                              _field(_returnToSportGoal, 'Spora Dönüş Hedefi'),
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                                title: const Text('Spor İlişkili'),
                                value: _sportsRelated,
                                onChanged: (v) => setState(() => _sportsRelated = v),
                              ),
                              _field(_returnToSportPlan, 'Spora Dönüş Planı', maxLines: 2),
                            ],
                          ],
                          ),
                          _clinicalSection(
                            sectionId: ClinicalEncounterFormSectionId.examination,
                            title: 'Muayene',
                            subtitle: 'Klinik izlenim ve muayene bulguları',
                            icon: Icons.monitor_heart_outlined,
                            children: [
                            _field(_clinicalImpression, 'Klinik İzlenim / Muayene Bulgusu', maxLines: 4),
                            _field(_inspection, 'İnspeksiyon', maxLines: 3),
                            _field(_palpation, 'Palpasyon', maxLines: 3),
                            _field(_rangeOfMotion, 'Hareket Açıklığı (ROM)', maxLines: 3),
                            _field(_muscleStrength, 'Kas Gücü', maxLines: 2),
                            _field(_stabilityTests, 'Stabilite Testleri', maxLines: 3),
                            _field(_specialTests, 'Özel Testler', maxLines: 3),
                            _field(_neurovascularStatus, 'Nörovasküler Durum', maxLines: 2),
                            _field(_comparisonWithOtherSide, 'Karşı Taraf ile Karşılaştırma', maxLines: 2),
                          ],
                          ),
                          _clinicalSection(
                            sectionId: ClinicalEncounterFormSectionId.imaging,
                            title: 'Görüntüleme',
                            subtitle: 'Görüntüleme notları',
                            icon: Icons.image_search_outlined,
                            children: [
                            _field(_imagingSummary, 'Görüntüleme Notları', maxLines: 4),
                            _field(_imagingDoctorComment, 'Görüntüleme Hekim Yorumu', maxLines: 3),
                            _field(_attachedFileNote, 'Ek Dosya Notu', maxLines: 2),
                          ],
                          ),
                          _clinicalSection(
                            sectionId: ClinicalEncounterFormSectionId.diagnosis,
                            title: ClinicalEncounterDiagnosisDisplay.sectionTitle,
                            subtitle: 'Tanı ve ICD-10 bilgisi',
                            icon: Icons.healing_outlined,
                            children: [
                            _field(
                              _preliminaryDiagnosis,
                              'Ön tanı',
                              maxLines: 3,
                              enabled: !_locksPreliminaryDiagnosis,
                            ),
                            _field(
                              _differentialDiagnosis,
                              'Ayırıcı tanı',
                              maxLines: 2,
                              enabled: !_locksPreliminaryDiagnosis,
                            ),
                            _field(_finalDiagnosis, 'Kesin tanı', maxLines: 3),
                            IcdCodeField(
                              initialCode: _icdCode,
                              initialTitle: _icdTitle.isEmpty ? null : _icdTitle,
                              labelText: 'ICD-10 kodu',
                              onChanged: (code, selected) {
                                setState(() {
                                  _icdCode = code;
                                  _icdTitle = selected?.titleTr ?? '';
                                });
                              },
                            ),
                            _dropdown<ClinicalDiagnosisType>(
                              value: _diagnosisType,
                              label: 'Tanı Tipi',
                              items: ClinicalDiagnosisType.values
                                  .map(
                                    (t) => DropdownMenuItem(
                                      value: t,
                                      child: Text(t.label, overflow: TextOverflow.ellipsis),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) {
                                if (v != null) setState(() => _diagnosisType = v);
                              },
                            ),
                          ],
                          ),
                          _clinicalSection(
                            sectionId: ClinicalEncounterFormSectionId.treatment,
                            title: 'Tedavi Planı',
                            subtitle: 'Tedavi yaklaşımı ve plan notları',
                            icon: Icons.medical_information_outlined,
                            children: [
                            _treatmentApproachDropdown(),
                            _field(_conservativeTreatment, 'Konservatif Tedavi', maxLines: 4),
                            _field(_medicationNotes, 'İlaç Notu', maxLines: 3),
                            _field(_injectionOrProcedurePlan, 'Enjeksiyon / İşlem Planı', maxLines: 3),
                            _field(_orthosisNotes, 'Ortez / Atel / Destek', maxLines: 3),
                            _field(_surgeryRecommendation, 'Ameliyat / Girişim Önerisi', maxLines: 2),
                          ],
                          ),
                          _clinicalSection(
                            sectionId: ClinicalEncounterFormSectionId.followUp,
                            title: 'Fizyoterapi / Egzersiz / Kontrol',
                            subtitle: 'FTR, egzersiz ve kontrol planı',
                            icon: Icons.event_note_outlined,
                            children: [
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              title: const Text('Fizyoterapi Yönlendirmesi'),
                              value: _physiotherapyReferral,
                              onChanged: (v) => setState(() => _physiotherapyReferral = v),
                            ),
                            _field(_exerciseRecommendation, 'FTR / Egzersiz Planı', maxLines: 4),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _controlDate == null
                                        ? 'Kontrol tarihi seçilmedi'
                                        : 'Kontrol: ${_controlDate!.day.toString().padLeft(2, '0')}.${_controlDate!.month.toString().padLeft(2, '0')}.${_controlDate!.year}',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                FilledButton.tonal(
                                  onPressed: _pickControlDate,
                                  child: const Text('Tarih Seç'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _dropdown<ClinicalEncounterStatus>(
                              value: _status,
                              label: 'Kayıt Durumu',
                              items: ClinicalEncounterStatus.values
                                  .map(
                                    (s) => DropdownMenuItem(
                                      value: s,
                                      child: Text(s.label, overflow: TextOverflow.ellipsis),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) {
                                if (v != null) setState(() => _status = v);
                              },
                            ),
                            _field(_imagingRequest, 'Görüntüleme İstemi', maxLines: 2),
                            _field(_patientInformationNote, 'Hasta Bilgilendirme Notu', maxLines: 3),
                            _field(_warningNotes, 'Uyarılar', maxLines: 2),
                          ],
                          ),
                          if (AuthSession.canViewFullClinicalEncounter)
                            _clinicalSection(
                              sectionId: ClinicalEncounterFormSectionId.privateNote,
                              title: 'Özel Not',
                              subtitle: 'Yalnızca yetkili hekim görür',
                              icon: Icons.lock_outline,
                              children: [
                                _field(
                                  _internalDoctorNote,
                                  'Özel Not',
                                  maxLines: 4,
                                ),
                              ],
                            ),
                            ],
                          ),
                        ],
      ),
    );
  }
}
