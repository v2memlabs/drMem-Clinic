import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_session.dart';
import '../../../shared/widgets/clinical_snack_bar.dart';
import '../../../shared/widgets/clinical_state_message.dart';
import '../../../shared/widgets/clinical_form_scaffold.dart';
import '../../../shared/widgets/form_section_card.dart';
import '../../../shared/widgets/page_header.dart';
import '../../patients/widgets/patient_selector_field.dart';
import '../data/physiotherapy_referral_encounter_prefill_data_source.dart';
import '../data/physiotherapy_referral_form_data_source.dart';
import '../data/physiotherapy_referral_repository_provider.dart';
import '../data/physiotherapy_referral_user_messages.dart';
import '../models/physiotherapy_referral.dart';
import '../physiotherapy_referral_prefill.dart';
import '../widgets/physiotherapist_selector_field.dart';

class PhysiotherapyReferralFormScreen extends StatefulWidget {
  final String? patientId;
  final String? clinicalEncounterId;

  const PhysiotherapyReferralFormScreen({
    super.key,
    this.patientId,
    this.clinicalEncounterId,
  });

  @override
  State<PhysiotherapyReferralFormScreen> createState() =>
      _PhysiotherapyReferralFormScreenState();
}

class _PhysiotherapyReferralFormScreenState
    extends State<PhysiotherapyReferralFormScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _patientId;
  String? _clinicalEncounterId;
  bool _lockPatient = false;
  bool _saving = false;
  bool _prefillLoading = false;
  String? _prefillNotice;

  final _referredByCtrl = TextEditingController();
  final _diagnosisCtrl = TextEditingController();
  final _goalCtrl = TextEditingController();
  final _precautionsCtrl = TextEditingController();
  final _allowedCtrl = TextEditingController();
  final _restrictedCtrl = TextEditingController();
  final _returnSportDateCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  ReferralStatus _status = ReferralStatus.yeni;
  String? _assignedPhysioProfileId;
  String _assignedPhysioName = 'Atanacak';

  @override
  void initState() {
    super.initState();
    _patientId = widget.patientId;
    _clinicalEncounterId = widget.clinicalEncounterId;
    _lockPatient = widget.clinicalEncounterId != null &&
        widget.clinicalEncounterId!.trim().isNotEmpty;
    _referredByCtrl.text = AuthSession.currentUser?.displayName ?? '';
    _loadDefaultPhysiotherapistAssignment();
    _loadClinicalEncounterPrefill();
  }

  Future<void> _loadDefaultPhysiotherapistAssignment() async {
    final resolved = await PhysiotherapistAssignmentResolver.resolveDefault();
    if (!mounted) return;
    if (resolved.profileId != null) {
      setState(() {
        _assignedPhysioProfileId = resolved.profileId;
        _assignedPhysioName = resolved.displayName ?? 'Fizyoterapist';
      });
    }
  }

  Future<void> _loadClinicalEncounterPrefill() async {
    final ceId = widget.clinicalEncounterId?.trim();
    if (ceId == null || ceId.isEmpty) return;

    setState(() {
      _prefillLoading = true;
      _prefillNotice = null;
    });

    final result =
        await PhysiotherapyReferralEncounterPrefillDataSource.loadEncounter(
      ceId,
    );

    if (!mounted) return;

    if (result.isLoading) return;

    if (result.encounter != null) {
      final encounter = result.encounter!;
      _patientId = encounter.patientId;
      _clinicalEncounterId = encounter.id;
      _lockPatient = true;

      _referredByCtrl.text = PhysiotherapyReferralPrefill.referredBy(
        encounter,
        AuthSession.currentUser?.displayName ?? 'Doktor',
      );
      _diagnosisCtrl.text =
          PhysiotherapyReferralPrefill.diagnosisSummary(encounter);
      _goalCtrl.text = PhysiotherapyReferralPrefill.treatmentGoal(encounter);
      _precautionsCtrl.text =
          PhysiotherapyReferralPrefill.precautions(encounter);
      _allowedCtrl.text =
          PhysiotherapyReferralPrefill.allowedActivities(encounter);
      _restrictedCtrl.text =
          PhysiotherapyReferralPrefill.restrictedActivities(encounter);

      final targetDate =
          PhysiotherapyReferralPrefill.targetReturnToSportDate(encounter);
      if (targetDate != null) {
        final d = targetDate.toLocal();
        _returnSportDateCtrl.text =
            '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      }
      _prefillNotice = 'Hasta ve klinik özet muayene kaydından ön dolduruldu.';
    } else if (result.errorMessage != null) {
      _prefillNotice = result.errorMessage;
    }

    setState(() => _prefillLoading = false);
  }

  @override
  void dispose() {
    _referredByCtrl.dispose();
    _diagnosisCtrl.dispose();
    _goalCtrl.dispose();
    _precautionsCtrl.dispose();
    _allowedCtrl.dispose();
    _restrictedCtrl.dispose();
    _returnSportDateCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;

    if (_patientId == null || _patientId!.isEmpty) {
      showClinicalSnackBar(
        context,
        PhysiotherapyReferralFormUserMessages.patientRequired,
      );
      return;
    }

    final patientName =
        await PhysiotherapyReferralFormDataSource.resolvePatientName(
      _patientId!,
    );
    if (patientName == null || patientName.isEmpty) {
      showClinicalSnackBar(
        context,
        PhysiotherapyReferralFormUserMessages.patientRequired,
      );
      return;
    }

    DateTime? targetReturnDate;
    if (_returnSportDateCtrl.text.trim().isNotEmpty) {
      try {
        targetReturnDate = DateTime.parse(_returnSportDateCtrl.text.trim());
      } catch (_) {
        showClinicalSnackBar(
          context,
          PhysiotherapyReferralFormUserMessages.invalidReturnDate,
        );
        return;
      }
    }

    setState(() => _saving = true);

    PhysiotherapyReferralRepositoryProvider.resetCache();

    final referral = PhysiotherapyReferral(
      id: '',
      patientId: _patientId!,
      patientName: patientName,
      referredAt: DateTime.now(),
      referredBy: _referredByCtrl.text.trim(),
      physiotherapistName: _assignedPhysioName.trim().isEmpty
          ? 'Atanacak'
          : _assignedPhysioName.trim(),
      assignedPhysiotherapistProfileId: _assignedPhysioProfileId,
      diagnosisSummary: _diagnosisCtrl.text.trim(),
      treatmentGoal: _goalCtrl.text.trim(),
      precautions: _precautionsCtrl.text.trim(),
      allowedActivities: _allowedCtrl.text.trim(),
      restrictedActivities: _restrictedCtrl.text.trim(),
      targetReturnToSportDate: targetReturnDate,
      status: _status,
      notes: '',
      doctorSummary: _notesCtrl.text.trim(),
      clinicalEncounterId: _clinicalEncounterId?.trim().isEmpty == true
          ? null
          : _clinicalEncounterId?.trim(),
    );

    final result = await PhysiotherapyReferralFormDataSource.add(referral);

    if (!mounted) return;
    setState(() => _saving = false);

    if (result.hasError) {
      showClinicalSnackBar(context, result.errorMessage!);
      return;
    }

    showClinicalSnackBar(
      context,
      PhysiotherapyReferralFormUserMessages.saveSuccess,
    );
    context.go('/physiotherapy/referrals/${result.referral!.id}');
  }

  void _cancel() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/physiotherapy/referrals');
    }
  }

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return ClinicalFormScaffold.sections(
      shellTitle: 'Fizyoterapi Yönlendirmesi',
      onSave: _save,
      onCancel: _cancel,
      saveLabel: _saving ? 'Kaydediliyor…' : 'Kaydet',
      formKey: _formKey,
      header: const PageHeader(
        title: 'Fizyoterapi Yönlendirmesi',
        icon: Icons.accessibility_new_outlined,
        leadingBack: true,
        fallbackRoute: '/physiotherapy/referrals',
      ),
      beforeSections: [
        if (_clinicalEncounterId != null && _clinicalEncounterId!.isNotEmpty) ...[
          if (_prefillLoading)
            ClinicalStateMessage.loading(
              message:
                  PhysiotherapyReferralFormUserMessages.loadingEncounter,
            )
          else if (_prefillNotice != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _prefillNotice!,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: muted),
              ),
            ),
        ],
      ],
      sections: [
                          FormSectionCard(
                            title: 'Hasta ve Yönlendirme Bilgisi',
                            icon: Icons.person_outline,
                            children: [
                              PatientSelectorField(
                                selectedPatientId: _patientId,
                                enabled: !_lockPatient,
                                isDense: true,
                                labelText: 'Hasta',
                                isRequired: true,
                                onChanged: (v) =>
                                    setState(() => _patientId = v),
                              ),
                              TextFormField(
                                controller: _referredByCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Yönlendiren hekim',
                                  isDense: true,
                                ),
                                validator: (v) => (v == null || v.trim().isEmpty)
                                    ? 'Zorunlu'
                                    : null,
                              ),
                              PhysiotherapistSelectorField(
                                selectedProfileId: _assignedPhysioProfileId,
                                onChanged: (v) => setState(
                                  () => _assignedPhysioProfileId = v,
                                ),
                                onPhysiotherapistSelected: (member) {
                                  if (member == null) return;
                                  setState(() {
                                    _assignedPhysioName = member.displayName;
                                  });
                                },
                              ),
                            ],
                          ),
                          FormSectionCard(
                            title: 'Klinik Özet / Tanı',
                            icon: Icons.medical_information_outlined,
                            children: [
                              TextFormField(
                                controller: _diagnosisCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Tanı özeti',
                                  isDense: true,
                                ),
                                maxLines: 3,
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? 'Zorunlu'
                                        : null,
                              ),
                            ],
                          ),
                          FormSectionCard(
                            title: 'Fizyoterapi Hedefleri',
                            icon: Icons.flag_outlined,
                            children: [
                              TextFormField(
                                controller: _goalCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Tedavi hedefi',
                                  isDense: true,
                                ),
                                maxLines: 3,
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? 'Zorunlu'
                                        : null,
                              ),
                            ],
                          ),
                          FormSectionCard(
                            title: 'Dikkat / Kısıtlı Aktiviteler',
                            icon: Icons.warning_amber_outlined,
                            children: [
                              TextFormField(
                                controller: _precautionsCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Dikkat edilecekler',
                                  isDense: true,
                                ),
                                maxLines: 2,
                              ),
                              TextFormField(
                                controller: _allowedCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'İzin verilen aktiviteler',
                                  isDense: true,
                                ),
                                maxLines: 2,
                              ),
                              TextFormField(
                                controller: _restrictedCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Kısıtlanan aktiviteler',
                                  isDense: true,
                                ),
                                maxLines: 2,
                              ),
                            ],
                          ),
                          FormSectionCard(
                            title: 'Spora Dönüş Hedefi',
                            icon: Icons.sports_outlined,
                            children: [
                              TextFormField(
                                controller: _returnSportDateCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Hedef tarih (YYYY-MM-DD)',
                                  isDense: true,
                                ),
                              ),
                            ],
                          ),
                          FormSectionCard(
                            title: 'Doktor Özeti',
                            icon: Icons.notes_outlined,
                            children: [
                              TextFormField(
                                controller: _notesCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Yönlendirme özeti (güvenli)',
                                  isDense: true,
                                ),
                                maxLines: 3,
                              ),
                            ],
                          ),
      ],
    );
  }
}
