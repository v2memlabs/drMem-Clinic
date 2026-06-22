import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/clinical_separated_list_body.dart';
import '../../clinical_encounter/data/clinical_role_summary_ui_states.dart';
import '../data/patient_file_metadata_list_load_result.dart';
import '../data/patient_file_metadata_list_user_messages.dart';
import '../widgets/patient_file_clinical_list_row.dart';

/// Metadata listesi gövdesi — loading / empty / error / notConfigured / liste.
class PatientFileMetadataListContent extends StatelessWidget {
  final bool isLoading;
  final PatientFileMetadataListLoadResult? result;
  final VoidCallback? onRetry;
  final int? maxItems;
  final bool showPreviewHintOnTap;
  final String? emptyTitle;

  const PatientFileMetadataListContent({
    super.key,
    required this.isLoading,
    required this.result,
    this.onRetry,
    this.maxItems,
    this.showPreviewHintOnTap = true,
    this.emptyTitle,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && result == null) {
      return ClinicalRoleSummaryUiStates.listLoading(
        message: PatientFileMetadataListUserMessages.loading,
      );
    }

    final active = result;
    if (active == null) {
      return ClinicalRoleSummaryUiStates.listLoading(
        message: PatientFileMetadataListUserMessages.loading,
      );
    }

    if (active.isNotConfigured) {
      return ClinicalRoleSummaryUiStates.listEmpty(
        icon: Icons.folder_off_outlined,
        title: PatientFileMetadataListUserMessages.notConfigured,
        description: PatientFileMetadataListUserMessages.notConfiguredDescription,
      );
    }

    if (active.hasError) {
      return ClinicalRoleSummaryUiStates.listError(
        title: PatientFileMetadataListUserMessages.errorTitle,
        description: PatientFileMetadataListUserMessages.errorDescription,
        onRetry: onRetry ?? () {},
      );
    }

    if (active.files.isEmpty) {
      return ClinicalRoleSummaryUiStates.listEmpty(
        icon: Icons.folder_open_outlined,
        title: emptyTitle ?? PatientFileMetadataListUserMessages.emptyForPatient,
        description: '',
      );
    }

    final visible = maxItems != null && maxItems! > 0
        ? active.files.take(maxItems!).toList()
        : active.files;

    final body = ClinicalSeparatedListBody(
      children: [
        for (final file in visible)
          PatientFileClinicalListRow(
            file: file,
            showPreviewHintOnTap: showPreviewHintOnTap,
          ),
      ],
    );

    if (maxItems != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < visible.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.sm),
            PatientFileClinicalListRow(
              file: visible[i],
              showPreviewHintOnTap: showPreviewHintOnTap,
            ),
          ],
        ],
      );
    }

    return body;
  }
}
