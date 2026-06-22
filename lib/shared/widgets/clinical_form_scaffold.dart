import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../layout/responsive_page_body.dart';
import 'app_shell.dart';
import 'clinical_stacked_sections.dart';
import 'form_screen_layout.dart';

/// Form ekranı kabuğu — Post-op referans: liste genişliği + kaydırılabilir gövde.
class ClinicalFormScaffold extends StatelessWidget {
  final String shellTitle;
  final Widget child;
  final VoidCallback onSave;
  final VoidCallback onCancel;
  final String saveLabel;
  final bool saving;
  final GlobalKey<FormState>? formKey;

  final ScrollController? scrollController;
  final Key? scrollViewKey;
  final double? listCacheExtent;
  final EdgeInsets? listPadding;
  final Widget? bottomBar;
  final Widget? headerBanner;
  final bool absorbPointer;

  const ClinicalFormScaffold({
    super.key,
    required this.shellTitle,
    required this.child,
    required this.onSave,
    required this.onCancel,
    required this.saveLabel,
    this.saving = false,
    this.formKey,
    this.scrollController,
    this.scrollViewKey,
    this.listCacheExtent,
    this.listPadding,
    this.bottomBar,
    this.headerBanner,
    this.absorbPointer = false,
  });

  /// Başlık + panel bölümler — [ClinicalStackedSections] ile.
  factory ClinicalFormScaffold.sections({
    Key? key,
    required String shellTitle,
    required Widget header,
    required List<Widget> sections,
    required VoidCallback onSave,
    required VoidCallback onCancel,
    required String saveLabel,
    bool saving = false,
    GlobalKey<FormState>? formKey,
    List<Widget> beforeSections = const [],
    List<Widget> afterSections = const [],
  }) {
    return ClinicalFormScaffold(
      key: key,
      shellTitle: shellTitle,
      onSave: onSave,
      onCancel: onCancel,
      saveLabel: saveLabel,
      saving: saving,
      formKey: formKey,
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
    final Widget scrollable;
    if (scrollController != null) {
      assert(
        child is Column,
        'ClinicalFormScaffold scrollController requires Column child',
      );
      final listView = ListView(
        key: scrollViewKey,
        controller: scrollController,
        cacheExtent: listCacheExtent ?? 250,
        padding: listPadding ?? const EdgeInsets.only(bottom: AppSpacing.lg),
        children: (child as Column).children,
      );
      scrollable = formKey != null ? Form(key: formKey, child: listView) : listView;
    } else {
      final body = formKey != null ? Form(key: formKey, child: child) : child;
      scrollable = SingleChildScrollView(child: body);
    }

    return AppShell(
      title: shellTitle,
      child: Column(
        children: [
          if (headerBanner != null) headerBanner!,
          Expanded(
            child: AbsorbPointer(
              absorbing: absorbPointer,
              child: ResponsiveListPage(
                child: scrollable,
              ),
            ),
          ),
          bottomBar ??
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

/// Form gövdesi alt boşluğu.
class ClinicalFormBody extends StatelessWidget {
  final List<Widget> children;

  const ClinicalFormBody({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...children,
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}
