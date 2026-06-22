import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/physiotherapy/data/patient_rehab_referral_summary_display.dart';
import 'package:v2mem_clinic/features/physiotherapy/models/physiotherapy_referral.dart';

void main() {
  test('latest referral picks most recent referredAt', () {
    final older = PhysiotherapyReferral(
      id: '1',
      patientId: 'p1',
      patientName: 'A',
      referredAt: DateTime(2026, 1, 1),
      referredBy: 'Dr',
      physiotherapistName: 'Atanacak',
      diagnosisSummary: 'Tanı 1',
      treatmentGoal: 'Hedef',
      precautions: '',
      allowedActivities: '',
      restrictedActivities: '',
    );
    final newer = PhysiotherapyReferral(
      id: '2',
      patientId: 'p1',
      patientName: 'A',
      referredAt: DateTime(2026, 6, 1),
      referredBy: 'Dr',
      physiotherapistName: 'Atanacak',
      diagnosisSummary: 'Tanı 2',
      treatmentGoal: 'Hedef',
      precautions: '',
      allowedActivities: '',
      restrictedActivities: '',
      doctorSummary: 'Doktor özeti',
      notes: 'Güvenli not',
    );

    final latest = PatientRehabReferralSummaryDisplay.latest([older, newer]);
    expect(latest?.id, '2');
    expect(latest?.doctorSummary, 'Doktor özeti');
    expect(latest?.notes, 'Güvenli not');
  });
}
