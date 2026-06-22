import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_session.dart';
import '../../../shared/layout/responsive_page_body.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/clinical_notice.dart';
import '../../../shared/widgets/clinical_notice_tone.dart';
import '../../../shared/widgets/clinical_snack_bar.dart';
import '../../../shared/widgets/clinical_state_message.dart';
import '../../../shared/widgets/detail_action_labels.dart';
import '../../../shared/widgets/clinical_stacked_sections.dart';
import '../../../shared/widgets/detail_actions_panel.dart';
import '../../../shared/widgets/detail_header_card.dart';
import '../../../shared/widgets/info_section_card.dart';
import '../../../shared/widgets/form_section_card.dart';
import '../../../shared/widgets/page_header.dart';
import '../data/async_physiotherapy_referral_repository_contract.dart';
import '../data/physiotherapy_referral_detail_data_source.dart';
import '../data/physiotherapy_referral_detail_load_result.dart';
import '../data/physiotherapy_referral_list_refresh.dart';
import '../data/physiotherapy_referral_user_messages.dart';
import '../data/physiotherapy_referral_workflow.dart';
import '../models/physiotherapy_referral.dart';

class PhysiotherapyReferralDetailScreen extends StatefulWidget {
  final String id;

  const PhysiotherapyReferralDetailScreen({super.key, required this.id});

  @override
  State<PhysiotherapyReferralDetailScreen> createState() =>
      _PhysiotherapyReferralDetailScreenState();
}

class _PhysiotherapyReferralDetailScreenState
    extends State<PhysiotherapyReferralDetailScreen> {
  late Future<PhysiotherapyReferralDetailLoadResult> _loadFuture;
  ReferralStatus? _editStatus;
  final _notesSafeCtrl = TextEditingController();
  bool _saving = false;
  int _lastRefreshVersion = PhysiotherapyReferralListRefresh.version;
  bool _activatedOnce = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _notesSafeCtrl.dispose();
    super.dispose();
  }

  @override
  void activate() {
    super.activate();
    if (!_activatedOnce) {
      _activatedOnce = true;
      return;
    }
    if (PhysiotherapyReferralListRefresh.isStale(_lastRefreshVersion)) {
      _reload();
    }
  }

  void _reload() {
    _lastRefreshVersion = PhysiotherapyReferralListRefresh.version;
    setState(() {
      _loadFuture = PhysiotherapyReferralDetailDataSource.load(widget.id);
    });
  }

  void _bindEditableFields(PhysiotherapyReferral referral) {
    _editStatus ??= referral.status;
    if (_notesSafeCtrl.text.isEmpty && referral.notes.isNotEmpty) {
      _notesSafeCtrl.text = referral.notes;
    }
  }

  Future<void> _saveUpdates(PhysiotherapyReferral referral) async {
    if (_saving) return;
    setState(() => _saving = true);

    final update = PhysiotherapyReferralSafeUpdate(
      status: _editStatus,
      notesSafe: _notesSafeCtrl.text.trim(),
    );

    final error = await PhysiotherapyReferralDetailDataSource.updateSafeFields(
      referral.id,
      update,
    );

    if (!mounted) return;
    setState(() => _saving = false);

    if (error != null) {
      showClinicalSnackBar(context, error);
      return;
    }

    showClinicalSnackBar(
      context,
      PhysiotherapyReferralDetailUserMessages.saveSuccess,
    );
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Fizyoterapi Yönlendirmesi',
      child: FutureBuilder<PhysiotherapyReferralDetailLoadResult>(
        future: _loadFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return ClinicalStateMessage.loading(
              message: PhysiotherapyReferralDetailUserMessages.loading,
            );
          }

          final result = snapshot.data!;
          if (result.hasError) {
            return ClinicalStateMessage.error(
              icon: Icons.error_outline,
              title: PhysiotherapyReferralDetailUserMessages.errorTitle,
              description: result.errorMessage!,
              onRetry: _reload,
            );
          }

          final referral = result.referral;
          if (referral == null) {
            return ClinicalStateMessage.empty(
              title: PhysiotherapyReferralDetailUserMessages.notFoundTitle,
              description:
                  PhysiotherapyReferralDetailUserMessages.notFoundDescription,
              icon: Icons.error_outline,
            );
          }

          _bindEditableFields(referral);
          return _buildContent(context, referral);
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, PhysiotherapyReferral referral) {
    final referredStr = _formatDate(referral.referredAt);
    final sportStr = referral.targetReturnToSportDate != null
        ? _formatDate(referral.targetReturnToSportDate!)
        : kDisplayUnspecified;
    final plannedStr = referral.plannedStartDate != null
        ? _formatDate(referral.plannedStartDate!)
        : kDisplayUnspecified;
    final hasSourceEncounter = referral.clinicalEncounterId != null &&
        referral.clinicalEncounterId!.trim().isNotEmpty;
    final canEdit = AuthSession.canEditPhysiotherapy;

    return ResponsiveDetailPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PageHeader(
            title: 'Fizyoterapi Yönlendirmesi',
            icon: Icons.accessibility_new_outlined,
            leadingBack: true,
            fallbackRoute: '/physiotherapy/referrals',
          ),
          DetailHeaderCard(
            title: referral.patientName,
            subtitle: 'Yönlendirme: $referredStr',
          ),
          if (AuthSession.isPhysiotherapist &&
              referral.isPendingPhysioAction &&
              PhysiotherapyReferralWorkflow.isAssignedToCurrentUser(referral))
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ClinicalNotice(
                tone: ClinicalNoticeTone.info,
                dense: true,
                message:
                    'Rehabilitasyon hastası — tanı, beklenti ve sınırlamaları inceleyip fizik tedavi randevusu planlayın.',
              ),
            ),
          if (hasSourceEncounter)
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextButton(
                  onPressed: () {
                    if (AuthSession.canEditClinicalEncounters) {
                      context.push(
                        '/clinical-records/${referral.clinicalEncounterId}',
                      );
                    } else if (AuthSession.canViewClinicalSummary) {
                      context.push(
                        '/physiotherapy/clinical-summaries/${referral.clinicalEncounterId}',
                      );
                    }
                  },
                  child: Text(
                    AuthSession.canEditClinicalEncounters
                        ? 'Kaynak Muayene Kaydına Git'
                        : 'Klinik Özete Git',
                  ),
                ),
              ),
            ),
          ClinicalStackedSections(
            children: [
          InfoSectionCard(
            title: 'Hasta ve Yönlendirme Bilgisi',
            rows: [
              InfoSectionRow('Hasta', referral.patientName, emphasize: true),
              InfoSectionRow('Yönlendirme tarihi', referredStr),
              InfoSectionRow('Yönlendiren', displayField(referral.referredBy)),
              InfoSectionRow(
                'Fizyoterapist',
                displayField(referral.physiotherapistName),
              ),
              InfoSectionRow('Durum', referral.statusLabel),
              InfoSectionRow('Planlanan başlangıç', plannedStr),
            ],
          ),
          InfoSectionCard(
            title: 'Klinik Özet / Tanı',
            rows: [
              InfoSectionRow(
                'Tanı özeti',
                displayField(referral.diagnosisSummary),
                emphasize: true,
              ),
            ],
          ),
          InfoSectionCard(
            title: 'Fizyoterapi Hedefleri',
            rows: [
              InfoSectionRow(
                'Tedavi hedefi',
                displayField(referral.treatmentGoal),
                emphasize: true,
              ),
            ],
          ),
          InfoSectionCard(
            title: 'Takip Planı',
            rows: [
              InfoSectionRow(
                'Dikkat edilecekler',
                displayField(referral.precautions),
              ),
              InfoSectionRow(
                'İzin verilen aktiviteler',
                displayField(referral.allowedActivities),
              ),
              InfoSectionRow(
                'Kısıtlanan aktiviteler',
                displayField(referral.restrictedActivities),
              ),
              InfoSectionRow('Spora dönüş hedef tarihi', sportStr),
            ],
          ),
          if (referral.doctorSummary.trim().isNotEmpty)
            InfoSectionCard(
              title: 'Doktor Özeti',
              rows: [
                InfoSectionRow(
                  'Yönlendirme özeti',
                  displayField(referral.doctorSummary),
                  emphasize: true,
                ),
              ],
            ),
            ],
          ),
          if (canEdit)
            FormSectionCard(
              title: 'Durum Güncelle',
              icon: Icons.sync_alt_outlined,
              children: [
                DropdownButtonFormField<ReferralStatus>(
                  value: _editStatus ?? referral.status,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Durum',
                    isDense: true,
                  ),
                  items: ReferralStatus.values
                      .map(
                        (s) => DropdownMenuItem(
                          value: s,
                          child: Text(referralStatusLabel(s)),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _editStatus = v);
                  },
                ),
                TextFormField(
                  controller: _notesSafeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Güvenli takip notu',
                    isDense: true,
                  ),
                  maxLines: 3,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: _saving ? null : () => _saveUpdates(referral),
                    child: Text(_saving ? 'Kaydediliyor…' : 'Güncelle'),
                  ),
                ),
              ],
            )
          else if (referral.notes.trim().isNotEmpty)
            InfoSectionCard(
              title: 'Takip Notu',
              rows: [
                InfoSectionRow('Güvenli not', displayField(referral.notes)),
              ],
            ),
          DetailActionsPanel(
            topSpacing: 0,
            actions: [
              if (PhysiotherapyReferralWorkflow.canPhysioBookAppointment(
                    referral,
                  ) ||
                  (AuthSession.canEditAppointments &&
                      !AuthSession.isPhysiotherapist))
                DetailAction(
                  label: DetailActionLabels.physiotherapyAppointmentPlan,
                  filled: true,
                  onPressed: () => context.push(
                    '/appointments/new?patientId=${referral.patientId}&type=fizikTedavi&referralId=${referral.id}',
                  ),
                ),
              if (PhysiotherapyReferralWorkflow.canCreateSession(referral))
                DetailAction(
                  label: 'Seans Notu Oluştur',
                  filled: AuthSession.isPhysiotherapist &&
                      !PhysiotherapyReferralWorkflow.canPhysioBookAppointment(
                        referral,
                      ),
                  onPressed: () => context.push(
                    '/physiotherapy/sessions/new?patientId=${referral.patientId}&referralId=${referral.id}',
                  ),
                ),
              if (PhysiotherapyReferralWorkflow.canCreateRehabPlan(referral))
                DetailAction(
                  label: 'Rehabilitasyon Planı',
                  onPressed: () => context.push(
                    '/exercise-plans/new?patientId=${referral.patientId}&referralId=${referral.id}',
                  ),
                ),
              if (PhysiotherapyReferralWorkflow.canViewPatientFile(referral))
                DetailAction(
                  label: 'Hasta Dosyası',
                  onPressed: () =>
                      context.push('/patients/${referral.patientId}'),
                ),
              if (AuthSession.canEditPdfOutputs && !AuthSession.isPhysiotherapist)
                DetailAction(
                  label: DetailActionLabels.pdfPrepare,
                  onPressed: () => context.push(
                    '/pdf-outputs/new?patientId=${referral.patientId}&source=physiotherapy_referral&id=${referral.id}',
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime date) {
  final local = date.toLocal();
  final d = local.day.toString().padLeft(2, '0');
  final m = local.month.toString().padLeft(2, '0');
  return '$d.$m.${local.year}';
}
