import '../../core/data/repository_registry.dart';
import '../appointments/models/appointment.dart';
import '../clinical_encounter/models/clinical_encounter.dart';
import '../exercises/models/exercise_plan.dart';
import '../imaging/models/imaging_note.dart';
import '../post_op_protocols/models/post_op_protocol.dart';
import '../surgery/models/surgery_procedure_note.dart';

/// PDF form kaynak yükleme — async remote/mock parity (sync mock repo yok).
abstract final class PdfFormSourceLoader {
  static Future<ClinicalEncounter?> loadClinicalEncounter(String recordId) async {
    final id = recordId.trim();
    if (id.isEmpty) return null;
    return RepositoryRegistry.clinicalEncountersAsync.getById(id);
  }

  static Future<Appointment?> loadAppointment(String recordId) async {
    final id = recordId.trim();
    if (id.isEmpty) return null;
    return RepositoryRegistry.appointmentsAsync.getById(id);
  }

  static Future<PostOpProtocol?> loadPostOpProtocol(String recordId) async {
    final id = recordId.trim();
    if (id.isEmpty) return null;
    try {
      return await RepositoryRegistry.postOpProtocolsAsync.getById(id);
    } catch (_) {
      return null;
    }
  }

  static Future<ExercisePlan?> loadExercisePlan(String recordId) async {
    final id = recordId.trim();
    if (id.isEmpty) return null;
    try {
      return await RepositoryRegistry.exercisePlansAsync.getById(id);
    } catch (_) {
      return null;
    }
  }

  static Future<SurgeryProcedureNote?> loadSurgeryNote(String recordId) async {
    final id = recordId.trim();
    if (id.isEmpty) return null;
    try {
      return await RepositoryRegistry.surgeryProcedureNotesAsync.getById(id);
    } catch (_) {
      return null;
    }
  }

  static Future<ImagingNote?> loadImagingNote(String recordId) async {
    final id = recordId.trim();
    if (id.isEmpty) return null;
    try {
      return await RepositoryRegistry.imagingNotesAsync.getById(id);
    } catch (_) {
      return null;
    }
  }
}
