import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/features/physiotherapy/data/async_physiotherapy_session_repository_contract.dart';
import 'package:v2mem_clinic/features/physiotherapy/data/physiotherapy_session_list_data_source.dart';
import 'package:v2mem_clinic/features/physiotherapy/data/physiotherapy_session_repository_provider.dart';
import 'package:v2mem_clinic/features/physiotherapy/models/physiotherapy_session_note.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';

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
  Future<List<PhysiotherapySessionNote>> getByReferralId(String referralId) async =>
      [];

  @override
  Future<PhysiotherapySessionNote?> getById(String id) async => null;

  @override
  Future<PhysiotherapySessionNote> add(PhysiotherapySessionNote session) async =>
      session;
}

PhysiotherapySessionNote _note({
  required String id,
  required String patientId,
  ReturnToSportStage stage = ReturnToSportStage.agri_kontrolu,
  bool doctorNotification = false,
}) {
  return PhysiotherapySessionNote(
    id: id,
    patientId: patientId,
    patientName: 'Hasta',
    sessionDate: DateTime(2026, 6, 1),
    physiotherapistName: 'Fizyoterapist',
    painScore: 3,
    rangeOfMotionSummary: '',
    strengthSummary: '',
    functionalAssessment: '',
    exercisesPerformed: '',
    homeProgramCompliance: 'İyi',
    warningSigns: '',
    returnToSportStage: stage,
    doctorNotificationNeeded: doctorNotification,
    referralId: 'ref-1',
  );
}

void main() {
  tearDown(() {
    AuthSession.clear();
    PhysiotherapySessionRepositoryProvider.clearTestOverrides();
    PhysiotherapySessionRepositoryProvider.resetCache();
  });

  test('load filters by patient and stage', () async {
    AuthSession.setUser(
      AppUser(
        id: 'p1',
        username: 'physio',
        displayName: 'Physio',
        role: AppRoles.physiotherapist,
      ),
    );

    PhysiotherapySessionRepositoryProvider.testOverride = _FakeSessionRepo([
      _note(id: 's1', patientId: 'p1'),
      _note(
        id: 's2',
        patientId: 'p2',
        stage: ReturnToSportStage.kuvvetlendirme,
      ),
    ]);

    final result = await PhysiotherapySessionListDataSource.load(
      patientId: 'p1',
      query: '',
      returnToSportStageEnumFilter: ReturnToSportStage.agri_kontrolu,
    );

    expect(result.hasError, isFalse);
    expect(result.items, hasLength(1));
    expect(result.items!.first.id, 's1');
  });

  test('load filters doctor notification', () async {
    AuthSession.setUser(
      AppUser(
        id: 'p1',
        username: 'physio',
        displayName: 'Physio',
        role: AppRoles.physiotherapist,
      ),
    );

    PhysiotherapySessionRepositoryProvider.testOverride = _FakeSessionRepo([
      _note(id: 's1', patientId: 'p1', doctorNotification: true),
      _note(id: 's2', patientId: 'p1'),
    ]);

    final result = await PhysiotherapySessionListDataSource.load(
      patientId: 'p1',
      query: '',
      doctorNotificationNeeded: true,
    );

    expect(result.items, hasLength(1));
    expect(result.items!.first.doctorNotificationNeeded, isTrue);
  });
}
