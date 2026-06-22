import '../models/surgery_note_template.dart';
import '../models/surgery_procedure_note.dart';

typedef SurgeryNoteTemplateFormBindings = ({
  void Function(ProcedureType? value) setProcedureType,
  void Function(SurgeryBodyRegion? value) setBodyRegion,
  void Function(SurgerySide? value) setSide,
  void Function(String? value) setAsaScore,
  void Function(bool? value) setTourniquetUsed,
  void Function(String value) setDiagnosis,
  void Function(String value) setProcedureName,
  void Function(String value) setAnesthesiaType,
  void Function(String value) setProcedureDetails,
  void Function(String value) setComplications,
  void Function(String value) setAssistantInfo,
  void Function(List<String> lines) setImplantLines,
  void Function(String value) setPostOpRecommendations,
  void Function(String value) setPhysiotherapyStart,
  void Function(String value) setControlSchedule,
  void Function(String value) setNotes,
});

abstract final class SurgeryNoteTemplateApply {
  static void applyContent(
    SurgeryNoteTemplateContent content,
    SurgeryNoteTemplateFormBindings bindings,
  ) {
    bindings.setProcedureType(content.procedureType);
    bindings.setBodyRegion(content.bodyRegion);
    bindings.setSide(content.side);
    bindings.setAsaScore(content.asaScore);
    bindings.setTourniquetUsed(content.tourniquetUsed);
    bindings.setDiagnosis(content.diagnosis);
    bindings.setProcedureName(content.procedureName);
    bindings.setAnesthesiaType(content.anesthesiaType);
    bindings.setProcedureDetails(content.procedureDetails);
    bindings.setComplications(content.complications);
    bindings.setAssistantInfo(content.assistantInfo);
    bindings.setImplantLines(content.implantLines);
    bindings.setPostOpRecommendations(content.postOpRecommendations);
    bindings.setPhysiotherapyStart(content.physiotherapyStartRecommendation);
    bindings.setControlSchedule(content.controlSchedule);
    bindings.setNotes(content.notes);
  }

  static SurgeryNoteTemplateContent captureContent({
    ProcedureType? procedureType,
    SurgeryBodyRegion? bodyRegion,
    SurgerySide? side,
    String? asaScore,
    bool? tourniquetUsed,
    required String diagnosis,
    required String procedureName,
    required String anesthesiaType,
    required String procedureDetails,
    required String complications,
    required String assistantInfo,
    required List<String> implantLines,
    required String postOpRecommendations,
    required String physiotherapyStart,
    required String controlSchedule,
    required String notes,
  }) {
    return SurgeryNoteTemplateContent(
      procedureType: procedureType,
      bodyRegion: bodyRegion,
      side: side,
      asaScore: asaScore,
      tourniquetUsed: tourniquetUsed,
      diagnosis: diagnosis.trim(),
      procedureName: procedureName.trim(),
      anesthesiaType: anesthesiaType.trim(),
      procedureDetails: procedureDetails.trim(),
      complications: complications.trim(),
      assistantInfo: assistantInfo.trim(),
      implantLines: implantLines,
      postOpRecommendations: postOpRecommendations.trim(),
      physiotherapyStartRecommendation: physiotherapyStart.trim(),
      controlSchedule: controlSchedule.trim(),
      notes: notes.trim(),
    );
  }
}
