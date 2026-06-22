import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/clinical_state_message.dart';

/// Role summary ekranları — ortak loading/error/empty bileşenleri.
abstract final class ClinicalRoleSummaryUiStates {
  static Widget listLoading({required String message}) {
    return ClinicalStateMessage.loading(message: message);
  }

  static Widget listError({
    required String title,
    required String description,
    required VoidCallback onRetry,
  }) {
    return ClinicalStateMessage.error(
      icon: Icons.error_outline,
      title: title,
      description: description,
      onRetry: onRetry,
    );
  }

  static Widget listEmpty({
    required IconData icon,
    required String title,
    required String description,
  }) {
    if (description.isEmpty) {
      return Center(
        child: ClinicalStateMessage.empty(
          icon: icon,
          title: title,
        ),
      );
    }
    return Center(
      child: ClinicalStateMessage.empty(
        icon: icon,
        title: title,
        description: description,
      ),
    );
  }

  static Widget listNotConfigured({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return listEmpty(icon: icon, title: title, description: description);
  }

  static Widget listBodyWithRefresh({
    required bool showRefreshBar,
    required Widget child,
  }) {
    if (!showRefreshBar) return child;
    return Column(
      children: [
        const LinearProgressIndicator(minHeight: 2),
        Expanded(child: child),
      ],
    );
  }

  static Widget detailLoadingShell({
    required String shellTitle,
    required String message,
  }) {
    return AppShell(
      title: shellTitle,
      child: listLoading(message: message),
    );
  }

  static Widget detailErrorShell({
    required String shellTitle,
    required String title,
    required String description,
    required VoidCallback onRetry,
  }) {
    return AppShell(
      title: shellTitle,
      child: Center(
        child: listError(
          title: title,
          description: description,
          onRetry: onRetry,
        ),
      ),
    );
  }

  static Widget detailNotFoundShell({
    required String shellTitle,
    required String title,
    required String description,
  }) {
    return AppShell(
      title: shellTitle,
      child: Center(
        child: ClinicalStateMessage.empty(
          icon: Icons.medical_information_outlined,
          title: title,
          description: description.isEmpty ? null : description,
        ),
      ),
    );
  }
}
