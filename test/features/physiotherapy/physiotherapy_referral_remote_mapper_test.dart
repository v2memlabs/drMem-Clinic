import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/physiotherapy/data/physiotherapy_referral_remote_mapper.dart';
import 'package:v2mem_clinic/features/physiotherapy/models/physiotherapy_referral.dart';

void main() {
  test('remote row maps to PhysiotherapyReferral', () {
    final referral = PhysiotherapyReferralRemoteMapper.fromRow({
      'id': 'ref-1',
      'tenant_id': 'tenant-1',
      'patient_id': 'p1',
      'clinical_encounter_id': 'ce-1',
      'appointment_id': null,
      'referred_by_profile_id': 'prof-1',
      'assigned_physiotherapist_profile_id': null,
      'reason': 'Menisküs dejenerasyonu',
      'status': 'yeni',
      'treatment_goal': 'Kuvvet kazanımı',
      'precautions': 'Ağrıda dur',
      'allowed_activities': 'Yürüyüş',
      'restricted_activities': 'Zıplama',
      'target_return_date': '2026-12-01',
      'planned_start_date': '2026-06-15',
      'notes_safe': 'İlk değerlendirme planlandı',
      'doctor_summary': 'Doktor özeti',
      'created_at': '2026-05-01T10:00:00Z',
      'patients': {'first_name': 'Ayşe', 'last_name': 'Yılmaz'},
      'referred_by': {'display_name': 'Dr. Enes'},
      'assigned_physiotherapist': null,
    });

    expect(referral.id, 'ref-1');
    expect(referral.patientName, 'Ayşe Yılmaz');
    expect(referral.diagnosisSummary, 'Menisküs dejenerasyonu');
    expect(referral.status, ReferralStatus.yeni);
    expect(referral.referredBy, 'Dr. Enes');
    expect(referral.physiotherapistName, 'Atanacak');
    expect(referral.notes, 'İlk değerlendirme planlandı');
    expect(referral.doctorSummary, 'Doktor özeti');
    expect(referral.plannedStartDate, isNotNull);
    expect(referral.clinicalEncounterId, 'ce-1');
  });

  test('nullable fields parse safely', () {
    final referral = PhysiotherapyReferralRemoteMapper.fromRow({
      'id': 'ref-2',
      'tenant_id': 'tenant-1',
      'patient_id': 'p2',
      'clinical_encounter_id': null,
      'reason': 'Tanı',
      'status': 'devam',
      'created_at': '2026-05-01T10:00:00Z',
      'patients': {'first_name': 'Mehmet', 'last_name': 'Öztürk'},
    });

    expect(referral.clinicalEncounterId, isNull);
    expect(referral.notes, '');
    expect(referral.doctorSummary, '');
    expect(referral.plannedStartDate, isNull);
    expect(referral.referredBy, 'Yönlendiren hekim');
  });

  test('insert row excludes client-generated id', () {
    final referral = PhysiotherapyReferral(
      id: 'mock-id',
      patientId: 'p1',
      patientName: 'Ayşe Yılmaz',
      referredAt: DateTime.utc(2026, 5, 1),
      referredBy: 'Dr. Enes',
      physiotherapistName: 'Atanacak',
      diagnosisSummary: 'Tanı',
      treatmentGoal: 'Hedef',
      precautions: '',
      allowedActivities: '',
      restrictedActivities: '',
      status: ReferralStatus.yeni,
      doctorSummary: 'Özet',
      clinicalEncounterId: 'ce-1',
    );

    final row = PhysiotherapyReferralRemoteMapper.toInsertRow(
      tenantId: 'tenant-1',
      referral: referral,
      referredByProfileId: 'prof-1',
    );

    expect(row.containsKey('id'), isFalse);
    expect(row['reason'], 'Tanı');
    expect(row['doctor_summary'], 'Özet');
    expect(row['notes_safe'], isNull);
    expect(row['clinical_encounter_id'], 'ce-1');
  });
}
