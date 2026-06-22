import '../models/surgery_procedure_note.dart';
import 'async_surgery_procedure_note_repository_contract.dart';
import 'surgery_note_ownership.dart';
import 'surgery_procedure_note_repository_failure.dart';
import 'surgery_repository.dart';

class MockAsyncSurgeryProcedureNoteRepositoryAdapter
    implements AsyncSurgeryProcedureNoteRepositoryContract {
  SurgeryRepository get _sync => SurgeryRepository.instance;

  @override
  Future<SurgeryProcedureNote> create(SurgeryProcedureNote note) async {
    final owned = SurgeryProcedureNote(
      id: note.id,
      patientId: note.patientId,
      patientName: note.patientName,
      procedureDate: note.procedureDate,
      procedureType: note.procedureType,
      bodyRegion: note.bodyRegion,
      side: note.side,
      diagnosis: note.diagnosis,
      procedureName: note.procedureName,
      anesthesiaType: note.anesthesiaType,
      asaScore: note.asaScore,
      tourniquetUsed: note.tourniquetUsed,
      implantOrMaterialInfo: note.implantOrMaterialInfo,
      arthroscopyFindings: note.arthroscopyFindings,
      procedureDetails: note.procedureDetails,
      complications: note.complications,
      postOpRecommendations: note.postOpRecommendations,
      physiotherapyStartRecommendation: note.physiotherapyStartRecommendation,
      controlSchedule: note.controlSchedule,
      surgeonName: SurgeryNoteOwnership.currentSurgeonDisplayName(),
      assistantInfo: note.assistantInfo,
      notes: note.notes,
      createdByProfileId: SurgeryNoteOwnership.currentProfileId(),
    );
    _sync.add(owned);
    return owned;
  }

  @override
  Future<List<SurgeryProcedureNote>> getAll() async => _sync.getAll();

  @override
  Future<SurgeryProcedureNote?> getById(String id) async => _sync.getById(id);

  @override
  Future<List<SurgeryProcedureNote>> getByPatientId(String patientId) async =>
      _sync.getByPatientId(patientId);

  @override
  Future<List<SurgeryProcedureNote>> search(String query) async =>
      _sync.search(query);

  @override
  Future<SurgeryProcedureNote> update(SurgeryProcedureNote note) async {
    final existing = _sync.getById(note.id);
    if (existing == null) {
      throw const SurgeryProcedureNoteRepositoryException(
        SurgeryProcedureNoteRepositoryFailure.notFound,
      );
    }
    if (!SurgeryNoteOwnership.canEditNote(existing)) {
      throw const SurgeryProcedureNoteRepositoryException(
        SurgeryProcedureNoteRepositoryFailure.forbidden,
      );
    }

    final updated = SurgeryProcedureNote(
      id: existing.id,
      patientId: existing.patientId,
      patientName: existing.patientName,
      procedureDate: note.procedureDate,
      procedureType: note.procedureType,
      bodyRegion: note.bodyRegion,
      side: note.side,
      diagnosis: note.diagnosis,
      procedureName: note.procedureName,
      anesthesiaType: note.anesthesiaType,
      asaScore: note.asaScore,
      tourniquetUsed: note.tourniquetUsed,
      implantOrMaterialInfo: note.implantOrMaterialInfo,
      arthroscopyFindings: note.arthroscopyFindings,
      procedureDetails: note.procedureDetails,
      complications: note.complications,
      postOpRecommendations: note.postOpRecommendations,
      physiotherapyStartRecommendation: note.physiotherapyStartRecommendation,
      controlSchedule: note.controlSchedule,
      surgeonName: existing.surgeonName,
      assistantInfo: note.assistantInfo,
      notes: note.notes,
      createdByProfileId: existing.createdByProfileId,
    );
    _sync.update(updated);
    return updated;
  }

  @override
  Future<SurgeryProcedureNote> updateNotes(String id, String notes) async {
    final existing = _sync.getById(id);
    if (existing == null) {
      throw StateError('Surgery note not found: $id');
    }
    final updated = SurgeryProcedureNote(
      id: existing.id,
      patientId: existing.patientId,
      patientName: existing.patientName,
      procedureDate: existing.procedureDate,
      procedureType: existing.procedureType,
      bodyRegion: existing.bodyRegion,
      side: existing.side,
      diagnosis: existing.diagnosis,
      procedureName: existing.procedureName,
      anesthesiaType: existing.anesthesiaType,
      asaScore: existing.asaScore,
      tourniquetUsed: existing.tourniquetUsed,
      implantOrMaterialInfo: existing.implantOrMaterialInfo,
      arthroscopyFindings: existing.arthroscopyFindings,
      procedureDetails: existing.procedureDetails,
      complications: existing.complications,
      postOpRecommendations: existing.postOpRecommendations,
      physiotherapyStartRecommendation: existing.physiotherapyStartRecommendation,
      controlSchedule: existing.controlSchedule,
      surgeonName: existing.surgeonName,
      assistantInfo: existing.assistantInfo,
      notes: notes,
      createdByProfileId: existing.createdByProfileId,
    );
    _sync.update(updated);
    return updated;
  }
}
