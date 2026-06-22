import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/core/session/active_tenant_context_store.dart';
import 'package:v2mem_clinic/core/session/mock_profile_ids.dart';
import 'package:v2mem_clinic/features/surgery/data/mock_async_surgery_procedure_note_repository_adapter.dart';
import 'package:v2mem_clinic/features/surgery/data/surgery_note_form_data_source.dart';
import 'package:v2mem_clinic/features/surgery/data/surgery_note_ownership.dart';
import 'package:v2mem_clinic/features/surgery/data/surgery_procedure_note_repository_provider.dart';
import 'package:v2mem_clinic/features/surgery/models/surgery_procedure_note.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';

SurgeryProcedureNote _note({String? createdByProfileId, String? surgeonName}) {
  return SurgeryProcedureNote(
    id: 'sn-edit-1',
    patientId: 'p1',
    patientName: 'Test Hasta',
    procedureDate: DateTime(2026, 3, 12),
    procedureType: ProcedureType.ameliyat,
    bodyRegion: SurgeryBodyRegion.diz,
    side: SurgerySide.sag,
    diagnosis: 'Tanı',
    procedureName: 'İşlem',
    anesthesiaType: '',
    implantOrMaterialInfo: '',
    arthroscopyFindings: '',
    procedureDetails: 'Detay',
    complications: '',
    postOpRecommendations: '',
    physiotherapyStartRecommendation: '',
    controlSchedule: '',
    surgeonName: surgeonName ?? 'Op. Dr. Mehmet Yılmaz',
    assistantInfo: '',
    notes: 'ilk not',
    createdByProfileId: createdByProfileId,
  );
}

void main() {
  tearDown(() {
    AuthSession.clear();
    ActiveTenantContextStore.clearSilently();
    SurgeryProcedureNoteRepositoryProvider.testOverride = null;
    SurgeryProcedureNoteRepositoryProvider.resetCache();
  });

  setUp(() {
    SurgeryProcedureNoteRepositoryProvider.resetCache();
    SurgeryProcedureNoteRepositoryProvider.testOverride =
        MockAsyncSurgeryProcedureNoteRepositoryAdapter();
  });

  test('canEditNote allows only owning surgeon profile', () {
    AuthSession.setUser(
      AppUser(
        id: 'doc-1',
        username: 'doc1',
        displayName: 'Op. Dr. Mehmet Yılmaz',
        role: AppRoles.doctor,
      ),
    );

    final owned = _note(createdByProfileId: MockProfileIds.primaryDoctor);
    final other = _note(
      createdByProfileId: MockProfileIds.assistant,
      surgeonName: 'Op. Dr. Ali Veli',
    );

    expect(SurgeryNoteOwnership.canEditNote(owned), isTrue);
    expect(SurgeryNoteOwnership.canEditNote(other), isFalse);
  });

  test('update rejects notes owned by another surgeon', () async {
    AuthSession.setUser(
      AppUser(
        id: 'doc-1',
        username: 'doc1',
        displayName: 'Op. Dr. Mehmet Yılmaz',
        role: AppRoles.doctor,
      ),
    );

    final created = await SurgeryProcedureNoteRepositoryProvider.asyncRepository
        .create(_note());

    AuthSession.setUser(
      AppUser(
        id: 'assistant-1',
        username: 'asst1',
        displayName: 'Asistan Kullanıcı',
        role: AppRoles.assistant,
      ),
    );

    expect(
      () => SurgeryNoteFormDataSource.update(
        SurgeryProcedureNote(
          id: created.id,
          patientId: created.patientId,
          patientName: created.patientName,
          procedureDate: created.procedureDate,
          procedureType: created.procedureType,
          bodyRegion: created.bodyRegion,
          side: created.side,
          diagnosis: 'Başkasının notu',
          procedureName: created.procedureName,
          anesthesiaType: created.anesthesiaType,
          implantOrMaterialInfo: created.implantOrMaterialInfo,
          arthroscopyFindings: created.arthroscopyFindings,
          procedureDetails: created.procedureDetails,
          complications: created.complications,
          postOpRecommendations: created.postOpRecommendations,
          physiotherapyStartRecommendation:
              created.physiotherapyStartRecommendation,
          controlSchedule: created.controlSchedule,
          surgeonName: created.surgeonName,
          assistantInfo: created.assistantInfo,
          notes: created.notes,
          createdByProfileId: created.createdByProfileId,
        ),
      ),
      throwsA(
        isA<SurgeryNoteFormException>().having(
          (e) => e.message,
          'message',
          'Bu notu düzenleme yetkiniz yok.',
        ),
      ),
    );
  });

  test('update persists edited clinical fields for owning surgeon', () async {
    AuthSession.setUser(
      AppUser(
        id: 'doc-1',
        username: 'doc1',
        displayName: 'Op. Dr. Mehmet Yılmaz',
        role: AppRoles.doctor,
      ),
    );

    final created = await SurgeryProcedureNoteRepositoryProvider.asyncRepository
        .create(_note());

    final updated = await SurgeryNoteFormDataSource.update(
      SurgeryProcedureNote(
        id: created.id,
        patientId: created.patientId,
        patientName: created.patientName,
        procedureDate: created.procedureDate,
        procedureType: created.procedureType,
        bodyRegion: created.bodyRegion,
        side: created.side,
        diagnosis: 'Güncel tanı',
        procedureName: created.procedureName,
        anesthesiaType: created.anesthesiaType,
        implantOrMaterialInfo: created.implantOrMaterialInfo,
        arthroscopyFindings: created.arthroscopyFindings,
        procedureDetails: 'Güncellenmiş detay',
        complications: created.complications,
        postOpRecommendations: created.postOpRecommendations,
        physiotherapyStartRecommendation:
            created.physiotherapyStartRecommendation,
        controlSchedule: created.controlSchedule,
        surgeonName: created.surgeonName,
        assistantInfo: created.assistantInfo,
        notes: 'güncel not',
        createdByProfileId: created.createdByProfileId,
      ),
    );

    expect(updated.diagnosis, 'Güncel tanı');
    expect(updated.procedureDetails, 'Güncellenmiş detay');
    expect(updated.notes, 'güncel not');
  });
}
