import '../../clinical_encounter/data/clinical_encounter_lookup_data_source.dart';
import '../../consents/data/consent_template_repository.dart';
import '../../consents/data/consent_template_repository_provider.dart';
import '../../exercises/data/exercise_plan_lookup_data_source.dart';
import '../../imaging/data/imaging_lookup_data_source.dart';
import '../../imaging/data/imaging_repository.dart';
import '../../physiotherapy/data/physiotherapy_referral_lookup_data_source.dart';
import '../../post_op_protocols/data/post_op_protocol_lookup_data_source.dart';
import '../../surgery/data/surgery_procedure_note_lookup_data_source.dart';
import '../models/pdf_output.dart';

/// PDF detay — kaynak kayıt etiketi (async lookup).
abstract final class PdfOutputSourceRecordLookupDataSource {
  static Future<String?> resolveDisplayLabel({
    required String sourceModule,
    required String? sourceRecordId,
  }) async {
    final id = sourceRecordId?.trim() ?? '';
    if (id.isEmpty) return null;

    switch (sourceModule) {
      case pdfSourceModuleClinicalEncounter:
        return _clinicalEncounterLabel(id);
      case pdfSourceModulePostOpProtocol:
        return _postOpProtocolLabel(id);
      case pdfSourceModuleExercisePlan:
        return _exercisePlanLabel(id);
      case pdfSourceModuleSurgeryNote:
        return _surgeryNoteLabel(id);
      case pdfSourceModuleImagingNote:
        return _imagingNoteLabel(id);
      case pdfSourceModulePhysiotherapyReferral:
        return _physiotherapyReferralLabel(id);
      case pdfSourceModuleConsentTemplate:
        return _consentTemplateLabel(id);
    }

    return null;
  }

  static Future<String?> _clinicalEncounterLabel(String id) async {
    final encounter = await ClinicalEncounterLookupDataSource.findById(id);
    if (encounter == null) return null;
    return 'Muayene — ${encounter.patientName} • '
        '${_formatDate(encounter.createdAt)}';
  }

  static Future<String?> _postOpProtocolLabel(String id) async {
    final protocol = await PostOpProtocolLookupDataSource.findById(id);
    if (protocol == null) return null;
    return 'Post-op — ${protocol.protocolTitle}';
  }

  static Future<String?> _exercisePlanLabel(String id) async {
    final plan = await ExercisePlanLookupDataSource.findById(id);
    if (plan == null) return null;
    return 'Egzersiz — ${plan.title}';
  }

  static Future<String?> _surgeryNoteLabel(String id) async {
    final note = await SurgeryProcedureNoteLookupDataSource.findById(id);
    if (note == null) return null;
    return 'Ameliyat — ${note.procedureName} • '
        '${_formatDate(note.procedureDate)}';
  }

  static Future<String?> _physiotherapyReferralLabel(String id) async {
    final result = await PhysiotherapyReferralLookupDataSource.getById(id);
    final referral = result.referral;
    if (referral == null) return null;
    return 'FTR — ${referral.patientName} • ${_formatDate(referral.referredAt)}';
  }

  static Future<String?> _imagingNoteLabel(String id) async {
    final imaging = await ImagingLookupDataSource.findById(id);
    if (imaging == null) return null;
    return 'Görüntüleme — ${ImagingRepository.typeLabel(imaging.imagingType)} • '
        '${_formatDate(imaging.imagingDate)}';
  }

  static Future<String?> _consentTemplateLabel(String id) async {
    if (ConsentTemplateRepositoryProvider.usesRemoteConsentTemplates) {
      try {
        final template =
            await ConsentTemplateRepositoryProvider.asyncRepository.getById(id);
        if (template == null) return null;
        return 'Onam — ${template.title}';
      } catch (_) {
        return null;
      }
    }

    final template = ConsentTemplateRepository.instance.getById(id);
    if (template == null) return null;
    return 'Onam — ${template.title}';
  }

  static String _formatDate(DateTime date) {
    final local = date.toLocal();
    final d = local.day.toString().padLeft(2, '0');
    final m = local.month.toString().padLeft(2, '0');
    final y = local.year.toString();
    return '$d.$m.$y';
  }
}
