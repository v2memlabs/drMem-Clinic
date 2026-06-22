import '../models/patient_file_metadata.dart';
import '../models/patient_file_metadata_enums.dart';

/// Güvenli metadata görüntüleme — storage path, tenant, içerik yok.
abstract final class PatientFileMetadataDisplay {
  static String fileKindLabel(PatientFileKind kind) => switch (kind) {
        PatientFileKind.patientUpload => 'Hasta yüklemesi',
        PatientFileKind.generatedPdf => 'PDF çıktısı',
        PatientFileKind.consentDocument => 'Onam belgesi',
        PatientFileKind.imagingReport => 'Görüntüleme raporu',
        PatientFileKind.labReport => 'Laboratuvar',
        PatientFileKind.physiotherapyDocument => 'Fizyoterapi',
        PatientFileKind.other => 'Diğer',
      };

  static String clinicalContextLabel(PatientFileClinicalContext ctx) =>
      switch (ctx) {
        PatientFileClinicalContext.patient => 'Hasta',
        PatientFileClinicalContext.appointment => 'Randevu',
        PatientFileClinicalContext.encounter => 'Muayene',
        PatientFileClinicalContext.physiotherapy => 'Fizyoterapi',
        PatientFileClinicalContext.consent => 'Onam',
        PatientFileClinicalContext.billing => 'Fatura',
        PatientFileClinicalContext.other => 'Diğer',
      };

  static String statusLabel(PatientFileStatus status) => switch (status) {
        PatientFileStatus.active => 'Aktif',
        PatientFileStatus.archived => 'Arşiv',
        PatientFileStatus.deleted => 'Silindi',
        PatientFileStatus.other => 'Diğer',
      };

  static String visibilityScopeLabel(PatientFileVisibilityScope scope) =>
      switch (scope) {
        PatientFileVisibilityScope.doctorAdmin => 'Klinik yönetimi',
        PatientFileVisibilityScope.clinicOperations => 'Operasyon',
        PatientFileVisibilityScope.physiotherapy => 'Fizyoterapi',
        PatientFileVisibilityScope.patientShareLater => 'Hasta paylaşımı (planlı)',
        PatientFileVisibilityScope.other => 'Diğer',
      };

  /// Teknik ID göstermeden bağlam etiketi.
  static String? relationContextLabel(PatientFileMetadata file) {
    if (file.encounterId != null && file.encounterId!.isNotEmpty) {
      return 'Muayene kaydına bağlı';
    }
    if (file.appointmentId != null && file.appointmentId!.isNotEmpty) {
      return 'Randevuya bağlı';
    }
    if (file.physiotherapySessionId != null &&
        file.physiotherapySessionId!.isNotEmpty) {
      return 'Fizyoterapi seansına bağlı';
    }
    return null;
  }

  static String formatFileSize(int? bytes) {
    if (bytes == null || bytes < 0) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  static String formatDateTime(DateTime date) {
    final local = date.toLocal();
    final d = local.day.toString().padLeft(2, '0');
    final m = local.month.toString().padLeft(2, '0');
    final y = local.year;
    final h = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '$d.$m.$y $h:$min';
  }

  static String subtitleFor(PatientFileMetadata file) {
    final parts = <String>[
      fileKindLabel(file.fileKind),
      clinicalContextLabel(file.clinicalContext),
    ];
    return parts.join(' · ');
  }

  static String? metaLineFor(PatientFileMetadata file) {
    final parts = <String>[];
    final name = file.originalFileName?.trim();
    if (name != null && name.isNotEmpty) {
      parts.add(name);
    }
    final mime = file.mimeType?.trim();
    if (mime != null && mime.isNotEmpty) {
      parts.add(mime);
    }
    final size = formatFileSize(file.fileSizeBytes);
    if (size.isNotEmpty) {
      parts.add(size);
    }
    if (parts.isEmpty) return null;
    return parts.join(' · ');
  }

  static List<String> chipsFor(PatientFileMetadata file) {
    final chips = <String>[
      statusLabel(file.status),
      visibilityScopeLabel(file.visibilityScope),
    ];
    if (file.isGeneratedPdf) {
      chips.insert(0, 'PDF');
    }
    return chips;
  }

  /// Liste satırı nötr chip — ham mime gösterilmez.
  static String listNeutralChipLabel(PatientFileMetadata file) {
    if (file.isGeneratedPdf) return 'PDF';
    final mime = file.mimeType?.trim().toLowerCase() ?? '';
    if (mime.startsWith('image/')) return 'Görsel';
    if (mime.contains('pdf')) return 'PDF';
    return 'Belge';
  }

  /// Liste satırı meta (max 2) — storage/tenant/id yok.
  static List<String> listMetaLinesFor(PatientFileMetadata file) {
    final lines = <String>[];
    final relation = relationContextLabel(file);
    if (relation != null && relation.isNotEmpty) {
      lines.add(relation);
    }
    final parts = <String>[];
    final size = formatFileSize(file.fileSizeBytes);
    if (size.isNotEmpty) {
      parts.add(size);
    }
    final type = listNeutralChipLabel(file);
    if (type.isNotEmpty) {
      parts.add(type);
    }
    if (parts.isNotEmpty) {
      lines.add(parts.join(' · '));
    }
    return lines.take(2).toList();
  }
}
