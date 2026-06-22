import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/physiotherapy/data/patient_rehab_last_session_display.dart';
import 'package:v2mem_clinic/features/physiotherapy/models/physiotherapy_session_note.dart';

PhysiotherapySessionNote _session({
  required String id,
  required DateTime sessionDate,
  int painScore = 3,
  bool doctorNotificationNeeded = false,
  String warningSigns = '',
  String homeProgramCompliance = 'Bilinmiyor',
}) {
  return PhysiotherapySessionNote(
    id: id,
    patientId: 'p1',
    patientName: 'Hasta',
    sessionDate: sessionDate,
    physiotherapistName: 'Fizyoterapist',
    painScore: painScore,
    rangeOfMotionSummary: 'ROM tam dump olmamalı',
    strengthSummary: 'Kuvvet tam dump olmamalı',
    functionalAssessment: 'Fonksiyonel tam dump olmamalı',
    exercisesPerformed: 'Egzersiz tam dump olmamalı',
    homeProgramCompliance: homeProgramCompliance,
    warningSigns: warningSigns,
    returnToSportStage: ReturnToSportStage.kuvvetlendirme,
    doctorNotificationNeeded: doctorNotificationNeeded,
    notes: 'Tam seans notu görünmemeli',
    referralId: 'ref-1',
  );
}

void main() {
  test('latestSessionFromSorted picks newest sessionDate', () {
    final picked = PatientRehabLastSessionDisplay.latestSessionFromSorted([
      _session(id: 'old', sessionDate: DateTime(2026, 5, 1)),
      _session(id: 'new', sessionDate: DateTime(2026, 6, 15)),
      _session(id: 'mid', sessionDate: DateTime(2026, 6, 1)),
    ]);

    expect(picked?.id, 'new');
  });

  test('latestSessionFromSorted sorts unsorted mock list', () {
    final picked = PatientRehabLastSessionDisplay.latestSessionFromSorted([
      _session(id: 'a', sessionDate: DateTime(2026, 1, 1)),
      _session(id: 'b', sessionDate: DateTime(2026, 12, 1)),
    ]);
    expect(picked?.id, 'b');
  });

  test('empty list returns null', () {
    expect(
      PatientRehabLastSessionDisplay.latestSessionFromSorted(const []),
      isNull,
    );
  });

  test('summaryRows includes core fields and doctor notification', () {
    final rows = PatientRehabLastSessionDisplay.summaryRows(
      _session(
        id: 's1',
        sessionDate: DateTime(2026, 6, 10),
        painScore: 7,
        doctorNotificationNeeded: true,
      ),
    );

    final labels = rows.map((r) => r.label).toList();
    final values = rows.map((r) => r.value).join(' | ');

    expect(labels, contains('Son seans tarihi'));
    expect(values, contains('VAS: 7/10'));
    expect(values, contains('Kuvvetlendirme'));
    expect(values, contains('Doktor değerlendirmesi gerekli'));
    expect(values, isNot(contains('Tam seans notu')));
    expect(values, isNot(contains('ROM tam dump')));
    expect(values, isNot(contains('Egzersiz tam dump')));
  });

  test('summaryRows prefers warning over compliance optional row', () {
    final rows = PatientRehabLastSessionDisplay.summaryRows(
      _session(
        id: 's1',
        sessionDate: DateTime(2026, 6, 10),
        warningSigns: 'Şişlik artışı',
        homeProgramCompliance: 'İyi uyum',
      ),
    );

    expect(rows.any((r) => r.label == 'Uyarı bulgusu'), isTrue);
    expect(rows.any((r) => r.label == 'Ev programı uyumu'), isFalse);
  });
}
