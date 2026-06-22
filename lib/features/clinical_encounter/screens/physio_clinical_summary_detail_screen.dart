import '../../../../shared/widgets/clinical_stacked_sections.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/layout/responsive_page_body.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/detail_header_card.dart';
import '../../../shared/widgets/info_section_card.dart';
import '../../../shared/widgets/page_header.dart';
import '../data/clinical_role_summary_ui_states.dart';
import '../data/physiotherapist_clinical_summary_detail_data_source.dart';
import '../data/physiotherapist_clinical_summary_detail_display.dart';
import '../data/physiotherapist_clinical_summary_detail_load_result.dart';
import '../data/physiotherapist_clinical_summary_detail_user_messages.dart';
import '../models/physiotherapist_clinical_summary.dart';

/// Fizyoterapist salt-okunur klinik özet — güvenli [PhysiotherapistClinicalSummary].
class PhysioClinicalSummaryDetailScreen extends StatefulWidget {
  final String id;

  const PhysioClinicalSummaryDetailScreen({super.key, required this.id});

  @override
  State<PhysioClinicalSummaryDetailScreen> createState() =>
      _PhysioClinicalSummaryDetailScreenState();
}

class _PhysioClinicalSummaryDetailScreenState
    extends State<PhysioClinicalSummaryDetailScreen> {
  late Future<PhysiotherapistClinicalSummaryDetailLoadResult> _loadFuture;
  PhysiotherapistClinicalSummaryDetailLoadResult? _cachedResult;
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
      _loadFuture =
          PhysiotherapistClinicalSummaryDetailDataSource.loadById(widget.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PhysiotherapistClinicalSummaryDetailLoadResult>(
      future: _loadFuture,
      builder: (context, snapshot) {
        final waiting = snapshot.connectionState == ConnectionState.waiting;
        final result = snapshot.data;

        if (waiting && _cachedResult == null) {
          return ClinicalRoleSummaryUiStates.detailLoadingShell(
            shellTitle:
                PhysiotherapistClinicalSummaryDetailUserMessages.shellTitle,
            message: PhysiotherapistClinicalSummaryDetailUserMessages.loading,
          );
        }

        if (result != null &&
            !result.hasError &&
            result.summary != null) {
          _cachedResult = result;
        }

        if (result?.hasError == true && _cachedResult == null) {
          return ClinicalRoleSummaryUiStates.detailErrorShell(
            shellTitle:
                PhysiotherapistClinicalSummaryDetailUserMessages.shellTitle,
            title: PhysiotherapistClinicalSummaryDetailUserMessages.errorTitle,
            description: result!.errorMessage!,
            onRetry: _reload,
          );
        }

        final summary = _cachedResult?.summary;
        if (summary == null) {
          return ClinicalRoleSummaryUiStates.detailNotFoundShell(
            shellTitle:
                PhysiotherapistClinicalSummaryDetailUserMessages.shellTitle,
            title: PhysiotherapistClinicalSummaryDetailUserMessages.notFoundTitle,
            description:
                PhysiotherapistClinicalSummaryDetailUserMessages.notFound,
          );
        }

        return _buildContent(context, summary);
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    PhysiotherapistClinicalSummary summary,
  ) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final diagnosisRows =
        PhysiotherapistClinicalSummaryDetailDisplay.diagnosisRows(summary);

    return AppShell(
      title: 'Klinik Özet',
      child: ResponsiveDetailPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PageHeader(
              title: 'Klinik Özet',
              icon: Icons.summarize_outlined,
              leadingBack: true,
              fallbackRoute: '/physiotherapy/clinical-summaries',
            ),
            DetailHeaderCard(
              title: summary.patientDisplayName,
              subtitle: PhysiotherapistClinicalSummaryDetailDisplay.headerSubtitle(
                summary,
              ),
              chips: [
                Chip(
                  label: const Text('Salt-okunur'),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
            Text(
              'Tam muayene kaydı, anamnez ve iç hekim notları bu ekranda gösterilmez.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: muted),
            ),
            ClinicalStackedSections(
              children: [
                InfoSectionCard(
                  title: 'Hasta ve Muayene Bilgisi',
                  rows: PhysiotherapistClinicalSummaryDetailDisplay.patientRows(
                    summary,
                  ),
                ),
                if (diagnosisRows.isNotEmpty)
                  InfoSectionCard(
                    title: 'Tanı / Plan Özeti',
                    rows: diagnosisRows,
                  ),
                InfoSectionCard(
                  title: 'Fizyoterapi / Rehabilitasyon',
                  rows: PhysiotherapistClinicalSummaryDetailDisplay.rehabRows(
                    summary,
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
