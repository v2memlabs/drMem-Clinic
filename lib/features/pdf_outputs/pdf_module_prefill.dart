import '../appointments/models/appointment.dart';
import '../exercises/models/exercise_plan.dart';
import '../imaging/data/imaging_repository.dart';
import '../imaging/models/imaging_note.dart';
import '../physiotherapy/models/physiotherapy_referral.dart';
import '../post_op_protocols/models/post_op_protocol.dart';
import '../surgery/models/surgery_procedure_note.dart';

/// Modül kaynaklarından PDF meta özeti (hassas alanlar hariç).
class PdfModulePrefill {
  PdfModulePrefill._();

  static const String unspecified = 'Belirtilmedi';

  static const String defaultWarningNote =
      'Bu belge, klinik değerlendirme sonrası bilgilendirme amacıyla hazırlanmıştır. '
      'Tedavi ve bakım planı kişiye özeldir. Hekim önerisi dışında uygulanmamalıdır. '
      'Belge çıktısı alınmadan önce hekim tarafından kontrol edilmelidir.';

  // --- Randevu ---

  static String appointmentTitle(String patientName, DateTime dateTime) {
    final name = patientName.trim().isEmpty ? 'Hasta' : patientName.trim();
    final local = dateTime.toLocal();
    final d = local.day.toString().padLeft(2, '0');
    final m = local.month.toString().padLeft(2, '0');
    return 'Randevu — $name ($d.$m.${local.year})';
  }

  static String appointmentContentSummary(Appointment a) {
    final local = a.appointmentDateTime.toLocal();
    final time =
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    final lines = <String>[
      'Randevu türü: ${appointmentTypeLabel(a.type)}',
      'Tarih / saat: ${_formatDate(local)} $time',
      'Durum: ${appointmentStatusLabel(a.status)}',
      'Süre: ${a.durationMinutes} dakika',
    ];
    final reason = a.reason.trim();
    if (reason.isNotEmpty) {
      lines.add('Randevu nedeni: ${_truncate(reason, 120)}');
    }
    final notes = a.notes.trim();
    if (notes.isNotEmpty) {
      lines.add('Notlar: ${_truncate(notes, 80)}');
    }
    return lines.join('\n');
  }

  static String appointmentRelatedDiagnosis(Appointment a) {
    final reason = a.reason.trim();
    return reason.isEmpty ? unspecified : _truncate(reason, 120);
  }

  // --- Post-op ---

  static String postOpTitle(String patientName) {
    final name = patientName.trim().isEmpty ? 'Hasta' : patientName.trim();
    return 'Post-op Protokol — $name';
  }

  static String postOpContentSummary(
    PostOpProtocol p, {
    String? linkedSurgeryProcedureName,
  }) {
    final lines = <String>[
      'Protokol: ${p.protocolTitle}',
      'Faz: ${postOpPhaseLabel(p.phase)}',
      'Durum: ${postOpProtocolStatusLabel(p.status)}',
    ];

    final procedure = p.diagnosisOrProcedureSummary.trim();
    if (procedure.isNotEmpty) {
      lines.add('İşlem / tanı özeti: ${_truncate(procedure, 100)}');
    }

    final linkedSurgery = linkedSurgeryProcedureName?.trim() ?? '';
    if (linkedSurgery.isNotEmpty) {
      lines.add('İlişkili girişim: $linkedSurgery');
    }

    if (p.controlDate != null) {
      lines.add('Kontrol tarihi: ${_formatDate(p.controlDate!)}');
    }

    final physio = p.physiotherapyInstructions.trim();
    if (physio.isNotEmpty) {
      lines.add('Fizyoterapi önerisi: ${_truncate(physio, 100)}');
    }

    final exercise = p.exerciseRestrictions.trim();
    if (exercise.isNotEmpty) {
      lines.add('Egzersiz kısıtları: ${_truncate(exercise, 80)}');
    }

    return lines.join('\n');
  }

  static String postOpRelatedPlan(PostOpProtocol p) {
    final bearing = p.weightBearingStatus.trim();
    if (bearing.isNotEmpty) return _truncate(bearing, 120);
    return unspecified;
  }

  // --- Egzersiz ---

  static String exerciseTitle(String patientName) {
    final name = patientName.trim().isEmpty ? 'Hasta' : patientName.trim();
    return 'Egzersiz Programı — $name';
  }

  static String exerciseContentSummary(ExercisePlan p) {
    final lines = <String>[
      'Program: ${p.title}',
      'Hedef: ${_truncate(p.goal.trim().isEmpty ? unspecified : p.goal, 100)}',
      'Faz: ${exercisePlanPhaseLabel(p.phase)}',
      'Durum: ${exercisePlanStatusLabel(p.status)}',
    ];

    if (p.doctorApproved) {
      lines.add('Doktor onayı: Onaylandı');
    }

    final instructions = p.homeInstructions.trim();
    if (instructions.isNotEmpty) {
      lines.add('Ev uygulaması: ${_truncate(instructions, 100)}');
    }

    if (p.exercises.isNotEmpty) {
      final names = p.exercises.take(3).map((e) => e.name).join(', ');
      final suffix = p.exercises.length > 3 ? ' (+${p.exercises.length - 3} egzersiz)' : '';
      lines.add('Egzersizler (özet): $names$suffix');
    }

    if (p.controlDate != null) {
      lines.add('Kontrol tarihi: ${_formatDate(p.controlDate!)}');
    }

    return lines.join('\n');
  }

  static String exerciseRelatedDiagnosis(ExercisePlan p) {
    final dx = p.diagnosisSummary.trim();
    return dx.isEmpty ? unspecified : _truncate(dx, 120);
  }

  // --- Ameliyat ---

  static String surgeryTitle(String patientName) {
    final name = patientName.trim().isEmpty ? 'Hasta' : patientName.trim();
    return 'Ameliyat / Girişim Notu — $name';
  }

  static String surgeryContentSummary(SurgeryProcedureNote n) {
    final lines = <String>[
      'İşlem: ${n.procedureName}',
      'İşlem tarihi: ${_formatDate(n.procedureDate)}',
      'Bölge / taraf: ${surgeryBodyRegionLabel(n.bodyRegion)} / ${surgerySideLabel(n.side)}',
      'İşlem tipi: ${procedureTypeLabel(n.procedureType)}',
    ];

    final dx = n.diagnosis.trim();
    if (dx.isNotEmpty) {
      lines.add('Tanı özeti: ${_truncate(dx, 100)}');
    }

    final postOp = n.postOpRecommendations.trim();
    if (postOp.isNotEmpty) {
      lines.add('Post-op öneri (kısa): ${_truncate(postOp, 100)}');
    }

    final physio = n.physiotherapyStartRecommendation.trim();
    if (physio.isNotEmpty) {
      lines.add('Fizyoterapi başlangıç: ${_truncate(physio, 80)}');
    }

    return lines.join('\n');
  }

  static String surgeryRelatedDiagnosis(SurgeryProcedureNote n) {
    final dx = n.diagnosis.trim();
    return dx.isEmpty ? unspecified : _truncate(dx, 120);
  }

  // --- Görüntüleme ---

  static String imagingTitle(String patientName) {
    final name = patientName.trim().isEmpty ? 'Hasta' : patientName.trim();
    return 'Görüntüleme Özeti — $name';
  }

  static String imagingContentSummary(ImagingNote n) {
    final lines = <String>[
      'Görüntüleme tipi: ${ImagingRepository.typeLabel(n.imagingType)}',
      'Görüntüleme tarihi: ${_formatDate(n.imagingDate)}',
      'Bölge / taraf: ${ImagingRepository.regionLabel(n.bodyRegion)} / ${imagingSideLabel(n.side)}',
    ];

    final center = n.imagingCenter.trim();
    if (center.isNotEmpty) {
      lines.add('Merkez: $center');
    }

    final report = n.reportSummary.trim();
    if (report.isNotEmpty) {
      lines.add('Rapor özeti: ${_truncate(report, 120)}');
    }

    final comment = n.doctorComment.trim();
    if (comment.isNotEmpty) {
      lines.add('Klinik değerlendirme: ${_truncate(comment, 100)}');
    }

    final relatedDx = n.relatedDiagnosis.trim();
    if (relatedDx.isNotEmpty) {
      lines.add('İlgili tanı: ${_truncate(relatedDx, 80)}');
    }

    return lines.join('\n');
  }

  static String imagingRelatedDiagnosis(ImagingNote n) {
    final dx = n.relatedDiagnosis.trim();
    return dx.isEmpty ? unspecified : _truncate(dx, 120);
  }

  // --- Fizyoterapi yönlendirme (lookup form/detail async hattında) ---

  static String physiotherapyReferralTitle(String patientName) {
    final name = patientName.trim().isEmpty ? 'Hasta' : patientName.trim();
    return 'Fizyoterapi Yönlendirme — $name';
  }

  static String physiotherapyReferralContentSummary(PhysiotherapyReferral r) {
    final lines = <String>[
      'Yönlendirme tarihi: ${_formatDate(r.referredAt)}',
      'Durum: ${r.statusLabel}',
      'Fizyoterapist: ${r.physiotherapistName}',
    ];

    final dx = r.diagnosisSummary.trim();
    if (dx.isNotEmpty) {
      lines.add('Tanı özeti: ${_truncate(dx, 100)}');
    }

    final goal = r.treatmentGoal.trim();
    if (goal.isNotEmpty) {
      lines.add('Hedef: ${_truncate(goal, 100)}');
    }

    final precautions = r.precautions.trim();
    if (precautions.isNotEmpty) {
      lines.add('Takip / dikkat: ${_truncate(precautions, 80)}');
    }

    final allowed = r.allowedActivities.trim();
    if (allowed.isNotEmpty) {
      lines.add('İzin verilen: ${_truncate(allowed, 60)}');
    }

    if (r.targetReturnToSportDate != null) {
      lines.add('Spora dönüş hedefi: ${_formatDate(r.targetReturnToSportDate!)}');
    }

    final referredBy = r.referredBy.trim();
    if (referredBy.isNotEmpty) {
      lines.add('Yönlendiren hekim: $referredBy');
    }

    return lines.join('\n');
  }

  static String physiotherapyReferralRelatedDiagnosis(PhysiotherapyReferral r) {
    final dx = r.diagnosisSummary.trim();
    return dx.isEmpty ? unspecified : _truncate(dx, 120);
  }

  static String _formatDate(DateTime date) {
    final local = date.toLocal();
    final d = local.day.toString().padLeft(2, '0');
    final m = local.month.toString().padLeft(2, '0');
    return '$d.$m.${local.year}';
  }

  static String _truncate(String text, int maxLen) {
    final t = text.trim();
    if (t.length <= maxLen) return t;
    return '${t.substring(0, maxLen)}…';
  }
}
