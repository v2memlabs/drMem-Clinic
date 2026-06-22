import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../shared/layout/responsive_page_body.dart';
import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/clinical_stacked_sections.dart';
import '../../shared/widgets/detail_header_card.dart';
import '../../shared/widgets/info_section_card.dart';
import '../../shared/widgets/page_header.dart';
import 'data/clinical_encounter_diagnosis_display.dart';
import 'data/assistant_clinical_summary_detail_data_source.dart';
import 'data/assistant_clinical_summary_detail_display.dart';
import 'data/assistant_clinical_summary_detail_load_result.dart';
import 'data/assistant_clinical_summary_detail_user_messages.dart';
import 'data/clinical_role_summary_ui_states.dart';
import 'models/assistant_clinical_summary.dart';

/// Operasyonel tanı detayı — güvenli [AssistantClinicalSummary] projection.
class ClinicalDiagnosisSummaryDetailScreen extends StatefulWidget {
  final String id;

  const ClinicalDiagnosisSummaryDetailScreen({super.key, required this.id});

  @override
  State<ClinicalDiagnosisSummaryDetailScreen> createState() =>
      _ClinicalDiagnosisSummaryDetailScreenState();
}

class _ClinicalDiagnosisSummaryDetailScreenState
    extends State<ClinicalDiagnosisSummaryDetailScreen> {
  late Future<AssistantClinicalSummaryDetailLoadResult> _loadFuture;
  AssistantClinicalSummaryDetailLoadResult? _cachedResult;
  bool _activatedOnce = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void activate() {
    super.activate();
    if (!_activatedOnce) {
      _activatedOnce = true;
      return;
    }
    _reload();
  }

  void _reload() {
    setState(() {
      _cachedResult = null;
      _loadFuture = AssistantClinicalSummaryDetailDataSource.loadById(widget.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AssistantClinicalSummaryDetailLoadResult>(
      future: _loadFuture,
      builder: (context, snapshot) {
        final waiting = snapshot.connectionState == ConnectionState.waiting;
        final result = snapshot.data;

        if (waiting && _cachedResult == null) {
          return ClinicalRoleSummaryUiStates.detailLoadingShell(
            shellTitle: AssistantClinicalSummaryDetailUserMessages.shellTitle,
            message: AssistantClinicalSummaryDetailUserMessages.loading,
          );
        }

        if (result != null &&
            !result.hasError &&
            result.summary != null) {
          _cachedResult = result;
        }

        if (result?.hasError == true && _cachedResult == null) {
          return ClinicalRoleSummaryUiStates.detailErrorShell(
            shellTitle: AssistantClinicalSummaryDetailUserMessages.shellTitle,
            title: AssistantClinicalSummaryDetailUserMessages.errorTitle,
            description: result!.errorMessage!,
            onRetry: _reload,
          );
        }

        final summary = _cachedResult?.summary;
        if (summary == null) {
          return ClinicalRoleSummaryUiStates.detailNotFoundShell(
            shellTitle: AssistantClinicalSummaryDetailUserMessages.shellTitle,
            title: AssistantClinicalSummaryDetailUserMessages.notFoundTitle,
            description: AssistantClinicalSummaryDetailUserMessages.notFound,
          );
        }

        return _buildContent(summary);
      },
    );
  }

  Widget _buildContent(AssistantClinicalSummary summary) {
    final rows = AssistantClinicalSummaryDetailDisplay.detailRows(summary);

    return AppShell(
      title: ClinicalEncounterDiagnosisDisplay.summaryTitle,
      child: ResponsiveDetailPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PageHeader(
              title: ClinicalEncounterDiagnosisDisplay.summaryTitle,
              icon: Icons.summarize_outlined,
              leadingBack: true,
              fallbackRoute: '/clinical-records/diagnosis-summary',
            ),
            DetailHeaderCard(
              title: summary.patientDisplayName,
              subtitle: AssistantClinicalSummaryDetailDisplay.headerSubtitle(
                summary,
              ),
            ),
            ClinicalStackedSections(
              children: [
                InfoSectionCard(
                  title: 'Klinik Özet',
                  rows: rows,
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
