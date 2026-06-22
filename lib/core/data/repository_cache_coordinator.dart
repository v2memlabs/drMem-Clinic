import '../../features/appointments/data/appointment_repository_provider.dart';
import '../../features/clinical_encounter/data/clinical_encounter_repository_provider.dart';
import '../../features/clinical_encounter/data/clinical_role_summary_repository_provider.dart';
import '../../features/patient_files/data/patient_file_metadata_repository_provider.dart';
import '../../features/patient_files/data/patient_file_storage_repository_provider.dart';
import '../../features/consents/data/consent_repository_provider.dart';
import '../../features/exercises/data/exercise_plan_repository_provider.dart';
import '../../features/imaging/data/imaging_repository_provider.dart';
import '../../features/inventory/data/inventory_repository_provider.dart';
import '../../features/physiotherapy/data/physiotherapy_referral_repository_provider.dart';
import '../../features/physiotherapy/data/physiotherapy_session_repository_provider.dart';
import '../../features/payments/data/payment_repository_provider.dart';
import '../../features/payments/data/payment_staff_notification_repository_provider.dart';
import '../../features/pdf_outputs/data/pdf_output_repository_provider.dart';
import '../../features/post_op_protocols/data/post_op_protocol_repository_provider.dart';
import '../../features/patient_tags/data/patient_tag_repository_provider.dart';
import '../../features/patients/data/patient_repository_provider.dart';
import '../../features/settings/data/clinic_workflow_settings_repository_provider.dart';
import '../../features/settings/data/profile_settings_repository_provider.dart';
import '../../features/settings/data/staff_leave_record_repository_provider.dart';
import '../../features/settings/data/staff_leave_request_repository_provider.dart';
import '../../features/settings/data/tenant_invite_repository_provider.dart';
import '../../features/settings/data/tenant_membership_repository_provider.dart';
import '../../features/settings/data/tenant_settings_repository_provider.dart';
import '../../features/settings/data/tenant_subscription_repository_provider.dart';
import '../../features/surgery/data/surgery_note_template_repository_provider.dart';
import '../../features/surgery/data/surgery_procedure_note_repository_provider.dart';
import '../../features/timeline/data/timeline_repository_provider.dart';
import '../../features/audit/data/audit_log_repository_provider.dart';
import '../../features/prescriptions/data/prescription_repository_provider.dart';
import '../../features/lab_orders/data/lab_order_repository_provider.dart';
import '../../features/lab_orders/data/lab_order_template_repository_provider.dart';
import '../../features/radiology_orders/data/radiology_order_repository_provider.dart';
import '../../features/clinical_reports/data/clinical_report_repository_provider.dart';
import '../../features/messages/data/message_template_repository_provider.dart';
import '../../features/messages/data/sent_message_repository_provider.dart';
import '../../features/dashboard/notifications/dashboard_notification_dismissals.dart';
import 'remote_list_refresh_coordinator.dart';

/// Uzak repository provider cache'leri — oturum/tenant/rol değişiminde sıfırlama.
///
/// Tenant switch UI eklendiğinde [ActiveTenantContextStore.set] üzerinden
/// otomatik tetiklenir; manuel çağrı gerekmez.
abstract final class RepositoryCacheCoordinator {
  /// Tüm remote provider instance cache'lerini temizler.
  static void resetAllRemoteProviderCaches() {
    PatientRepositoryProvider.resetCache();
    PatientTagRepositoryProvider.resetCache();
    AppointmentRepositoryProvider.resetCache();
    ClinicalEncounterRepositoryProvider.resetCache();
    ClinicalRoleSummaryRepositoryProvider.resetCache();
    PatientFileMetadataRepositoryProvider.resetCache();
    PdfOutputRepositoryProvider.resetCache();
    PaymentRepositoryProvider.resetCache();
    PaymentStaffNotificationRepositoryProvider.resetCache();
    ConsentRepositoryProvider.resetCache();
    ExercisePlanRepositoryProvider.resetCache();
    ImagingRepositoryProvider.resetCache();
    InventoryRepositoryProvider.resetCache();
    PostOpProtocolRepositoryProvider.resetCache();
    PhysiotherapyReferralRepositoryProvider.resetCache();
    PhysiotherapySessionRepositoryProvider.resetCache();
    TimelineRepositoryProvider.resetCache();
    AuditLogRepositoryProvider.resetCache();
    PrescriptionRepositoryProvider.resetCache();
    LabOrderRepositoryProvider.resetCache();
    LabOrderTemplateRepositoryProvider.resetCache();
    RadiologyOrderRepositoryProvider.resetCache();
    ClinicalReportRepositoryProvider.resetCache();
    MessageTemplateRepositoryProvider.resetCache();
    SentMessageRepositoryProvider.resetCache();
    SurgeryProcedureNoteRepositoryProvider.resetCache();
    SurgeryNoteTemplateRepositoryProvider.resetCache();
    ClinicWorkflowSettingsRepositoryProvider.resetCache();
    ProfileSettingsRepositoryProvider.resetCache();
    TenantSettingsRepositoryProvider.resetCache();
    TenantMembershipRepositoryProvider.resetCache();
    TenantInviteRepositoryProvider.resetCache();
    StaffLeaveRecordRepositoryProvider.resetCache();
    StaffLeaveRequestRepositoryProvider.resetCache();
    TenantSubscriptionRepositoryProvider.resetCache();
    PatientFileStorageRepositoryProvider.resetCache();
  }

  /// Provider cache + hasta/randevu liste stale sürümleri.
  static void resetForSessionContextChange() {
    resetAllRemoteProviderCaches();
    DashboardNotificationDismissals.reset();
    RemoteListRefreshCoordinator.markAllStale();
  }

  /// Logout / oturum iptali.
  static void onSessionCleared() {
    resetForSessionContextChange();
  }

  /// Başarılı login veya bootstrap sonrası yeni oturum.
  static void onSessionEstablished() {
    resetForSessionContextChange();
  }

  /// Aktif tenant kimliği değişti (aynı kullanıcı, farklı klinik).
  static void onActiveTenantChanged() {
    resetForSessionContextChange();
  }
}
