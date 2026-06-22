import '../models/surgery_procedure_note.dart';
import 'mock_surgery_procedure_notes.dart';
import 'surgery_note_ownership.dart';

class SurgeryRepository {
  SurgeryRepository._();

  static final SurgeryRepository instance = SurgeryRepository._();

  List<SurgeryProcedureNote> getAll() => List.unmodifiable(
        mockSurgeryProcedureNotes.where(SurgeryNoteOwnership.isVisibleToCurrentUser),
      );

  SurgeryProcedureNote? getById(String id) {
    for (final note in mockSurgeryProcedureNotes) {
      if (note.id == id && SurgeryNoteOwnership.isVisibleToCurrentUser(note)) {
        return note;
      }
    }
    return null;
  }

  List<SurgeryProcedureNote> getByPatientId(String patientId) =>
      mockSurgeryProcedureNotes
          .where(
            (n) =>
                n.patientId == patientId &&
                SurgeryNoteOwnership.isVisibleToCurrentUser(n),
          )
          .toList();

  List<SurgeryProcedureNote> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return getAll();
    return mockSurgeryProcedureNotes
        .where(
          (n) =>
              SurgeryNoteOwnership.isVisibleToCurrentUser(n) &&
              matchesQuery(n, q),
        )
        .toList();
  }

  List<SurgeryProcedureNote> getFiltered({
    String? patientId,
    String? query,
    ProcedureType? procedureTypeFilter,
    SurgeryBodyRegion? bodyRegionFilter,
  }) {
    Iterable<SurgeryProcedureNote> list = mockSurgeryProcedureNotes;

    if (patientId != null && patientId.isNotEmpty) {
      list = list.where((n) => n.patientId == patientId);
    }
    if (procedureTypeFilter != null) {
      list = list.where((n) => n.procedureType == procedureTypeFilter);
    }
    if (bodyRegionFilter != null) {
      list = list.where((n) => n.bodyRegion == bodyRegionFilter);
    }

    final q = query?.trim().toLowerCase() ?? '';
    if (q.isNotEmpty) {
      list = list.where((n) => matchesQuery(n, q));
    }

    return List<SurgeryProcedureNote>.from(list);
  }

  void add(SurgeryProcedureNote note) => mockSurgeryProcedureNotes.insert(0, note);

  void update(SurgeryProcedureNote note) {
    final index = mockSurgeryProcedureNotes.indexWhere((n) => n.id == note.id);
    if (index < 0) return;
    mockSurgeryProcedureNotes[index] = note;
  }

  static bool matchesQuery(SurgeryProcedureNote n, String q) {
    if (n.patientName.toLowerCase().contains(q)) return true;
    if (n.procedureName.toLowerCase().contains(q)) return true;
    if (n.diagnosis.toLowerCase().contains(q)) return true;
    if (n.surgeonName.toLowerCase().contains(q)) return true;
    if (procedureTypeLabel(n.procedureType).toLowerCase().contains(q)) return true;
    if (n.procedureType.name.toLowerCase().contains(q)) return true;
    if (surgeryBodyRegionLabel(n.bodyRegion).toLowerCase().contains(q)) return true;
    if (n.bodyRegion.name.toLowerCase().contains(q)) return true;
    if (n.notes.toLowerCase().contains(q)) return true;
    return false;
  }
}
