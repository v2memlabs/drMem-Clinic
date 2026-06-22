import 'package:flutter/material.dart';

import 'clinical_state_message.dart';
import 'clinical_ui_text_sanitizer.dart';

/// Güvenli SnackBar mesajları — teknik metin/exception sızıntısını engeller.
abstract final class ClinicalSnackBar {
  static const genericErrorMessage =
      'İşlem tamamlanamadı. Lütfen tekrar deneyin.';
  static const genericSuccessMessage = 'İşlem tamamlandı.';

  /// SnackBar için güvenli metin üretir.
  static String safeMessage(String? message, {required bool isError}) {
    if (message == null || message.trim().isEmpty) {
      return isError ? genericErrorMessage : genericSuccessMessage;
    }

    final trimmed = message.trim();
    if (ClinicalUiTextSanitizer.containsForbiddenToken(trimmed)) {
      return isError ? genericErrorMessage : genericSuccessMessage;
    }

    if (isError) {
      final safe = ClinicalStateMessage.safeErrorDescription(trimmed);
      if (safe == ClinicalStateMessage.genericLoadFailure) {
        return genericErrorMessage;
      }
      return safe;
    }

    final sanitized = ClinicalUiTextSanitizer.sanitize(trimmed);
    if (sanitized == '—' || sanitized.trim().isEmpty) {
      return genericSuccessMessage;
    }
    return sanitized;
  }

  static void show(
    BuildContext context,
    String message, {
    bool isError = true,
  }) {
    final text = safeMessage(message, isError: isError);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }
}

void showClinicalSnackBar(
  BuildContext context,
  String message, {
  bool isError = true,
}) {
  ClinicalSnackBar.show(context, message, isError: isError);
}
