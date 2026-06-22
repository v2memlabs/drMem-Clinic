import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_session.dart';
import '../../../shared/widgets/clinical_form_scaffold.dart';
import '../../../shared/widgets/form_section_card.dart';
import '../../../shared/widgets/page_header.dart';
import '../../patients/data/patient_lookup_data_source.dart';
import '../../patients/models/patient.dart';
import '../../patients/widgets/patient_selector_field.dart';
import '../data/physiotherapy_referral_lookup_data_source.dart';
import '../data/physiotherapy_referral_user_messages.dart';
import '../data/physiotherapy_session_form_data_source.dart';
import '../data/physiotherapy_session_repository_provider.dart';
import '../data/physiotherapy_session_user_messages.dart';
import '../models/physiotherapy_referral.dart';
import '../models/physiotherapy_session_note.dart';
import '../referral_record_prefill.dart';

class PhysiotherapySessionFormScreen extends StatefulWidget {
  final String? patientId;
  final String? referralId;

  const PhysiotherapySessionFormScreen({
    super.key,
    this.patientId,
    this.referralId,
  });

  @override
  State<PhysiotherapySessionFormScreen> createState() =>
      _PhysiotherapySessionFormScreenState();
}

class _PhysiotherapySessionFormScreenState
    extends State<PhysiotherapySessionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _sessionDateCtrl = TextEditingController();
  final _physioController = TextEditingController();
  final _romController = TextEditingController();
  final _strengthController = TextEditingController();
  final _functionalController = TextEditingController();
  final _exercisesController = TextEditingController();
  final _homeComplianceController = TextEditingController();
  final _warningController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedPatientId;
  String? _selectedPatientName;
  Patient? _selectedPatientPreview;
  String? _referralId;
  String? _referralPatientId;
  bool _lockPatient = false;
  int _pain = 0;
  ReturnToSportStage _returnStage = ReturnToSportStage.uygun_degil;
  bool _doctorNotificationNeeded = false;
  bool _referralPrefillLoading = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedPatientId = widget.patientId;
    _referralId = widget.referralId;
    final now = DateTime.now();
    _sessionDateCtrl.text =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    _applyReferralPrefill();
  }

  Future<void> _applyReferralPrefill() async {
    final refId = widget.referralId?.trim();
    if (refId == null || refId.isEmpty) return;

    setState(() => _referralPrefillLoading = true);
    final result = await PhysiotherapyReferralLookupDataSource.getById(refId);
    if (!mounted) return;

    final referral = result.referral;
    if (referral != null) {
      _applyReferralFields(referral);
    }

    setState(() => _referralPrefillLoading = false);
  }

  void _applyReferralFields(PhysiotherapyReferral referral) {
    _referralId = referral.id;
    _referralPatientId = referral.patientId;
    _selectedPatientId = referral.patientId;
    _selectedPatientName = referral.patientName;
    _selectedPatientPreview = _buildPatientPreview(
      patientId: referral.patientId,
      fullName: referral.patientName,
    );
    _lockPatient = true;

    if (referral.physiotherapistName.trim().isNotEmpty &&
        referral.physiotherapistName.trim() != 'Atanacak') {
      _physioController.text = referral.physiotherapistName.trim();
    } else {
      _physioController.text =
          AuthSession.currentUser?.displayName ?? '';
    }

    _functionalController.text =
        ReferralRecordPrefill.sessionFunctionalAssessment(referral);
    _notesController.text = ReferralRecordPrefill.sessionNotes(referral);
    _warningController.text = ReferralRecordPrefill.sessionWarningSigns(referral);
    _exercisesController.text =
        ReferralRecordPrefill.sessionExercisesPerformed(referral);

    if (referral.targetReturnToSportDate != null) {
      _returnStage = ReturnToSportStage.agri_kontrolu;
    }
  }

  Patient _buildPatientPreview({
    required String patientId,
    required String fullName,
  }) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    final first = parts.isEmpty ? 'Hasta' : parts.first;
    final last = parts.length > 1 ? parts.sublist(1).join(' ') : ' ';
    final now = DateTime.now();
    return Patient(
      id: patientId,
      fileNumber: '—',
      firstName: first,
      lastName: last,
      phone: '',
      birthDate: now,
      lastVisitDate: now,
      primaryComplaint: '',
      bodyRegion: '',
    );
  }

  @override
  void dispose() {
    _sessionDateCtrl.dispose();
    _physioController.dispose();
    _romController.dispose();
    _strengthController.dispose();
    _functionalController.dispose();
    _exercisesController.dispose();
    _homeComplianceController.dispose();
    _warningController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _returnStageLabel(ReturnToSportStage stage) {
    switch (stage) {
      case ReturnToSportStage.uygun_degil:
        return 'Uygun Değil';
      case ReturnToSportStage.agri_kontrolu:
        return 'Ağrı Kontrolü';
      case ReturnToSportStage.hareket_acikligi:
        return 'Hareket Açıklığı';
      case ReturnToSportStage.kuvvetlendirme:
        return 'Kuvvetlendirme';
      case ReturnToSportStage.kosuya_donus:
        return 'Koşuya Dönüş';
      case ReturnToSportStage.saha_brans_calisma:
        return 'Saha / Branş Çalışması';
      case ReturnToSportStage.temasli_antrenman:
        return 'Temaslı Antrenman';
      case ReturnToSportStage.maca_donus:
        return 'Maça / Yarışa Dönüş';
    }
  }

  Future<void> _save() async {
    final effectivePatientId =
        _selectedPatientId?.trim().isNotEmpty == true
        ? _selectedPatientId!.trim()
        : (widget.patientId?.trim().isNotEmpty == true
              ? widget.patientId!.trim()
              : _referralPatientId?.trim());
    if (effectivePatientId == null || effectivePatientId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(PhysiotherapySessionFormUserMessages.patientRequired),
        ),
      );
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) return;

    DateTime sessionDate;
    try {
      sessionDate = DateTime.parse(_sessionDateCtrl.text.trim());
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(PhysiotherapySessionFormUserMessages.invalidSessionDate),
        ),
      );
      return;
    }

    final referralTrimmed = _referralId?.trim() ?? '';
    if (referralTrimmed.isEmpty &&
        PhysiotherapySessionRepositoryProvider.usesRemoteSessions) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(PhysiotherapySessionFormUserMessages.referralRequired),
        ),
      );
      return;
    }

    setState(() => _saving = true);

    var patientName = _selectedPatientName ?? _selectedPatientPreview?.fullName;
    patientName ??= (await PatientLookupDataSource.findById(effectivePatientId))
        ?.fullName;
    patientName ??=
        await PhysiotherapySessionFormDataSource.resolvePatientName(
          effectivePatientId,
        );
    patientName ??= 'Hasta';

    final note = PhysiotherapySessionNote(
      id: 'sess-pending',
      patientId: effectivePatientId,
      patientName: patientName,
      sessionDate: sessionDate,
      physiotherapistName: _physioController.text.trim().isEmpty
          ? 'Fizyoterapist'
          : _physioController.text.trim(),
      painScore: _pain,
      rangeOfMotionSummary: _romController.text.trim(),
      strengthSummary: _strengthController.text.trim(),
      functionalAssessment: _functionalController.text.trim(),
      exercisesPerformed: _exercisesController.text.trim(),
      homeProgramCompliance: _homeComplianceController.text.trim().isEmpty
          ? 'Bilinmiyor'
          : _homeComplianceController.text.trim(),
      warningSigns: _warningController.text.trim(),
      returnToSportStage: _returnStage,
      doctorNotificationNeeded: _doctorNotificationNeeded,
      notes: _notesController.text.trim(),
      referralId: referralTrimmed.isEmpty ? null : referralTrimmed,
    );

    final result = await PhysiotherapySessionFormDataSource.add(note);
    if (!mounted) return;

    setState(() => _saving = false);

    if (result.hasError || result.session == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.errorMessage ?? PhysiotherapySessionFormUserMessages.saveFailure,
          ),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(PhysiotherapySessionFormUserMessages.saveSuccess),
      ),
    );
    context.go('/physiotherapy/sessions/${result.session!.id}');
  }

  void _cancel() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/physiotherapy/sessions');
    }
  }

  Widget _referralBanner(BuildContext context) {
    if (_referralId == null || _referralId!.isEmpty) {
      return const SizedBox.shrink();
    }
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.link, size: 20, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: _referralPrefillLoading
                  ? Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Yönlendirme bilgisi yükleniyor…',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: muted),
                        ),
                      ],
                    )
                  : Text(
                      PhysiotherapyReferralLookupUserMessages.sessionLinkedBanner,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: muted),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClinicalFormScaffold.sections(
      shellTitle: 'Yeni Seans Notu',
      onSave: _save,
      onCancel: _cancel,
      saveLabel: 'Kaydet',
      saving: _saving,
      formKey: _formKey,
      header: const PageHeader(
        title: 'Yeni Seans Notu',
        icon: Icons.fitness_center_outlined,
        leadingBack: true,
        fallbackRoute: '/physiotherapy/sessions',
      ),
      beforeSections: [_referralBanner(context)],
      sections: [
                          FormSectionCard(
                            title: 'Hasta ve Seans',
                            icon: Icons.event_note_outlined,
                            children: [
                              PatientSelectorField(
                                selectedPatientId: _selectedPatientId,
                                selectedPatientPreview: _selectedPatientPreview,
                                lockSelection: _lockPatient,
                                enabled: !_lockPatient,
                                isDense: true,
                                onChanged: (v) => setState(() {
                                  _selectedPatientId = v;
                                  if (v == null || v.isEmpty) {
                                    _selectedPatientName = null;
                                    _selectedPatientPreview = null;
                                  }
                                }),
                                onPatientSelected: (p) => setState(() {
                                  _selectedPatientId = p?.id;
                                  _selectedPatientName = p?.fullName;
                                  _selectedPatientPreview = p;
                                }),
                              ),
                              TextFormField(
                                controller: _physioController,
                                decoration: const InputDecoration(
                                  labelText: 'Fizyoterapist adı',
                                  isDense: true,
                                ),
                              ),
                              TextFormField(
                                controller: _sessionDateCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Seans tarihi (YYYY-MM-DD)',
                                  isDense: true,
                                ),
                              ),
                              Row(
                                children: [
                                  const Text('Ağrı skoru (0-10):'),
                                  Expanded(
                                    child: Slider(
                                      value: _pain.toDouble(),
                                      min: 0,
                                      max: 10,
                                      divisions: 10,
                                      label: '$_pain',
                                      onChanged: (d) =>
                                          setState(() => _pain = d.toInt()),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          FormSectionCard(
                            title: 'Değerlendirme',
                            icon: Icons.fact_check_outlined,
                            children: [
                              TextFormField(
                                controller: _romController,
                                maxLines: 2,
                                decoration: const InputDecoration(
                                  labelText: 'ROM özeti',
                                  isDense: true,
                                ),
                              ),
                              TextFormField(
                                controller: _strengthController,
                                maxLines: 2,
                                decoration: const InputDecoration(
                                  labelText: 'Kuvvet özeti',
                                  isDense: true,
                                ),
                              ),
                              TextFormField(
                                controller: _functionalController,
                                maxLines: 2,
                                decoration: const InputDecoration(
                                  labelText: 'Fonksiyonel değerlendirme',
                                  isDense: true,
                                ),
                              ),
                              TextFormField(
                                controller: _exercisesController,
                                maxLines: 3,
                                decoration: const InputDecoration(
                                  labelText: 'Yapılan egzersizler',
                                  isDense: true,
                                ),
                              ),
                              TextFormField(
                                controller: _homeComplianceController,
                                decoration: const InputDecoration(
                                  labelText: 'Ev programı uyumu',
                                  isDense: true,
                                ),
                              ),
                              TextFormField(
                                controller: _warningController,
                                maxLines: 2,
                                decoration: const InputDecoration(
                                  labelText: 'Uyarı bulguları',
                                  isDense: true,
                                ),
                              ),
                            ],
                          ),
                          FormSectionCard(
                            title: 'Spora Dönüş',
                            icon: Icons.sports_outlined,
                            children: [
                              DropdownButtonFormField<ReturnToSportStage>(
                                initialValue: _returnStage,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'Spora dönüş aşaması',
                                  isDense: true,
                                ),
                                items: ReturnToSportStage.values
                                    .map(
                                      (s) => DropdownMenuItem(
                                        value: s,
                                        child: Text(
                                          _returnStageLabel(s),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) {
                                  if (v != null) setState(() => _returnStage = v);
                                },
                              ),
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text('Doktor bildirimi gerekli mi?'),
                                value: _doctorNotificationNeeded,
                                onChanged: (v) =>
                                    setState(() => _doctorNotificationNeeded = v),
                              ),
                              TextFormField(
                                controller: _notesController,
                                maxLines: 3,
                                decoration: const InputDecoration(
                                  labelText: 'Notlar',
                                  isDense: true,
                                ),
                              ),
                            ],
                          ),
      ],
    );
  }
}
