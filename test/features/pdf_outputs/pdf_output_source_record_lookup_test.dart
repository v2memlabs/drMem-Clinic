import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/core/data/backend_config.dart';
import 'package:v2mem_clinic/core/data/data_backend.dart';
import 'package:v2mem_clinic/features/exercises/data/exercise_plan_repository_provider.dart';
import 'package:v2mem_clinic/features/exercises/data/mock_async_exercise_plan_repository_adapter.dart';
import 'package:v2mem_clinic/features/exercises/models/exercise_item.dart';
import 'package:v2mem_clinic/features/exercises/models/exercise_plan.dart';
import 'package:v2mem_clinic/features/imaging/data/mock_async_imaging_repository_adapter.dart';
import 'package:v2mem_clinic/features/imaging/data/imaging_repository_provider.dart';
import 'package:v2mem_clinic/features/imaging/models/imaging_note.dart';
import 'package:v2mem_clinic/features/pdf_outputs/data/pdf_output_source_record_lookup_data_source.dart';
import 'package:v2mem_clinic/features/pdf_outputs/models/pdf_output.dart';
import 'package:v2mem_clinic/features/post_op_protocols/data/mock_async_post_op_protocol_repository_adapter.dart';
import 'package:v2mem_clinic/features/post_op_protocols/data/post_op_protocol_repository_provider.dart';
import 'package:v2mem_clinic/features/post_op_protocols/models/post_op_protocol.dart';
import 'package:v2mem_clinic/features/physiotherapy/data/async_physiotherapy_referral_repository_contract.dart';
import 'package:v2mem_clinic/features/physiotherapy/data/physiotherapy_referral_repository_provider.dart';
import 'package:v2mem_clinic/features/physiotherapy/models/physiotherapy_referral.dart';
import 'package:v2mem_clinic/features/surgery/data/mock_async_surgery_procedure_note_repository_adapter.dart';
import 'package:v2mem_clinic/features/surgery/data/surgery_procedure_note_repository_provider.dart';
import 'package:v2mem_clinic/features/surgery/models/surgery_procedure_note.dart';

const _remoteReferralId = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';

void main() {
  tearDown(() {
    AppBackendConfig.activeBackend = DataBackend.mock;
    ExercisePlanRepositoryProvider.clearTestOverrides();
    ExercisePlanRepositoryProvider.resetCache();
    PostOpProtocolRepositoryProvider.clearTestOverrides();
    PostOpProtocolRepositoryProvider.resetCache();
    SurgeryProcedureNoteRepositoryProvider.testOverride = null;
    SurgeryProcedureNoteRepositoryProvider.resetCache();
    ImagingRepositoryProvider.clearTestOverrides();
    ImagingRepositoryProvider.resetCache();
    PhysiotherapyReferralRepositoryProvider.clearTestOverrides();
    PhysiotherapyReferralRepositoryProvider.resetCache();
  });

  test('mock mode resolves surgery note source label', () async {
    AppBackendConfig.activeBackend = DataBackend.mock;

    final label =
        await PdfOutputSourceRecordLookupDataSource.resolveDisplayLabel(
      sourceModule: pdfSourceModuleSurgeryNote,
      sourceRecordId: 'sn1',
    );

    expect(label, 'Ameliyat — Diz artroskopisi • 12.11.2025');
  });

  test('supabase mode does not read mock-only source modules', () async {
    AppBackendConfig.activeBackend = DataBackend.supabase;

    expect(
      await PdfOutputSourceRecordLookupDataSource.resolveDisplayLabel(
        sourceModule: pdfSourceModulePostOpProtocol,
        sourceRecordId: 'post-op-1',
      ),
      isNull,
    );
    expect(
      await PdfOutputSourceRecordLookupDataSource.resolveDisplayLabel(
        sourceModule: pdfSourceModuleExercisePlan,
        sourceRecordId: 'plan-1',
      ),
      isNull,
    );
  });

  test(
    'supabase mode without remote gate does not read mock surgery singleton',
    () async {
      AppBackendConfig.activeBackend = DataBackend.supabase;

      expect(
        await PdfOutputSourceRecordLookupDataSource.resolveDisplayLabel(
          sourceModule: pdfSourceModuleSurgeryNote,
          sourceRecordId: 'sn1',
        ),
        isNull,
      );
    },
  );

  test('mock mode resolves FTR referral source label', () async {
    AppBackendConfig.activeBackend = DataBackend.mock;

    final label =
        await PdfOutputSourceRecordLookupDataSource.resolveDisplayLabel(
      sourceModule: pdfSourceModulePhysiotherapyReferral,
      sourceRecordId: 'ref-001',
    );

    expect(label, isNotNull);
    expect(label, startsWith('FTR — Ayşe Yılmaz • '));
  });

  test('supabase mode resolves FTR label via async repository', () async {
    AppBackendConfig.activeBackend = DataBackend.supabase;
    PhysiotherapyReferralRepositoryProvider.resetCache();
    PhysiotherapyReferralRepositoryProvider.testOverride = _FakeReferralRepo();

    final label =
        await PdfOutputSourceRecordLookupDataSource.resolveDisplayLabel(
      sourceModule: pdfSourceModulePhysiotherapyReferral,
      sourceRecordId: _remoteReferralId,
    );

    expect(label, 'FTR — Ayşe Yılmaz • 01.05.2026');
  });

  test('supabase mode returns null when FTR referral not found', () async {
    AppBackendConfig.activeBackend = DataBackend.supabase;
    PhysiotherapyReferralRepositoryProvider.resetCache();
    PhysiotherapyReferralRepositoryProvider.testOverride =
        _FakeReferralRepo(returnReferral: false);

    expect(
      await PdfOutputSourceRecordLookupDataSource.resolveDisplayLabel(
        sourceModule: pdfSourceModulePhysiotherapyReferral,
        sourceRecordId: _remoteReferralId,
      ),
      isNull,
    );
  });

  test('supabase mode resolves surgery label via async repository', () async {
    AppBackendConfig.activeBackend = DataBackend.supabase;
    SurgeryProcedureNoteRepositoryProvider.resetCache();
    SurgeryProcedureNoteRepositoryProvider.testOverride =
        _RemoteGateOpenSurgeryRepo();

    final label =
        await PdfOutputSourceRecordLookupDataSource.resolveDisplayLabel(
      sourceModule: pdfSourceModuleSurgeryNote,
      sourceRecordId: 'remote-sn-1',
    );

    expect(label, 'Ameliyat — Meniskektomi • 01.03.2026');
  });

  test('supabase mode resolves imaging label via async repository', () async {
    AppBackendConfig.activeBackend = DataBackend.supabase;
    ImagingRepositoryProvider.resetCache();
    ImagingRepositoryProvider.testOverride = _RemoteGateOpenImagingRepo();

    final label =
        await PdfOutputSourceRecordLookupDataSource.resolveDisplayLabel(
      sourceModule: pdfSourceModuleImagingNote,
      sourceRecordId: 'remote-img-1',
    );

    expect(label, 'Görüntüleme — MR • 02.04.2026');
  });

  test('supabase mode resolves exercise plan label via async repository',
      () async {
    AppBackendConfig.activeBackend = DataBackend.supabase;
    ExercisePlanRepositoryProvider.resetCache();
    ExercisePlanRepositoryProvider.testOverride = _RemoteGateOpenExerciseRepo();

    final label =
        await PdfOutputSourceRecordLookupDataSource.resolveDisplayLabel(
      sourceModule: pdfSourceModuleExercisePlan,
      sourceRecordId: 'remote-ex-1',
    );

    expect(label, 'Egzersiz — Ön Çapraz Bağ Rehabilitasyonu');
  });

  test('supabase mode resolves post-op protocol label via async repository',
      () async {
    AppBackendConfig.activeBackend = DataBackend.supabase;
    PostOpProtocolRepositoryProvider.resetCache();
    PostOpProtocolRepositoryProvider.testOverride = _RemoteGateOpenPostOpRepo();

    final label =
        await PdfOutputSourceRecordLookupDataSource.resolveDisplayLabel(
      sourceModule: pdfSourceModulePostOpProtocol,
      sourceRecordId: 'remote-pop-1',
    );

    expect(label, 'Post-op — Artroskopi Sonrası Takip');
  });

  test(
    'supabase mode without remote gate does not read mock imaging singleton',
    () async {
      AppBackendConfig.activeBackend = DataBackend.supabase;

      expect(
        await PdfOutputSourceRecordLookupDataSource.resolveDisplayLabel(
          sourceModule: pdfSourceModuleImagingNote,
          sourceRecordId: 'img-1',
        ),
        isNull,
      );
    },
  );
}

class _FakeReferralRepo
    implements AsyncPhysiotherapyReferralRepositoryContract {
  _FakeReferralRepo({this.returnReferral = true});

  final bool returnReferral;

  @override
  Future<PhysiotherapyReferral?> getById(String id) async {
    if (!returnReferral || id != _remoteReferralId) return null;
    return PhysiotherapyReferral(
      id: _remoteReferralId,
      patientId: 'p1',
      patientName: 'Ayşe Yılmaz',
      referredAt: DateTime(2026, 5, 1),
      referredBy: 'Dr. Enes',
      physiotherapistName: 'Fizyoterapist A',
      diagnosisSummary: 'Menisküs dejenerasyonu',
      treatmentGoal: 'Kuvvet',
      precautions: '',
      allowedActivities: '',
      restrictedActivities: '',
    );
  }

  @override
  Future<List<PhysiotherapyReferral>> getAll() async => [];

  @override
  Future<List<PhysiotherapyReferral>> getByPatientId(String patientId) async =>
      [];

  @override
  Future<List<PhysiotherapyReferral>> search(String query) async => [];

  @override
  Future<List<PhysiotherapyReferral>> getFiltered({
    String? patientId,
    String? query,
    ReferralStatus? statusEnumFilter,
    String? physiotherapistFilter,
  }) async =>
      [];

  @override
  Future<PhysiotherapyReferral> add(PhysiotherapyReferral referral) async =>
      referral;

  @override
  Future<PhysiotherapyReferral> updateSafeFields(
    String id,
    PhysiotherapyReferralSafeUpdate update,
  ) async =>
      (await getById(id))!;
}

/// Test-only async repo override for supabase-mode lookup.
class _RemoteGateOpenSurgeryRepo
    extends MockAsyncSurgeryProcedureNoteRepositoryAdapter {
  @override
  Future<SurgeryProcedureNote?> getById(String id) async {
    if (id != 'remote-sn-1') return null;
    return SurgeryProcedureNote(
      id: id,
      patientId: 'p1',
      patientName: 'Ayşe Yılmaz',
      procedureDate: DateTime(2026, 3, 1),
      procedureType: ProcedureType.artroskopi,
      bodyRegion: SurgeryBodyRegion.diz,
      side: SurgerySide.sag,
      diagnosis: 'Menisküs',
      procedureName: 'Meniskektomi',
      anesthesiaType: '',
      implantOrMaterialInfo: '',
      arthroscopyFindings: '',
      procedureDetails: '',
      complications: '',
      postOpRecommendations: '',
      physiotherapyStartRecommendation: '',
      controlSchedule: '',
      surgeonName: 'Dr. Test',
      assistantInfo: '',
    );
  }
}

/// Test-only async repo override for supabase-mode lookup.
class _RemoteGateOpenImagingRepo extends MockAsyncImagingRepositoryAdapter {
  @override
  Future<ImagingNote?> getById(String id) async {
    if (id != 'remote-img-1') return null;
    return ImagingNote(
      id: id,
      patientId: 'p1',
      patientName: 'Ayşe Yılmaz',
      createdAt: DateTime(2026, 4, 2),
      imagingType: ImagingType.mr,
      imagingDate: DateTime(2026, 4, 2),
      imagingCenter: 'Test Görüntüleme',
      bodyRegion: ImagingBodyRegion.diz,
      side: ImagingSide.sag,
      reportSummary: 'MR raporu',
      doctorComment: '',
      comparisonWithPrevious: '',
      relatedDiagnosis: '',
    );
  }
}

/// Test-only async repo override for supabase-mode lookup.
class _RemoteGateOpenExerciseRepo
    extends MockAsyncExercisePlanRepositoryAdapter {
  @override
  Future<ExercisePlan?> getById(String id) async {
    if (id != 'remote-ex-1') return null;
    return ExercisePlan(
      id: id,
      patientId: 'p1',
      patientName: 'Ayşe Yılmaz',
      title: 'Ön Çapraz Bağ Rehabilitasyonu',
      createdBy: 'Fizyoterapist A',
      createdAt: DateTime(2026, 4, 3),
      diagnosisSummary: 'ÖÇB rekonstrüksiyonu sonrası',
      phase: ExercisePlanPhase.erkenRehabilitasyon,
      goal: 'Eklem hareket açıklığını artırmak',
      exercises: [
        ExerciseItem(
          id: 'ex-1',
          name: 'Topuk kaydırma',
          description: 'Diz fleksiyon egzersizi',
        ),
      ],
      status: ExercisePlanStatus.aktif,
    );
  }
}

/// Test-only async repo override for supabase-mode lookup.
class _RemoteGateOpenPostOpRepo
    extends MockAsyncPostOpProtocolRepositoryAdapter {
  @override
  Future<PostOpProtocol?> getById(String id) async {
    if (id != 'remote-pop-1') return null;
    return PostOpProtocol(
      id: id,
      patientId: 'p1',
      patientName: 'Ayşe Yılmaz',
      createdAt: DateTime(2026, 4, 4),
      protocolTitle: 'Artroskopi Sonrası Takip',
      diagnosisOrProcedureSummary: 'Menisküs artroskopisi sonrası',
      phase: PostOpPhase.hafta0_2,
      weightBearingStatus: 'Tolere ettiği kadar',
      rangeOfMotionLimits: '0-90 derece',
      braceOrImmobilization: '',
      woundCareNotes: '',
      medicationOrPainControlNotes: '',
      physiotherapyInstructions: '',
      exerciseRestrictions: '',
      redFlags: '',
      returnToSportEstimate: '3 ay',
      createdBy: 'Dr. Test',
      status: PostOpProtocolStatus.aktif,
    );
  }
}
