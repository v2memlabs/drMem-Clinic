import 'package:flutter/material.dart';

import '../../../shared/widgets/clinical_state_message.dart';

/// Hasta timeline — ortak loading / empty / error bileşenleri.
abstract final class TimelineListUiStates {
  static Widget listLoading({required String message}) {
    return ClinicalStateMessage.loading(message: message);
  }

  static Widget listEmpty({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Center(
      child: ClinicalStateMessage.empty(
        icon: icon,
        title: title,
        description: description.isEmpty ? null : description,
      ),
    );
  }

  static Widget listNotConfigured({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Center(
      child: ClinicalStateMessage.notConfigured(
        icon: icon,
        title: title,
        description: description,
      ),
    );
  }

  static Widget listError({
    required String title,
    required String description,
    required VoidCallback? onRetry,
    bool showRetry = true,
  }) {
    return Center(
      child: ClinicalStateMessage.error(
        icon: Icons.error_outline,
        title: title,
        description: description,
        onRetry: showRetry ? onRetry : null,
      ),
    );
  }
}
