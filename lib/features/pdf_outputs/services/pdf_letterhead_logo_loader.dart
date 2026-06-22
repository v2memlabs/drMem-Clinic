import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/widgets.dart' as pw;

import '../../settings/data/settings_image_storage_path_builder.dart';
import '../../settings/data/settings_image_storage_repository_provider.dart';
import 'pdf_letterhead_config.dart';

/// Klinik logosu — önce Ayarlar depolama yolu, yoksa varsayılan asset.
Future<pw.ImageProvider?> loadPdfLetterheadLogo(
  PdfLetterheadConfig letterhead,
) async {
  final storagePath = letterhead.logoStoragePath?.trim() ?? '';
  if (storagePath.isNotEmpty) {
    try {
      final bytes = await SettingsImageStorageRepositoryProvider.repository
          .downloadBytes(
        bucket: SettingsImageStoragePathBuilder.defaultBucket,
        path: storagePath,
      );
      if (bytes != null && bytes.isNotEmpty) {
        return pw.MemoryImage(bytes);
      }
    } catch (_) {
      // Asset yedeğine düş.
    }
  }

  try {
    final logoData = await rootBundle.load(letterhead.logoAssetPath);
    return pw.MemoryImage(logoData.buffer.asUint8List());
  } catch (_) {
    return null;
  }
}
