import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/layout/responsive_page_body.dart';
import '../../../shared/widgets/clinical_stacked_sections.dart';
import '../../../shared/widgets/form_screen_layout.dart';
import 'maintenance_scaffold.dart';

/// Bakım konsolu form kabuğu — klinik [ClinicalFormScaffold] ile aynı alt aksiyon kalıbı.
class MaintenanceFormScaffold extends StatelessWidget {
  final String title;
  final Widget child;
  final VoidCallback onSave;
  final VoidCallback onCancel;
  final String saveLabel;
  final bool saving;
  final GlobalKey<FormState>? formKey;
  final Widget? headerBanner;
  final List<Widget>? actions;

  const MaintenanceFormScaffold({
    super.key,
    required this.title,
    required this.child,
    required this.onSave,
    required this.onCancel,
    required this.saveLabel,
    this.saving = false,
    this.formKey,
    this.headerBanner,
    this.actions,
  });

  factory MaintenanceFormScaffold.sections({
    Key? key,
    required String title,
    required Widget header,
    required List<Widget> sections,
    required VoidCallback onSave,
    required VoidCallback onCancel,
    required String saveLabel,
    bool saving = false,
    GlobalKey<FormState>? formKey,
    Widget? headerBanner,
    List<Widget> beforeSections = const [],
    List<Widget> afterSections = const [],
    List<Widget>? actions,
  }) {
    return MaintenanceFormScaffold(
      key: key,
      title: title,
      onSave: onSave,
      onCancel: onCancel,
      saveLabel: saveLabel,
      saving: saving,
      formKey: formKey,
      headerBanner: headerBanner,
      actions: actions,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          ...beforeSections,
          ClinicalStackedSections(children: sections),
          ...afterSections,
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final body = formKey != null ? Form(key: formKey, child: child) : child;

    return MaintenanceScaffold(
      title: title,
      actions: actions,
      child: Column(
        children: [
          if (headerBanner != null) headerBanner!,
          Expanded(
            child: ResponsiveListPage(
              child: SingleChildScrollView(
                child: body,
              ),
            ),
          ),
          FormScreenLayout.bottomActions(
            onSave: onSave,
            onCancel: onCancel,
            saveLabel: saveLabel,
            saving: saving,
          ),
        ],
      ),
    );
  }
}
