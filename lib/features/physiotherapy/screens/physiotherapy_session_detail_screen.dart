import '../../../../shared/widgets/clinical_stacked_sections.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../features/patients/widgets/patient_lookup_builder.dart';
import '../../../shared/layout/responsive_page_body.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/clinical_state_message.dart';
import '../../../shared/widgets/detail_header_card.dart';
import '../../../shared/widgets/info_section_card.dart';
import '../../../shared/widgets/page_header.dart';
import '../data/physiotherapy_session_detail_data_source.dart';
import '../data/physiotherapy_session_detail_load_result.dart';
import '../data/physiotherapy_session_user_messages.dart';
import '../models/physiotherapy_session_note.dart';
import '../widgets/physiotherapy_referral_source_section.dart';

class PhysiotherapySessionDetailScreen extends StatefulWidget {
  final String id;

  const PhysiotherapySessionDetailScreen({super.key, required this.id});

  @override
  State<PhysiotherapySessionDetailScreen> createState() =>
      _PhysiotherapySessionDetailScreenState();
}

class _PhysiotherapySessionDetailScreenState
    extends State<PhysiotherapySessionDetailScreen> {
  late Future<PhysiotherapySessionDetailLoadResult> _loadFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _loadFuture = PhysiotherapySessionDetailDataSource.load(widget.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Fizyoterapi Seans Notu',
      child: FutureBuilder<PhysiotherapySessionDetailLoadResult>(
        future: _loadFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return ClinicalStateMessage.loading(
              message: PhysiotherapySessionDetailUserMessages.loading,
            );
          }

          final result = snapshot.data!;
          if (result.hasError) {
            return ClinicalStateMessage.error(
              icon: Icons.error_outline,
              title: PhysiotherapySessionDetailUserMessages.errorTitle,
              description: result.errorMessage!,
              onRetry: _reload,
            );
          }

          final note = result.session;
          if (note == null) {
            return ClinicalStateMessage.empty(
              title: PhysiotherapySessionDetailUserMessages.notFoundTitle,
              description:
                  PhysiotherapySessionDetailUserMessages.notFoundDescription,
              icon: Icons.error_outline,
            );
          }

          return _buildContent(context, note);
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, PhysiotherapySessionNote note) {
    return PatientLookupBuilder(
      patientId: note.patientId,
      builder: (context, patient) {
        final fileNo = patient?.fileNumber ?? '';
        return _buildSessionDetailBody(context, note, fileNo);
      },
    );
  }

  Widget _buildSessionDetailBody(
    BuildContext context,
    PhysiotherapySessionNote note,
    String fileNo,
  ) {
    final sessionStr = _formatDate(note.sessionDate);
    final refId = note.referralId?.trim() ?? '';

    final sections = <Widget>[
      InfoSectionCard(
        title: 'Hasta ve Seans Bilgisi',
        rows: [
          InfoSectionRow('Hasta', note.patientName, emphasize: true),
          InfoSectionRow(
            'Hasta dosya no',
            fileNo.isEmpty ? kDisplayUnspecified : fileNo,
          ),
          InfoSectionRow('Seans tarihi', sessionStr),
          InfoSectionRow(
            'Fizyoterapist',
            displayField(note.physiotherapistName),
          ),
          InfoSectionRow('Ağrı skoru (VAS)', '${note.painScore}/10'),
          InfoSectionRow(
            'Spora dönüş aşaması',
            note.returnToSportLabel,
          ),
          if (note.doctorNotificationNeeded)
            InfoSectionRow(
              'Doktor bildirimi',
              'Doktor bildirimi gerekli',
              emphasize: true,
            ),
        ],
      ),
      InfoSectionCard(
        title: 'Seans Özeti',
        rows: [
          InfoSectionRow(
            'Fonksiyonel değerlendirme',
            displayField(note.functionalAssessment),
            emphasize: true,
          ),
          InfoSectionRow(
            'ROM özeti',
            displayField(note.rangeOfMotionSummary),
          ),
          InfoSectionRow(
            'Kuvvet özeti',
            displayField(note.strengthSummary),
          ),
          InfoSectionRow(
            'Yapılan egzersizler',
            displayField(note.exercisesPerformed),
          ),
          InfoSectionRow(
            'Ev programı uyumu',
            displayField(note.homeProgramCompliance),
          ),
        ],
      ),
      InfoSectionCard(
        title: 'Fizyoterapist Notları',
        rows: [
          InfoSectionRow('Notlar', displayField(note.notes)),
          InfoSectionRow(
            'Uyarı bulguları',
            displayField(note.warningSigns),
          ),
        ],
      ),
    ];

    return ResponsiveDetailPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PageHeader(
            title: 'Fizyoterapi Seans Notu',
            icon: Icons.fitness_center_outlined,
            leadingBack: true,
            fallbackRoute: '/physiotherapy/sessions',
          ),
          DetailHeaderCard(
            title: note.patientName,
            subtitle: sessionStr,
          ),
          ClinicalStackedSections(children: sections),
          if (refId.isNotEmpty)
            PhysiotherapyReferralSourceSection(referralId: refId),
          const SizedBox(height: AppSpacing.md),
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
