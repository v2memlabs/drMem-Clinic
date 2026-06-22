import '../../features/appointments/data/appointment_list_refresh.dart';
import '../../features/clinical_encounter/data/assistant_clinical_summary_list_refresh.dart';
import '../../features/clinical_encounter/data/clinical_encounter_list_refresh.dart';
import '../../features/consents/data/consent_list_refresh.dart';
import '../../features/exercises/data/exercise_plan_list_refresh.dart';
import '../../features/imaging/data/imaging_list_refresh.dart';
import '../../features/inventory/data/inventory_list_refresh.dart';
import '../../features/physiotherapy/data/physiotherapy_referral_list_refresh.dart';
import '../../features/physiotherapy/data/physiotherapy_session_list_refresh.dart';
import '../../features/payments/data/payment_list_refresh.dart';
import '../../features/pdf_outputs/data/pdf_output_list_refresh.dart';
import '../../features/patients/data/patient_list_refresh.dart';
import '../../features/post_op_protocols/data/post_op_protocol_list_refresh.dart';
import '../../features/surgery/data/surgery_note_list_refresh.dart';

/// Liste ekranları — oturum/tenant değişiminde stale işaretleme.
abstract final class RemoteListRefreshCoordinator {
  static void markAllStale() {
    PatientListRefresh.markStale();
    AppointmentListRefresh.markStale();
    ClinicalEncounterListRefresh.markStale();
    AssistantClinicalSummaryListRefresh.markStale();
    PdfOutputListRefresh.markStale();
    PaymentListRefresh.markStale();
    ConsentListRefresh.markStale();
    ExercisePlanListRefresh.markStale();
    ImagingListRefresh.markStale();
    InventoryListRefresh.markStale();
    PhysiotherapyReferralListRefresh.markStale();
    PhysiotherapySessionListRefresh.markStale();
    PostOpProtocolListRefresh.markStale();
    SurgeryNoteListRefresh.markStale();
  }
}
