import 'package:flutter/material.dart';

import '../models/timeline_event.dart';
import '../models/timeline_event_enums.dart';

/// Güvenli timeline görüntüleme — audit/internal note/storage yok.
abstract final class TimelineEventDisplay {
  static String eventTypeLabel(TimelineEventType type) => switch (type) {
        TimelineEventType.patientCreated => 'Hasta kaydı',
        TimelineEventType.patientUpdated => 'Hasta güncelleme',
        TimelineEventType.appointmentCreated => 'Randevu',
        TimelineEventType.appointmentUpdated => 'Randevu güncelleme',
        TimelineEventType.appointmentCancelled => 'Randevu iptal',
        TimelineEventType.appointmentCompleted => 'Randevu tamamlandı',
        TimelineEventType.clinicalEncounterCreated => 'Muayene',
        TimelineEventType.clinicalEncounterUpdated => 'Muayene güncelleme',
        TimelineEventType.clinicalEncounterCompleted => 'Muayene tamamlandı',
        TimelineEventType.fileMetadataCreated => 'Dosya kaydı',
        TimelineEventType.fileMetadataArchived => 'Dosya arşiv',
        TimelineEventType.pdfMetadataCreated => 'PDF çıktısı',
        TimelineEventType.pdfMetadataArchived => 'PDF arşiv',
        TimelineEventType.other => 'Klinik olay',
      };

  static String eventGroupLabel(TimelineEventGroup group) => switch (group) {
        TimelineEventGroup.patient => 'Hasta',
        TimelineEventGroup.appointment => 'Randevu',
        TimelineEventGroup.clinical => 'Muayene',
        TimelineEventGroup.file => 'Dosya',
        TimelineEventGroup.pdf => 'PDF',
        TimelineEventGroup.consent => 'Onam',
        TimelineEventGroup.physiotherapy => 'Fizyoterapi',
        TimelineEventGroup.other => 'Diğer',
      };

  static String formatDateTime(DateTime date) {
    final local = date.toLocal();
    final d = local.day.toString().padLeft(2, '0');
    final m = local.month.toString().padLeft(2, '0');
    final h = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '$d.$m.${local.year} $h:$min';
  }

  static IconData iconFor(TimelineEvent event) {
    final key = event.iconKey?.trim();
    if (key != null && key.isNotEmpty) {
      return switch (key) {
        'patient' => Icons.person_outline,
        'calendar' => Icons.event_outlined,
        'clinical' => Icons.medical_services_outlined,
        'file' => Icons.folder_outlined,
        'pdf' => Icons.picture_as_pdf_outlined,
        'consent' => Icons.shield_outlined,
        'physiotherapy' => Icons.self_improvement_outlined,
        _ => Icons.timeline_outlined,
      };
    }
    return switch (event.eventGroup) {
      TimelineEventGroup.patient => Icons.person_outline,
      TimelineEventGroup.appointment => Icons.event_outlined,
      TimelineEventGroup.clinical => Icons.medical_services_outlined,
      TimelineEventGroup.file => Icons.folder_outlined,
      TimelineEventGroup.pdf => Icons.picture_as_pdf_outlined,
      TimelineEventGroup.consent => Icons.shield_outlined,
      TimelineEventGroup.physiotherapy => Icons.self_improvement_outlined,
      TimelineEventGroup.other => Icons.timeline_outlined,
    };
  }

  static List<String> chipsFor(TimelineEvent event) {
    final chips = <String>[
      eventTypeLabel(event.eventType),
      eventGroupLabel(event.eventGroup),
    ];
    final status = event.status?.trim();
    if (status != null && status.isNotEmpty) {
      chips.add(status);
    }
    chips.addAll(metadataChipLabels(event.metadata));
    return chips;
  }

  static List<String> metadataChipLabels(Map<String, Object?> metadata) {
    final out = <String>[];
    void addKey(String key, String label) {
      final v = metadata[key];
      if (v == null) return;
      final s = v.toString().trim();
      if (s.isEmpty) return;
      out.add('$label: $s');
    }

    addKey('appointment_status', 'Durum');
    addKey('visit_type', 'Ziyaret');
    addKey('file_kind', 'Tür');
    addKey('clinical_context', 'Bağlam');
    addKey('encounter_status', 'Muayene durumu');
    return out;
  }
}
