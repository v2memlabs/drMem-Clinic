import '../../../core/data/repository_registry.dart';
import '../../audit/models/audit_log.dart';
import '../../appointments/models/appointment.dart';
import '../../clinical_encounter/models/clinical_encounter.dart';
import '../../consents/data/consent_repository.dart';
import '../../consents/models/consent_record.dart';
import '../../exercises/models/exercise_plan.dart';
import '../../patient_files/data/patient_file_metadata_display.dart';
import '../../imaging/data/imaging_repository.dart';
import '../../imaging/models/imaging_note.dart';
import '../../messages/models/sent_message.dart';
import '../../../core/tenant/tenant_financial_feature_gate.dart';
import '../../payments/models/payment_record.dart';
import '../../pdf_outputs/data/pdf_output_repository.dart';
import '../../pdf_outputs/models/pdf_output.dart';
import '../../physiotherapy/data/physiotherapy_repository.dart';
import '../../physiotherapy/models/physiotherapy_referral.dart';
import '../../physiotherapy/models/physiotherapy_session_note.dart';
import '../../post_op_protocols/models/post_op_protocol.dart';
import '../../surgery/models/surgery_procedure_note.dart';
import '../models/patient_timeline_event.dart';

/// Hasta timeline olaylarını gerçek repository kaynaklarından üretir (Faz 1–4).
class PatientTimelineBuilder {
  PatientTimelineBuilder._();

  static Future<List<PatientTimelineEvent>> buildAsync({String? patientId}) async {
    final events = <PatientTimelineEvent>[
      ...await _fromClinicalEncounters(patientId),
      ...await _fromAppointments(patientId),
      ...await _fromImaging(patientId),
      ...await _fromSurgery(patientId),
      ...await _fromPostOpProtocols(patientId),
      ..._fromPhysiotherapyReferrals(patientId),
      ..._fromPhysiotherapySessions(patientId),
      ...await _fromExercisePlans(patientId),
      ...await _fromPatientFiles(patientId),
      ..._fromConsentRecords(patientId),
      if (TenantFinancialFeatureGate.paymentRecordsEnabled)
        ...await _fromPayments(patientId),
      ...await _fromSentMessages(patientId),
      ..._fromPdfOutputs(patientId),
      ...await _fromAuditLogs(patientId),
    ];

    events.sort((a, b) {
      final byDate = b.eventDate.compareTo(a.eventDate);
      if (byDate != 0) return byDate;
      return a.id.compareTo(b.id);
    });

    return events;
  }

  static Future<List<ClinicalEncounter>> _clinicalEncounters(String? patientId) async {
    final repo = RepositoryRegistry.clinicalEncountersAsync;
    if (patientId != null && patientId.isNotEmpty) {
      return repo.getByPatientId(patientId);
    }
    return repo.getAll();
  }

  static Future<List<PatientTimelineEvent>> _fromClinicalEncounters(
    String? patientId,
  ) async {
    final encounters = await _clinicalEncounters(patientId);
    return encounters.map((e) {
      final diagnosis = _clinicalDiagnosisSummary(e);
      final description = [
        diagnosis,
        '${e.bodyRegion.label} / ${e.side.label}',
        e.status.label,
      ].join(' • ');

      return PatientTimelineEvent(
        id: 'ce-${e.id}',
        patientId: e.patientId,
        patientName: e.patientName,
        eventDate: e.createdAt,
        eventType: TimelineEventType.muayeneNotu,
        title: 'Muayene kaydı — ${e.visitType.label}',
        description: description,
        relatedModule: 'Muayene Kayıtları',
        relatedRecordId: e.id,
        relatedRoute: '/clinical-records/${e.id}',
        createdBy: _displayCreator(e.doctorName),
      );
    }).toList();
  }

  static String _clinicalDiagnosisSummary(ClinicalEncounter e) {
    final finalDx = e.finalDiagnosis.trim();
    if (finalDx.isNotEmpty) return _truncate(finalDx, 80);
    final prelim = e.preliminaryDiagnosis.trim();
    if (prelim.isNotEmpty) return _truncate(prelim, 80);
    return 'Belirtilmedi';
  }

  static Future<List<Appointment>> _appointments(String? patientId) async {
    final repo = RepositoryRegistry.appointmentsAsync;
    if (patientId != null && patientId.isNotEmpty) {
      return repo.getByPatientId(patientId);
    }
    return repo.getAll();
  }

  static Future<List<PatientTimelineEvent>> _fromAppointments(String? patientId) async {
    final appointments = await _appointments(patientId);
    return appointments.map((a) {
      final reason = a.reason.trim();
      final notes = a.notes.trim();
      final parts = <String>[
        appointmentStatusLabel(a.status),
        if (reason.isNotEmpty) reason else if (notes.isNotEmpty) notes,
      ];
      final description = parts.where((p) => p.isNotEmpty).join(' • ');

      return PatientTimelineEvent(
        id: 'appt-${a.id}',
        patientId: a.patientId,
        patientName: a.patientName,
        eventDate: a.appointmentDateTime,
        eventType: TimelineEventType.randevu,
        title: appointmentTypeLabel(a.type),
        description: description.isEmpty ? 'Belirtilmedi' : _truncate(description, 120),
        relatedModule: 'Randevu',
        relatedRecordId: a.id,
        relatedRoute: '/appointments/${a.id}',
        createdBy: 'Belirtilmedi',
      );
    }).toList();
  }

  static Future<List<ImagingNote>> _imagingNotes(String? patientId) async {
    final repo = RepositoryRegistry.imagingNotesAsync;
    if (patientId != null && patientId.isNotEmpty) {
      return repo.getByPatientId(patientId);
    }
    return repo.getAll();
  }

  static Future<List<PatientTimelineEvent>> _fromImaging(String? patientId) async {
    final notes = await _imagingNotes(patientId);
    return notes.map((n) {
      final summary = n.reportSummary.trim();
      return PatientTimelineEvent(
        id: 'img-${n.id}',
        patientId: n.patientId,
        patientName: n.patientName,
        eventDate: n.imagingDate,
        eventType: TimelineEventType.goruntuleme,
        title:
            '${ImagingRepository.typeLabel(n.imagingType)} — ${ImagingRepository.regionLabel(n.bodyRegion)}',
        description: summary.isEmpty ? 'Belirtilmedi' : _truncate(summary, 120),
        relatedModule: 'Görüntüleme',
        relatedRecordId: n.id,
        relatedRoute: '/imaging/${n.id}',
        createdBy: 'Belirtilmedi',
      );
    }).toList();
  }

  static Future<List<SurgeryProcedureNote>> _surgeryNotes(String? patientId) async {
    final repo = RepositoryRegistry.surgeryProcedureNotesAsync;
    if (patientId != null && patientId.isNotEmpty) {
      return repo.getByPatientId(patientId);
    }
    return repo.getAll();
  }

  static Future<List<PatientTimelineEvent>> _fromSurgery(String? patientId) async {
    final notes = await _surgeryNotes(patientId);
    return notes.map((n) {
      final diagnosis = n.diagnosis.trim();
      final description = [
        procedureTypeLabel(n.procedureType),
        if (diagnosis.isNotEmpty) diagnosis else 'Belirtilmedi',
      ].join(' • ');

      return PatientTimelineEvent(
        id: 'surg-${n.id}',
        patientId: n.patientId,
        patientName: n.patientName,
        eventDate: n.procedureDate,
        eventType: TimelineEventType.ameliyatGirisim,
        title: n.procedureName.trim().isEmpty ? 'Ameliyat / Girişim' : n.procedureName,
        description: _truncate(description, 120),
        relatedModule: 'Ameliyat / Girişim',
        relatedRecordId: n.id,
        relatedRoute: '/surgery-notes/${n.id}',
        createdBy: _displayCreator(n.surgeonName),
      );
    }).toList();
  }

  static Future<List<PostOpProtocol>> _postOpProtocols(String? patientId) async {
    final repo = RepositoryRegistry.postOpProtocolsAsync;
    if (patientId != null && patientId.isNotEmpty) {
      return repo.getByPatientId(patientId);
    }
    return repo.getAll();
  }

  static Future<List<PatientTimelineEvent>> _fromPostOpProtocols(
    String? patientId,
  ) async {
    final protocols = await _postOpProtocols(patientId);
    return protocols.map((p) {
      final summary = p.diagnosisOrProcedureSummary.trim();
      final description = [
        postOpPhaseLabel(p.phase),
        if (summary.isNotEmpty) summary else 'Belirtilmedi',
      ].join(' • ');

      return PatientTimelineEvent(
        id: 'pop-${p.id}',
        patientId: p.patientId,
        patientName: p.patientName,
        eventDate: p.createdAt,
        eventType: TimelineEventType.postOpProtokol,
        title: p.protocolTitle.trim().isEmpty ? 'Post-op Protokol' : p.protocolTitle,
        description: _truncate(description, 120),
        relatedModule: 'Post-op Protokol',
        relatedRecordId: p.id,
        relatedRoute: '/post-op-protocols/${p.id}',
        createdBy: _displayCreator(p.createdBy),
      );
    }).toList();
  }

  static List<PhysiotherapyReferral> _physiotherapyReferrals(String? patientId) {
    final repo = PhysiotherapyRepository.instance;
    if (patientId != null && patientId.isNotEmpty) {
      return repo.getReferralsByPatientId(patientId);
    }
    return repo.getReferrals();
  }

  static List<PatientTimelineEvent> _fromPhysiotherapyReferrals(String? patientId) {
    return _physiotherapyReferrals(patientId).map((r) {
      final dx = r.diagnosisSummary.trim();
      final goal = r.treatmentGoal.trim();
      final description = [
        if (dx.isNotEmpty) _truncate(dx, 60) else 'Belirtilmedi',
        if (goal.isNotEmpty) _truncate(goal, 50),
        r.statusLabel,
      ].join(' • ');

      return PatientTimelineEvent(
        id: 'ftr-ref-${r.id}',
        patientId: r.patientId,
        patientName: r.patientName,
        eventDate: r.referredAt,
        eventType: TimelineEventType.fizyoterapiYonlendirme,
        title: 'Fizyoterapi yönlendirmesi',
        description: description,
        relatedModule: 'Fizyoterapi Yönlendirme',
        relatedRecordId: r.id,
        relatedRoute: '/physiotherapy/referrals/${r.id}',
        createdBy: _displayCreator(r.referredBy),
      );
    }).toList();
  }

  static List<PhysiotherapySessionNote> _physiotherapySessions(String? patientId) {
    final repo = PhysiotherapyRepository.instance;
    if (patientId != null && patientId.isNotEmpty) {
      return repo.getSessionNotesByPatientId(patientId);
    }
    return repo.getSessionNotes();
  }

  static List<PatientTimelineEvent> _fromPhysiotherapySessions(String? patientId) {
    return _physiotherapySessions(patientId).map((s) {
      final functional = s.functionalAssessment.trim();
      final description = [
        'VAS ${s.painScore}',
        if (functional.isNotEmpty) _truncate(functional, 70) else s.returnToSportLabel,
      ].join(' • ');

      return PatientTimelineEvent(
        id: 'ftr-sess-${s.id}',
        patientId: s.patientId,
        patientName: s.patientName,
        eventDate: s.sessionDate,
        eventType: TimelineEventType.fizyoterapiSeansi,
        title: 'Fizyoterapi seansı',
        description: description,
        relatedModule: 'Fizyoterapi Seansı',
        relatedRecordId: s.id,
        relatedRoute: '/physiotherapy/sessions/${s.id}',
        createdBy: _displayCreator(s.physiotherapistName),
      );
    }).toList();
  }

  static Future<List<ExercisePlan>> _exercisePlans(String? patientId) async {
    final repo = RepositoryRegistry.exercisePlansAsync;
    if (patientId != null && patientId.isNotEmpty) {
      return repo.getByPatientId(patientId);
    }
    return repo.getAll();
  }

  static Future<List<PatientTimelineEvent>> _fromExercisePlans(
    String? patientId,
  ) async {
    final plans = await _exercisePlans(patientId);
    return plans.map((p) {
      final goal = p.goal.trim();
      final description = [
        exercisePlanPhaseLabel(p.phase),
        exercisePlanStatusLabel(p.status),
        if (goal.isNotEmpty) _truncate(goal, 50) else '${p.exercises.length} egzersiz',
      ].join(' • ');

      return PatientTimelineEvent(
        id: 'ex-${p.id}',
        patientId: p.patientId,
        patientName: p.patientName,
        eventDate: p.createdAt,
        eventType: TimelineEventType.egzersizProgrami,
        title: p.title.trim().isEmpty ? 'Egzersiz programı' : p.title,
        description: description,
        relatedModule: 'Egzersiz Programı',
        relatedRecordId: p.id,
        relatedRoute: '/exercise-plans/${p.id}',
        createdBy: _displayCreator(p.createdBy),
      );
    }).toList();
  }

  static Future<List<PatientTimelineEvent>> _fromPatientFiles(
    String? patientId,
  ) async {
    try {
      final repo = RepositoryRegistry.patientFileMetadata;
      final list = patientId != null && patientId.trim().isNotEmpty
          ? await repo.listPatientFiles(patientId: patientId.trim())
          : await repo.listTenantFiles();
      return list.map((f) {
        final typeLabel = PatientFileMetadataDisplay.fileKindLabel(f.fileKind);
        final uploadedBy =
            f.metadata['uploaded_by_display']?.toString().trim() ?? '';
        return PatientTimelineEvent(
          id: 'file-${f.id}',
          patientId: f.patientId,
          patientName: 'Hasta',
          eventDate: f.createdAt,
          eventType: TimelineEventType.dosya,
          title: '$typeLabel yüklendi',
          description: typeLabel,
          relatedModule: 'Dosya',
          relatedRecordId: f.id,
          relatedRoute: '/files/${f.id}',
          createdBy: _displayCreator(uploadedBy),
        );
      }).toList();
    } catch (_) {
      return const [];
    }
  }

  static List<ConsentRecord> _consentRecords(String? patientId) {
    final repo = ConsentRepository.instance;
    if (patientId != null && patientId.isNotEmpty) {
      return repo.getByPatientId(patientId);
    }
    return repo.getAll();
  }

  static List<PatientTimelineEvent> _fromConsentRecords(String? patientId) {
    return _consentRecords(patientId).map((c) {
      final eventDate = c.givenAt ?? c.createdAt;
      return PatientTimelineEvent(
        id: 'consent-${c.id}',
        patientId: c.patientId,
        patientName: c.patientName,
        eventDate: eventDate,
        eventType: TimelineEventType.kvkkOnam,
        title: consentTypeLabel(c.consentType),
        description: consentStatusLabel(c.status),
        relatedModule: 'KVKK / Onam',
        relatedRecordId: c.id,
        relatedRoute: '/consents/${c.id}',
        createdBy: _displayCreator(c.recordedBy),
      );
    }).toList();
  }

  static Future<List<PaymentRecord>> _payments(String? patientId) async {
    final repo = RepositoryRegistry.paymentsAsync;
    if (patientId != null && patientId.isNotEmpty) {
      return repo.getByPatientId(patientId);
    }
    return repo.getAll();
  }

  static Future<List<PatientTimelineEvent>> _fromPayments(String? patientId) async {
    final payments = await _payments(patientId);
    return payments.map((p) {
      final description = [
        p.paymentStatusLabel,
        p.paymentMethodLabel,
      ].join(' • ');

      return PatientTimelineEvent(
        id: 'pay-${p.id}',
        patientId: p.patientId,
        patientName: p.patientName,
        eventDate: p.transactionDate,
        eventType: TimelineEventType.odeme,
        title: '${p.serviceTypeLabel} — ödeme',
        description: description,
        relatedModule: 'Ödeme / Tahsilat',
        relatedRecordId: p.id,
        relatedRoute: '/payments/${p.id}',
        createdBy: _displayCreator(p.recordedBy),
      );
    }).toList();
  }

  static Future<List<SentMessage>> _sentMessages(String? patientId) async {
    final repo = RepositoryRegistry.sentMessagesAsync;
    if (patientId != null && patientId.isNotEmpty) {
      return repo.getByPatientId(patientId);
    }
    return repo.getAll();
  }

  static Future<List<PatientTimelineEvent>> _fromSentMessages(
    String? patientId,
  ) async {
    final messages = await _sentMessages(patientId);
    return messages.map((m) {
      final template = m.templateTitle.trim();
      final channel = m.channel.trim();
      final description = [
        if (channel.isNotEmpty) channel else 'Belirtilmedi',
        sendStatusLabel(m.status),
      ].join(' • ');

      return PatientTimelineEvent(
        id: 'msg-${m.id}',
        patientId: m.patientId,
        patientName: m.patientName,
        eventDate: m.sentAt,
        eventType: TimelineEventType.mesaj,
        title: template.isEmpty ? 'Mesaj gönderildi' : _truncate(template, 60),
        description: description,
        relatedModule: 'Mesaj',
        relatedRecordId: m.id,
        relatedRoute: '/messages/sent/${m.id}',
        createdBy: _displayCreator(m.sentBy),
      );
    }).toList();
  }

  static List<PdfOutput> _pdfOutputs(String? patientId) {
    final repo = PdfOutputRepository.instance;
    if (patientId != null && patientId.isNotEmpty) {
      return repo.getByPatientId(patientId);
    }
    return repo.getAll();
  }

  static List<PatientTimelineEvent> _fromPdfOutputs(String? patientId) {
    return _pdfOutputs(patientId).map((p) {
      final docTitle = p.title.trim();
      final description = [
        documentTypeLabel(p.documentType),
        pdfStatusLabel(p.status),
      ].join(' • ');

      return PatientTimelineEvent(
        id: 'pdf-${p.id}',
        patientId: p.patientId,
        patientName: p.patientName,
        eventDate: p.createdAt,
        eventType: TimelineEventType.pdfCikti,
        title: docTitle.isEmpty ? 'PDF çıktı oluşturuldu' : docTitle,
        description: description,
        relatedModule: 'PDF Çıktı',
        relatedRecordId: p.id,
        relatedRoute: '/pdf-outputs/${p.id}',
        createdBy: _displayCreator(p.createdBy),
      );
    }).toList();
  }

  static Future<List<AuditLog>> _auditLogs(String? patientId) async {
    final repo = RepositoryRegistry.auditLogsAsync;
    if (patientId != null && patientId.isNotEmpty) {
      return repo.getByPatientId(patientId);
    }
    return repo.getAll();
  }

  static Future<List<PatientTimelineEvent>> _fromAuditLogs(
    String? patientId,
  ) async {
    final logs = await _auditLogs(patientId);
    return logs.map((a) {
      final pid = a.patientId ?? '';
      final pname = a.patientName?.trim() ?? '';
      final role = a.userRole.trim();
      final actor = role.isEmpty
          ? a.userName.trim()
          : '${a.userName.trim()} ($role)';
      final description = [
        moduleTypeLabel(a.module),
        actionTypeLabel(a.actionType),
        if (actor.isNotEmpty) _truncate(actor, 40),
      ].join(' • ');

      return PatientTimelineEvent(
        id: 'audit-${a.id}',
        patientId: pid,
        patientName: pname.isEmpty ? 'Hasta' : pname,
        eventDate: a.createdAt,
        eventType: TimelineEventType.auditLog,
        title: actionTypeLabel(a.actionType),
        description: _truncate(description, 120),
        relatedModule: 'İşlem Kaydı',
        relatedRecordId: a.id,
        relatedRoute: '/audit-logs/${a.id}',
        createdBy: _displayCreator(actor),
      );
    }).toList();
  }

  static String _displayCreator(String name) {
    final t = name.trim();
    return t.isEmpty ? 'Belirtilmedi' : t;
  }

  static String _truncate(String text, int maxLen) {
    final t = text.trim();
    if (t.length <= maxLen) return t;
    return '${t.substring(0, maxLen)}…';
  }
}
