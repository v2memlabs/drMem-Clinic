import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Liste kartı sol şerit renkleri — durum/tip ayrımı (sade, klinik).
abstract final class ListCardAccent {
  static Color? appointmentStatus(String statusLabel) {
    final s = statusLabel.toLowerCase();
    if (s.contains('iptal') || s.contains('gelmedi')) {
      return const Color(0xFFC62828);
    }
    if (s.contains('geldi') || s.contains('tamam')) {
      return AppColors.accentTurquoise;
    }
    if (s.contains('bekl') || s.contains('plan')) {
      return const Color(0xFFF9A825);
    }
    return AppColors.navy;
  }

  static Color? consentStatus(String statusLabel) {
    final s = statusLabel.toLowerCase();
    if (s.contains('red') || s.contains('iptal')) {
      return const Color(0xFFC62828);
    }
    if (s.contains('alın') || s.contains('onay')) {
      return AppColors.accentTurquoise;
    }
    if (s.contains('bekl')) {
      return const Color(0xFFF9A825);
    }
    return AppColors.navy;
  }

  static Color? paymentStatus(String statusLabel) {
    final s = statusLabel.toLowerCase();
    if (s.contains('ödendi') || s.contains('tamam')) {
      return AppColors.accentTurquoise;
    }
    if (s.contains('kısmi') || s.contains('bekl')) {
      return const Color(0xFFF9A825);
    }
    if (s.contains('iptal')) {
      return const Color(0xFFC62828);
    }
    return AppColors.navy;
  }

  static Color? referralStatus(String statusLabel) {
    final s = statusLabel.toLowerCase();
    if (s.contains('bekl') || s.contains('değerlendir')) {
      return const Color(0xFFF9A825);
    }
    if (s.contains('aktif') || s.contains('devam')) {
      return AppColors.accentTurquoise;
    }
    return AppColors.navy;
  }
}
