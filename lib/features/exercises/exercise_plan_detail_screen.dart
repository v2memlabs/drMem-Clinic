import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_session.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../features/patients/widgets/patient_lookup_builder.dart';
import '../../shared/layout/responsive_page_body.dart';
import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/detail_action_labels.dart';
import '../../shared/widgets/clinical_stacked_sections.dart';
import '../../shared/widgets/detail_actions_panel.dart';
import '../../shared/widgets/detail_header_card.dart';
import '../../shared/widgets/clinical_state_message.dart';
import '../../shared/widgets/info_section_card.dart';
import '../../shared/widgets/page_header.dart';
import '../physiotherapy/widgets/physiotherapy_referral_source_section.dart';
import 'data/exercise_plan_detail_data_source.dart';
import 'data/exercise_plan_approval_data_source.dart';
import 'models/exercise_item.dart';
import 'models/exercise_plan.dart';

class ExercisePlanDetailScreen extends StatefulWidget {
  final String id;

  const ExercisePlanDetailScreen({super.key, required this.id});

  @override
  State<ExercisePlanDetailScreen> createState() =>
      _ExercisePlanDetailScreenState();
}

class _ExercisePlanDetailScreenState extends State<ExercisePlanDetailScreen> {
  late Future<ExercisePlanDetailLoadResult> _loadFuture;
  bool _approving = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _loadFuture = ExercisePlanDetailDataSource.load(widget.id);
    });
  }

  Future<void> _approvePlan(ExercisePlan plan) async {
    if (_approving) return;
    setState(() => _approving = true);
    final result = await ExercisePlanApprovalDataSource.approve(plan.id);
    if (!mounted) return;
    setState(() => _approving = false);
    if (result.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.errorMessage!)),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Rehabilitasyon planı onaylandı')),
    );
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ExercisePlanDetailLoadResult>(
      future: _loadFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const AppShell(
            title: 'Egzersiz Programı',
            child: Center(child: CircularProgressIndicator.adaptive()),
          );
        }

        final result = snapshot.data;
        final plan = result?.plan;
        if (snapshot.hasError ||
            result == null ||
            result.hasError ||
            plan == null) {
          return AppShell(
            title: 'Egzersiz Programı',
            child: ClinicalStateMessage.error(
              icon: Icons.error_outline,
              title: 'Egzersiz programı bulunamadı',
              description: ClinicalStateMessage.safeErrorDescription(
                result?.errorMessage ?? 'Kayıt yüklenemedi.',
              ),
              onRetry: () {
                setState(() {
                  _loadFuture = ExercisePlanDetailDataSource.load(widget.id);
                });
              },
            ),
          );
        }

        final createdStr = _formatDate(plan.createdAt);
        final controlStr = plan.controlDate != null
            ? _formatDate(plan.controlDate!)
            : kDisplayUnspecified;
        final refId = plan.referralId?.trim() ?? '';

        return PatientLookupBuilder(
          patientId: plan.patientId,
          builder: (context, patient) {
            final fileNo = patient?.fileNumber ?? '';
            return _buildExercisePlanBody(
              context,
              plan,
              createdStr,
              controlStr,
              fileNo,
              refId,
            );
          },
        );
      },
    );
  }

  Widget _buildExercisePlanBody(
    BuildContext context,
    ExercisePlan plan,
    String createdStr,
    String controlStr,
    String fileNo,
    String refId,
  ) {
    return AppShell(
      title: 'Egzersiz Programı',
      child: ResponsiveDetailPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PageHeader(
              title: 'Egzersiz Programı',
              icon: Icons.directions_run_outlined,
              leadingBack: true,
              fallbackRoute: '/exercise-plans',
            ),
            DetailHeaderCard(
              title: plan.title,
              subtitle: plan.patientName,
            ),
            if (refId.isNotEmpty)
              PhysiotherapyReferralSourceSection(
                referralId: refId,
                showGoToReferralAction: false,
              ),
            ClinicalStackedSections(
              children: [
                InfoSectionCard(
                  title: 'Hasta ve Program Bilgisi',
                  rows: [
                    InfoSectionRow('Hasta', plan.patientName, emphasize: true),
                    InfoSectionRow(
                      'Hasta dosya no',
                      fileNo.isEmpty ? kDisplayUnspecified : fileNo,
                    ),
                    InfoSectionRow(
                      'Program başlığı',
                      displayField(plan.title),
                      emphasize: true,
                    ),
                    InfoSectionRow('Oluşturan', displayField(plan.createdBy)),
                    InfoSectionRow('Oluşturulma tarihi', createdStr),
                    InfoSectionRow('Faz', exercisePlanPhaseLabel(plan.phase)),
                    InfoSectionRow(
                        'Durum', exercisePlanStatusLabel(plan.status)),
                    InfoSectionRow(
                      'Doktor onayı',
                      plan.doctorApproved ? 'Onaylandı' : 'Onay bekleniyor',
                    ),
                  ],
                ),
                InfoSectionCard(
                  title: 'Program Hedefi',
                  rows: [
                    InfoSectionRow(
                      'Tanı özeti',
                      displayField(plan.diagnosisSummary),
                    ),
                    InfoSectionRow('Faz', exercisePlanPhaseLabel(plan.phase)),
                    InfoSectionRow(
                      'Hedef',
                      displayField(plan.goal),
                      emphasize: true,
                    ),
                  ],
                ),
                _PatientFriendlyExerciseSection(exercises: plan.exercises),
                _PatientHomeInstructionsCard(
                    instructions: plan.homeInstructions),
                _PatientPrecautionsCard(warnings: plan.warnings),
                InfoSectionCard(
                  title: 'Takip ve İlerleme',
                  rows: [
                    InfoSectionRow('Kontrol tarihi', controlStr),
                    InfoSectionRow(
                      'Doktor onayı',
                      plan.doctorApproved ? 'Onaylandı' : 'Onay bekleniyor',
                    ),
                    InfoSectionRow(
                        'Program durumu', exercisePlanStatusLabel(plan.status)),
                  ],
                ),
                if (plan.notes.trim().isNotEmpty)
                  InfoSectionCard(
                    title: 'Klinik / İç Notlar (personel)',
                    rows: [
                      InfoSectionRow(
                        'Program notları',
                        displayField(plan.notes),
                      ),
                    ],
                  ),
              ],
            ),
            if (refId.isNotEmpty || AuthSession.canEditPdfOutputs)
              DetailActionsPanel(
                title: 'İşlemler',
                topSpacing: 0,
                actions: [
                  if (AuthSession.canApproveExercisePlans &&
                      !plan.doctorApproved &&
                      plan.status == ExercisePlanStatus.doktorOnayBekliyor)
                    DetailAction(
                      label: _approving ? 'Onaylanıyor…' : 'Rehabilitasyon Planını Onayla',
                      filled: true,
                      onPressed: _approving ? null : () => _approvePlan(plan),
                    ),
                  if (refId.isNotEmpty)
                    DetailAction(
                      label: DetailActionLabels.goToReferral,
                      onPressed: () =>
                          context.push('/physiotherapy/referrals/$refId'),
                    ),
                  if (AuthSession.canEditPdfOutputs)
                    DetailAction(
                      label: DetailActionLabels.pdfPrepare,
                      filled: true,
                      onPressed: () => context.push(
                        '/pdf-outputs/new?patientId=${plan.patientId}&source=exercise_plan&id=${plan.id}',
                      ),
                    ),
                ],
              ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
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

/// Hasta ile paylaşılabilir egzersiz listesi.
class _PatientFriendlyExerciseSection extends StatelessWidget {
  final List<ExerciseItem> exercises;

  const _PatientFriendlyExerciseSection({required this.exercises});

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Egzersizler',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.navy,
                ),
          ),
        ),
        Text(
          'Aşağıdaki hareketleri hekim veya fizyoterapist önerisine göre uygulayın.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: muted),
        ),
        const SizedBox(height: 10),
        if (exercises.isEmpty)
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                kDisplayUnspecified,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: muted),
              ),
            ),
          )
        else
          for (var i = 0; i < exercises.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _PatientExerciseItemCard(index: i + 1, exercise: exercises[i]),
          ],
      ],
    );
  }
}

class _PatientExerciseItemCard extends StatelessWidget {
  final int index;
  final ExerciseItem exercise;

  const _PatientExerciseItemCard({
    required this.index,
    required this.exercise,
  });

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final staffNote = exercise.notes.trim();

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 14,
                  child: Text(
                    '$index',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    exercise.name.trim().isEmpty
                        ? kDisplayUnspecified
                        : exercise.name.trim(),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _patientExerciseLine(
              context,
              'Ne yapılacak?',
              displayField(exercise.description),
            ),
            _patientExerciseLine(
              context,
              'Kaç set / kaç tekrar?',
              '${exercise.sets} set × ${exercise.repetitions} tekrar',
            ),
            _patientExerciseLine(
              context,
              'Ne kadar süre?',
              displayField(exercise.duration),
            ),
            _patientExerciseLine(
              context,
              'Ne sıklıkla?',
              displayField(exercise.frequency),
            ),
            _patientExerciseLine(
              context,
              'Nelere dikkat edilecek?',
              displayField(exercise.precautions),
            ),
            if (staffNote.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Personel notu: $staffNote',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: muted,
                      fontStyle: FontStyle.italic,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

Widget _patientExerciseLine(
  BuildContext context,
  String question,
  String answer,
) {
  final muted = Theme.of(context).colorScheme.onSurfaceVariant;
  return Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 148,
          child: Text(
            question,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: muted,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
        Expanded(
          child: Text(
            answer,
            style: Theme.of(context).textTheme.bodyMedium,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}

class _PatientHomeInstructionsCard extends StatelessWidget {
  final String instructions;

  const _PatientHomeInstructionsCard({required this.instructions});

  @override
  Widget build(BuildContext context) {
    final text = displayField(instructions);
    final emphasized = text != kDisplayUnspecified;

    return Card(
      margin: EdgeInsets.zero,
      color: Theme.of(context).colorScheme.primaryContainer.withValues(
            alpha: 0.35,
          ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.home_outlined,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Ev Programı Talimatları',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: emphasized ? FontWeight.w500 : null,
                  ),
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _PatientPrecautionsCard extends StatelessWidget {
  final String warnings;

  const _PatientPrecautionsCard({required this.warnings});

  @override
  Widget build(BuildContext context) {
    final text = displayField(warnings);
    if (text == kDisplayUnspecified) return const SizedBox.shrink();

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning_amber_outlined,
                  size: 20,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 8),
                Text(
                  'Dikkat Edilecekler',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
