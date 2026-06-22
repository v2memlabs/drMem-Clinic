import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/physiotherapy/data/async_physiotherapy_session_repository_contract.dart';
import 'package:v2mem_clinic/features/physiotherapy/data/physiotherapy_session_repository_provider.dart';
import 'package:v2mem_clinic/features/physiotherapy/models/physiotherapy_session_note.dart';

PhysiotherapySessionNote _session({
  required String id,
  String referralId = 'ref-1',
  String patientId = 'p1',
  DateTime? sessionDate,
}) {
  return PhysiotherapySessionNote(
    id: id,
    patientId: patientId,
    patientName: 'Test Hasta',
    sessionDate: sessionDate ?? DateTime(2026, 6, 10),
    physiotherapistName: 'Fizyoterapist',
    painScore: 2,
    rangeOfMotionSummary: 'ROM',
    strengthSummary: 'Kuvvet',
    functionalAssessment: 'Fonksiyonel',
    exercisesPerformed: 'Egzersiz',
    homeProgramCompliance: 'İyi',
    warningSigns: '-',
    returnToSportStage: ReturnToSportStage.agri_kontrolu,
    referralId: referralId,
  );
}

class _FakeSessionRepo implements AsyncPhysiotherapySessionRepositoryContract {
  _FakeSessionRepo(this._items);

  final List<PhysiotherapySessionNote> _items;

  @override
  Future<List<PhysiotherapySessionNote>> getAll() async =>
      List.unmodifiable(_items);

  @override
  Future<List<PhysiotherapySessionNote>> getByPatientId(String patientId) async =>
      _items.where((s) => s.patientId == patientId).toList();

  @override
  Future<List<PhysiotherapySessionNote>> getByReferralId(
    String referralId,
  ) async {
    final list = _items.where((s) => s.referralId == referralId).toList()
      ..sort((a, b) => b.sessionDate.compareTo(a.sessionDate));
    return list;
  }

  @override
  Future<PhysiotherapySessionNote?> getById(String id) async {
    for (final s in _items) {
      if (s.id == id) return s;
    }
    return null;
  }

  @override
  Future<PhysiotherapySessionNote> add(PhysiotherapySessionNote session) async {
    final saved = session.copyWith(id: 'remote-uuid-sess-1');
    _items.insert(0, saved);
    return saved;
  }
}

extension on PhysiotherapySessionNote {
  PhysiotherapySessionNote copyWith({String? id}) {
    return PhysiotherapySessionNote(
      id: id ?? this.id,
      patientId: patientId,
      patientName: patientName,
      sessionDate: sessionDate,
      physiotherapistName: physiotherapistName,
      painScore: painScore,
      rangeOfMotionSummary: rangeOfMotionSummary,
      strengthSummary: strengthSummary,
      functionalAssessment: functionalAssessment,
      exercisesPerformed: exercisesPerformed,
      homeProgramCompliance: homeProgramCompliance,
      warningSigns: warningSigns,
      returnToSportStage: returnToSportStage,
      doctorNotificationNeeded: doctorNotificationNeeded,
      notes: notes,
      referralId: referralId,
    );
  }
}

void main() {
  tearDown(() {
    PhysiotherapySessionRepositoryProvider.clearTestOverrides();
    PhysiotherapySessionRepositoryProvider.resetCache();
  });

  test('getByReferralId orders by session_date desc', () async {
    final repo = _FakeSessionRepo([
      _session(id: 's1', sessionDate: DateTime(2026, 6, 1)),
      _session(id: 's2', sessionDate: DateTime(2026, 6, 15)),
    ]);
    PhysiotherapySessionRepositoryProvider.testOverride = repo;

    final list = await repo.getByReferralId('ref-1');
    expect(list.first.id, 's2');
    expect(list.last.id, 's1');
  });

  test('add returns remote uuid', () async {
    final repo = _FakeSessionRepo([]);
    PhysiotherapySessionRepositoryProvider.testOverride = repo;

    final saved = await repo.add(_session(id: 'pending'));
    expect(saved.id, 'remote-uuid-sess-1');
  });
}
