import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import 'patient_file_signed_url_service.dart';

/// Signed URL'yi geçici olarak viewer'da açar — URL kalıcı state'e yazılmaz.
abstract final class PatientFileViewLauncher {
  static Future<void> openPatientFile(String fileId) async {
    final url = await PatientFileSignedUrlService.createViewUrlForPatientFile(
      fileId,
    );

    if (kIsWeb && url.startsWith('drmem-mock://')) {
      throw const PatientFileSignedUrlException(
        'Bu ortamda dosya önizlemesi desteklenmiyor.',
      );
    }

    final uri = Uri.parse(url);
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched) {
      throw const PatientFileSignedUrlException(
        'Dosya açılırken bir sorun oluştu.',
      );
    }
  }
}
