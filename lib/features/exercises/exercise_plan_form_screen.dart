import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_session.dart';
import '../../shared/widgets/clinical_form_scaffold.dart';
import '../../shared/widgets/form_section_card.dart';
import '../../shared/widgets/page_header.dart';
import '../patients/data/patient_lookup_data_source.dart';
import '../patients/models/patient.dart';
import '../patients/widgets/patient_selector_field.dart';
import '../physiotherapy/data/physiotherapy_referral_lookup_data_source.dart';
import '../physiotherapy/data/physiotherapy_referral_user_messages.dart';
import '../physiotherapy/models/physiotherapy_referral.dart';
import '../physiotherapy/referral_record_prefill.dart';
import 'data/exercise_plan_form_data_source.dart';
import 'data/exercise_plan_template_store.dart';
import 'models/exercise_item.dart';
import 'models/exercise_plan.dart';

class ExercisePlanFormScreen extends StatefulWidget {
  final String? patientId;
  final String? referralId;

  const ExercisePlanFormScreen({
    super.key,
    this.patientId,
    this.referralId,
  });

  @override
  State<ExercisePlanFormScreen> createState() => _ExercisePlanFormScreenState();
}

class _ExercisePlanFormScreenState extends State<ExercisePlanFormScreen> {
  String? selectedPatientId;
  String? _selectedPatientName;
  Patient? _selectedPatientPreview;
  String? _referralId;
  String? _referralPatientId;
  bool _lockPatient = false;

  final titleCtrl = TextEditingController();
  final diagnosisCtrl = TextEditingController();
  ExercisePlanPhase? phase;
  final goalCtrl = TextEditingController();
  final exercisesCtrl = TextEditingController();
  final homeCtrl = TextEditingController();
  final warningsCtrl = TextEditingController();
  final controlDateCtrl = TextEditingController();
  ExercisePlanStatus status = ExercisePlanStatus.taslak;
  bool doctorApproved = false;
  bool _referralPrefillLoading = false;
  bool _saving = false;

  bool get _isPhysioSubmittingPlan =>
      AuthSession.isPhysiotherapist && AuthSession.canEditExercisePlans;

  void _applyTemplate(ExercisePlanTemplate template) {
    titleCtrl.text = template.title;
    phase = template.phase;
    goalCtrl.text = template.goal;
    exercisesCtrl.text = template.exercisesText;
    homeCtrl.text = template.homeInstructions;
    warningsCtrl.text = template.warnings;
    setState(() {});
  }

  Future<void> _saveCurrentAsTemplate() async {
    final title = titleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Şablon için plan başlığı girin')),
      );
      return;
    }
    ExercisePlanTemplateStore.add(
      ExercisePlanTemplate(
        id: 'tpl-${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        phase: phase ?? ExercisePlanPhase.erkenRehabilitasyon,
        goal: goalCtrl.text.trim(),
        exercisesText: exercisesCtrl.text.trim(),
        homeInstructions: homeCtrl.text.trim(),
        warnings: warningsCtrl.text.trim(),
      ),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Rehabilitasyon şablonu kaydedildi')),
    );
  }

  @override
  void initState() {
    super.initState();
    selectedPatientId = widget.patientId;
    _referralId = widget.referralId;
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
    selectedPatientId = referral.patientId;
    _selectedPatientName = referral.patientName;
    _selectedPatientPreview = _buildPatientPreview(
      patientId: referral.patientId,
      fullName: referral.patientName,
    );
    _lockPatient = true;

    titleCtrl.text = ReferralRecordPrefill.exerciseTitle(referral);
    diagnosisCtrl.text = referral.diagnosisSummary.trim();
    goalCtrl.text = referral.treatmentGoal.trim();
    homeCtrl.text = ReferralRecordPrefill.exerciseHomeInstructions(referral);
    warningsCtrl.text = ReferralRecordPrefill.exerciseWarnings(referral);

    if (referral.allowedActivities.trim().isNotEmpty) {
      exercisesCtrl.text = referral.allowedActivities.trim();
    }

    if (referral.targetReturnToSportDate != null) {
      controlDateCtrl.text =
          ReferralRecordPrefill.formatDate(referral.targetReturnToSportDate!);
      phase = ExercisePlanPhase.sporaDonus;
    } else {
      phase = ExercisePlanPhase.erkenRehabilitasyon;
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
    titleCtrl.dispose();
    diagnosisCtrl.dispose();
    goalCtrl.dispose();
    exercisesCtrl.dispose();
    homeCtrl.dispose();
    warningsCtrl.dispose();
    controlDateCtrl.dispose();
    super.dispose();
  }

  List<ExerciseItem> _parseExercises(String raw) {
    final lines =
        raw.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty);
    var index = 0;
    return lines.map((line) {
      index++;
      return ExerciseItem(
        id: 'ex-$index',
        name: line,
        description: line,
      );
    }).toList();
  }

  Future<void> _save() async {
    if (_saving) return;

    final effectivePatientId = selectedPatientId?.trim().isNotEmpty == true
        ? selectedPatientId!.trim()
        : (widget.patientId?.trim().isNotEmpty == true
            ? widget.patientId!.trim()
            : _referralPatientId?.trim());
    if (effectivePatientId == null || effectivePatientId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen hasta seçin')),
      );
      return;
    }

    DateTime? controlDate;
    if (controlDateCtrl.text.trim().isNotEmpty) {
      try {
        controlDate = DateTime.parse(controlDateCtrl.text.trim());
      } catch (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Kontrol tarihi YYYY-MM-DD formatında olmalı')),
        );
        return;
      }
    }

    final exercises = _parseExercises(exercisesCtrl.text);
    final patientName = _selectedPatientName ??
        _selectedPatientPreview?.fullName ??
        await PatientLookupDataSource.resolveName(
          patientId: effectivePatientId,
        );
    final effectiveDoctorApproved =
        _isPhysioSubmittingPlan ? false : doctorApproved;
    final effectiveStatus = _isPhysioSubmittingPlan
        ? ExercisePlanStatus.doktorOnayBekliyor
        : status;

    final plan = ExercisePlan(
      id: 'ep${DateTime.now().millisecondsSinceEpoch}',
      patientId: effectivePatientId,
      patientName: patientName,
      title: titleCtrl.text.trim().isEmpty
          ? 'Yeni Egzersiz Programı'
          : titleCtrl.text.trim(),
      createdBy: AuthSession.currentUser?.displayName ?? 'Fizyoterapist',
      createdAt: DateTime.now(),
      diagnosisSummary:
          diagnosisCtrl.text.trim().isEmpty ? '-' : diagnosisCtrl.text.trim(),
      phase: phase ?? ExercisePlanPhase.erkenRehabilitasyon,
      goal: goalCtrl.text.trim().isEmpty ? '-' : goalCtrl.text.trim(),
      exercises: exercises.isEmpty
          ? [
              ExerciseItem(
                id: 'ex-1',
                name: 'Genel egzersiz',
                description: 'Program detayı formda güncellenecek',
              ),
            ]
          : exercises,
      homeInstructions: homeCtrl.text.trim(),
      warnings: warningsCtrl.text.trim(),
      doctorApproved: effectiveDoctorApproved,
      controlDate: controlDate,
      status: effectiveStatus,
      notes: '',
      referralId:
          _referralId?.trim().isEmpty == true ? null : _referralId?.trim(),
    );

    setState(() => _saving = true);
    try {
      final saved = await ExercisePlanFormDataSource.create(plan);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Egzersiz programı kaydedildi')),
      );
      context.go('/exercise-plans/${saved.id}');
    } on ExercisePlanFormException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
      setState(() => _saving = false);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Egzersiz programı kaydedilemedi.')),
      );
      setState(() => _saving = false);
    }
  }

  void _cancel() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/exercise-plans');
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
            Icon(Icons.link,
                size: 20, color: Theme.of(context).colorScheme.primary),
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
                      PhysiotherapyReferralLookupUserMessages
                          .exerciseLinkedBanner,
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
      shellTitle: 'Yeni Rehabilitasyon Planı',
      onSave: _save,
      onCancel: _cancel,
      saveLabel: _saving
          ? 'Kaydediliyor...'
          : (_isPhysioSubmittingPlan ? 'Doktor Onayına Gönder' : 'Kaydet'),
      header: PageHeader(
        title: _isPhysioSubmittingPlan
            ? 'Rehabilitasyon Planı'
            : 'Yeni Egzersiz Programı',
        icon: Icons.directions_run_outlined,
        leadingBack: true,
        fallbackRoute: '/exercise-plans',
      ),
      beforeSections: [_referralBanner(context)],
      sections: [
        FormSectionCard(
          title: 'Hasta ve Program',
          icon: Icons.assignment_outlined,
          children: [
            PatientSelectorField(
              selectedPatientId: selectedPatientId,
              selectedPatientPreview: _selectedPatientPreview,
              lockSelection: _lockPatient,
              enabled: !_lockPatient,
              isDense: true,
              onChanged: (v) => setState(() {
                selectedPatientId = v;
                if (v == null || v.isEmpty) {
                  _selectedPatientName = null;
                  _selectedPatientPreview = null;
                }
              }),
              onPatientSelected: (p) => setState(() {
                selectedPatientId = p?.id;
                _selectedPatientName = p?.fullName;
                _selectedPatientPreview = p;
              }),
            ),
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Plan başlığı',
                isDense: true,
              ),
            ),
            TextField(
              controller: diagnosisCtrl,
              decoration: const InputDecoration(
                labelText: 'Tanı özeti',
                isDense: true,
              ),
              maxLines: 2,
            ),
            DropdownButtonFormField<ExercisePlanPhase>(
              initialValue: phase,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Faz',
                isDense: true,
              ),
              items: ExercisePlanPhase.values
                  .map(
                    (p) => DropdownMenuItem(
                      value: p,
                      child: Text(
                        exercisePlanPhaseLabel(p),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => phase = v),
            ),
            TextField(
              controller: goalCtrl,
              decoration: const InputDecoration(
                labelText: 'Hedef',
                isDense: true,
              ),
              maxLines: 2,
            ),
          ],
        ),
        FormSectionCard(
          title: 'Şablonlar',
          icon: Icons.library_books_outlined,
          children: [
            if (ExercisePlanTemplateStore.listAll().isEmpty)
              Text(
                'Henüz şablon yok. Planı doldurup "Şablon olarak kaydet" ile oluşturabilirsiniz.',
                style: Theme.of(context).textTheme.bodySmall,
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final template in ExercisePlanTemplateStore.listAll())
                    OutlinedButton(
                      onPressed: () => _applyTemplate(template),
                      child: Text(template.title),
                    ),
                ],
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _saveCurrentAsTemplate,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Şablon olarak kaydet'),
              ),
            ),
          ],
        ),
        FormSectionCard(
          title: 'Egzersiz İçeriği',
          icon: Icons.fitness_center_outlined,
          children: [
            TextField(
              controller: exercisesCtrl,
              decoration: const InputDecoration(
                labelText: 'Egzersizler (her satır bir egzersiz)',
                alignLabelWithHint: true,
                isDense: true,
              ),
              maxLines: 4,
            ),
            TextField(
              controller: homeCtrl,
              decoration: const InputDecoration(
                labelText: 'Ev talimatları',
                isDense: true,
              ),
              maxLines: 3,
            ),
            TextField(
              controller: warningsCtrl,
              decoration: const InputDecoration(
                labelText: 'Uyarılar',
                isDense: true,
              ),
              maxLines: 2,
            ),
          ],
        ),
        FormSectionCard(
          title: 'Kontrol ve Onay',
          icon: Icons.verified_outlined,
          children: [
            TextField(
              controller: controlDateCtrl,
              decoration: const InputDecoration(
                labelText: 'Kontrol tarihi (YYYY-MM-DD)',
                isDense: true,
              ),
            ),
            if (_isPhysioSubmittingPlan)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Doktor onayı'),
                subtitle: const Text(
                  'Plan kaydedildiğinde doktora onay bildirimi gider.',
                ),
                trailing: const Icon(Icons.schedule_send_outlined),
              )
            else ...[
              DropdownButtonFormField<ExercisePlanStatus>(
                initialValue: status,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Durum',
                  isDense: true,
                ),
                items: ExercisePlanStatus.values
                    .map(
                      (s) => DropdownMenuItem(
                        value: s,
                        child: Text(
                          exercisePlanStatusLabel(s),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => status = v);
                },
              ),
              if (AuthSession.canApproveExercisePlans)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Doktor onayı'),
                  value: doctorApproved,
                  onChanged: (v) => setState(() => doctorApproved = v),
                ),
            ],
          ],
        ),
      ],
    );
  }
}
