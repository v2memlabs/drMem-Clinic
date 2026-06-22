import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../models/surgery_procedure_note.dart';

/// Ameliyat / işlem liste satırı — tip renk kodları ve metin yardımcıları.
abstract final class SurgeryProcedureListDisplay {
  static Color markerColorForType(ProcedureType type) {
    switch (listCategoryForType(type)) {
      case SurgeryProcedureListCategory.ameliyat:
        return AppColors.primaryDeepTeal;
      case SurgeryProcedureListCategory.girisim:
        return AppColors.accentTurquoise;
      case SurgeryProcedureListCategory.islem:
        return AppColors.navy;
      case SurgeryProcedureListCategory.pansuman:
        return const Color(0xFF6A1B9A);
    }
  }

  @visibleForTesting
  static SurgeryProcedureListCategory listCategoryForType(ProcedureType type) {
    switch (type) {
      case ProcedureType.ameliyat:
        return SurgeryProcedureListCategory.ameliyat;
      case ProcedureType.artroskopi:
      case ProcedureType.enjeksiyonGirisim:
        return SurgeryProcedureListCategory.girisim;
      case ProcedureType.yaraPansuman:
        return SurgeryProcedureListCategory.pansuman;
      case ProcedureType.kontrolAmacli:
      case ProcedureType.diger:
        return SurgeryProcedureListCategory.islem;
    }
  }

  /// Üst satır: dosya no + tanı (etiketsiz).
  static String? metaLine({
    String? fileNumber,
    required String diagnosis,
  }) {
    final parts = <String>[];
    final file = fileNumber?.trim() ?? '';
    if (file.isNotEmpty) parts.add('Dosya: $file');
    final dx = diagnosis.trim();
    if (dx.isNotEmpty) parts.add(dx);
    if (parts.isEmpty) return null;
    return parts.join(' · ');
  }

  /// Alt satır: işlem adı + cerrah.
  static String detailLine({
    required String procedureName,
    required String surgeonName,
  }) {
    final proc = procedureName.trim();
    final surgeon = surgeonName.trim();
    final surgeonLabel = surgeon.isEmpty ? 'Belirtilmedi' : surgeon;
    if (proc.isEmpty) return 'Cerrah: $surgeonLabel';
    return '$proc · Cerrah: $surgeonLabel';
  }

  static String formatProcedureDate(DateTime date) {
    final local = date.toLocal();
    final d = local.day.toString().padLeft(2, '0');
    final m = local.month.toString().padLeft(2, '0');
    return '$d.$m.${local.year}';
  }
}

enum SurgeryProcedureListCategory {
  ameliyat,
  girisim,
  islem,
  pansuman,
}
