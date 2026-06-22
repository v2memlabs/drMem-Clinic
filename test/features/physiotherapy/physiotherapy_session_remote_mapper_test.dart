import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/physiotherapy/data/physiotherapy_session_remote_mapper.dart';
import 'package:v2mem_clinic/features/physiotherapy/models/physiotherapy_session_note.dart';

void main() {
  test('remote row maps to PhysiotherapySessionNote', () {
    final session = PhysiotherapySessionRemoteMapper.fromRow({
      'id': 'sess-1',
      'tenant_id': 'tenant-1',
      'referral_id': 'ref-1',
      'patient_id': 'p1',
      'physiotherapist_profile_id': 'prof-1',
      'session_date': '2026-05-20T10:00:00Z',
      'status': 'kayitli',
      'pain_score': 4,
      'range_of_motion': 'ROM iyi',
      'strength': 'Orta',
      'functional_status': 'İyi',
      'exercises_performed': 'Quad set',
      'adherence': 'İyi',
      'warning_signs': 'Şişlik',
      'return_to_sport_stage': 'agri_kontrolu',
      'doctor_notification_needed': true,
      'notes': 'Seans notu',
      'patients': {'first_name': 'Ayşe', 'last_name': 'Yılmaz'},
      'physiotherapist': {'display_name': 'Fizyoterapist A'},
    });

    expect(session.id, 'sess-1');
    expect(session.patientName, 'Ayşe Yılmaz');
    expect(session.referralId, 'ref-1');
    expect(session.painScore, 4);
    expect(session.returnToSportStage, ReturnToSportStage.agri_kontrolu);
    expect(session.doctorNotificationNeeded, isTrue);
    expect(session.physiotherapistName, 'Fizyoterapist A');
    expect(session.notes, 'Seans notu');
  });

  test('nullable fields parse safely', () {
    final session = PhysiotherapySessionRemoteMapper.fromRow({
      'id': 'sess-2',
      'tenant_id': 'tenant-1',
      'referral_id': 'ref-2',
      'patient_id': 'p2',
      'physiotherapist_profile_id': 'prof-2',
      'session_date': '2026-05-20T10:00:00Z',
      'status': 'kayitli',
      'pain_score': null,
      'return_to_sport_stage': null,
      'doctor_notification_needed': false,
      'patients': {'first_name': 'Mehmet', 'last_name': 'Öztürk'},
    });

    expect(session.painScore, 0);
    expect(session.returnToSportStage, ReturnToSportStage.uygun_degil);
    expect(session.notes, '');
    expect(session.physiotherapistName, 'Fizyoterapist');
  });

  test('insert row requires referral id', () {
    final session = PhysiotherapySessionNote(
      id: 'pending',
      patientId: 'p1',
      patientName: 'Ayşe',
      sessionDate: DateTime.utc(2026, 5, 20),
      physiotherapistName: 'Fizyoterapist',
      painScore: 3,
      rangeOfMotionSummary: '',
      strengthSummary: '',
      functionalAssessment: '',
      exercisesPerformed: '',
      homeProgramCompliance: 'İyi',
      warningSigns: '',
      returnToSportStage: ReturnToSportStage.uygun_degil,
    );

    expect(
      () => PhysiotherapySessionRemoteMapper.toInsertRow(
        tenantId: 'tenant-1',
        session: session,
        physiotherapistProfileId: 'prof-1',
      ),
      throwsA(isA<Exception>()),
    );
  });

  test('insert row excludes client-generated id', () {
    final session = PhysiotherapySessionNote(
      id: 'sess-pending',
      patientId: 'p1',
      patientName: 'Ayşe',
      sessionDate: DateTime.utc(2026, 5, 20),
      physiotherapistName: 'Fizyoterapist',
      painScore: 3,
      rangeOfMotionSummary: 'ROM',
      strengthSummary: 'Kuvvet',
      functionalAssessment: 'Fonksiyonel',
      exercisesPerformed: 'Egzersiz',
      homeProgramCompliance: 'İyi',
      warningSigns: 'Uyarı',
      returnToSportStage: ReturnToSportStage.kuvvetlendirme,
      referralId: 'ref-1',
    );

    final row = PhysiotherapySessionRemoteMapper.toInsertRow(
      tenantId: 'tenant-1',
      session: session,
      physiotherapistProfileId: 'prof-1',
    );

    expect(row.containsKey('id'), isFalse);
    expect(row['referral_id'], 'ref-1');
    expect(row['return_to_sport_stage'], 'kuvvetlendirme');
    expect(row['status'], 'kayitli');
  });
}
