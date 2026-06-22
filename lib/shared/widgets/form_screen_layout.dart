import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../layout/app_breakpoints.dart';
import '../layout/responsive_layout.dart';
import '../layout/responsive_page_body.dart';
import 'clinical_stacked_sections.dart';

/// Form ekranı layout sabitleri ve alt aksiyon çubuğu.
abstract final class FormScreenLayout {
  /// Uzun formlar (muayene, egzersiz).
  static const double maxWidthLong = AppBreakpoints.formLongMaxWidth;

  /// Standart formlar.
  static const double maxWidthStandard = AppBreakpoints.formStandardMaxWidth;

  static double contentWidth(double viewportWidth, {bool longForm = false}) {
    return ResponsiveLayout.formContentMaxWidth(
      viewportWidth,
      longForm: longForm,
    );
  }

  /// Post-op referans — liste genişliğinde kaydırılabilir form gövdesi.
  static Widget listAlignedScroll({
    Widget? header,
    required List<Widget> sections,
    GlobalKey<FormState>? formKey,
    List<Widget> beforeSections = const [],
    List<Widget> afterSections = const [],
  }) {
    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (header != null) header,
        ...beforeSections,
        ClinicalStackedSections(children: sections),
        ...afterSections,
        const SizedBox(height: AppSpacing.lg),
      ],
    );
    final body = formKey != null ? Form(key: formKey, child: column) : column;
    return ResponsiveListPage(
      child: SingleChildScrollView(child: body),
    );
  }

  static EdgeInsets scrollPadding({bool withBottomBar = true}) {
    return EdgeInsets.fromLTRB(
      AppSpacing.md,
      AppSpacing.md,
      AppSpacing.md,
      withBottomBar ? AppSpacing.sm : AppSpacing.md,
    );
  }

  /// Kartsız form alt aksiyonları — detay [DetailActionsPanel] flat ile uyumlu.
  static Widget flatBottomActions({
    required VoidCallback onSave,
    required VoidCallback onCancel,
    required String saveLabel,
    String title = 'Kayıt',
    bool saving = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            top: AppSpacing.md,
            bottom: AppSpacing.sm,
          ),
          child: Divider(height: 1, thickness: 1, color: AppColors.borderSoft),
        ),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryDeepTeal,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            OutlinedButton(
              onPressed: saving ? null : onCancel,
              child: const Text('İptal'),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: FilledButton(
                onPressed: saving ? null : onSave,
                child: saving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator.adaptive(
                          strokeWidth: 2,
                        ),
                      )
                    : Text(saveLabel),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Kaydet + İptal alt satırı — form gövdesiyle aynı yatay hizada, tam genişlik.
  static Widget bottomActions({
    required VoidCallback onSave,
    required VoidCallback onCancel,
    required String saveLabel,
    double? maxWidth,
    bool saving = false,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final pagePad = ResponsiveLayout.pagePadding(constraints.maxWidth);
        return DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            border: Border(
              top: BorderSide(color: AppColors.borderSoft),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              pagePad.left,
              AppSpacing.sm,
              pagePad.right,
              AppSpacing.md,
            ),
            child: Row(
              children: [
                OutlinedButton(
                  onPressed: saving ? null : onCancel,
                  child: const Text('İptal'),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FilledButton(
                    onPressed: saving ? null : onSave,
                    child: saving
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator.adaptive(
                              strokeWidth: 2,
                            ),
                          )
                        : Text(saveLabel),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
