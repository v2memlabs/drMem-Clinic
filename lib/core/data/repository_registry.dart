import 'backend_config.dart';
import '../../features/appointments/data/appointment_repository_contract.dart';
import '../../features/appointments/data/appointment_repository_provider.dart';
import '../../features/appointments/data/async_appointment_repository_contract.dart';
import '../../features/clinical_encounter/data/assistant_clinical_summary_repository.dart';
import '../../features/clinical_encounter/data/async_clinical_encounter_repository_contract.dart';
import '../../features/clinical_encounter/data/clinical_encounter_repository_provider.dart';
import '../../features/clinical_encounter/data/clinical_role_summary_repository_provider.dart';
import '../../features/clinical_encounter/data/physiotherapist_clinical_summary_repository.dart';
import '../../features/patient_files/data/patient_file_metadata_repository.dart';
import '../../features/patient_files/data/patient_file_metadata_repository_provider.dart';
import '../../features/consents/data/async_consent_repository_contract.dart';
import '../../features/consents/data/consent_repository_provider.dart';
import '../../features/exercises/data/async_exercise_plan_repository_contract.dart';
import '../../features/exercises/data/exercise_plan_repository_provider.dart';
import '../../features/imaging/data/async_imaging_repository_contract.dart';
import '../../features/imaging/data/imaging_repository_provider.dart';
import '../../features/inventory/data/async_inventory_repository_contract.dart';
import '../../features/inventory/data/inventory_repository_provider.dart';
import '../../features/payments/data/async_payment_repository_contract.dart';
import '../../features/physiotherapy/data/async_physiotherapy_referral_repository_contract.dart';
import '../../features/physiotherapy/data/async_physiotherapy_session_repository_contract.dart';
import '../../features/physiotherapy/data/physiotherapy_referral_repository_provider.dart';
import '../../features/physiotherapy/data/physiotherapy_session_repository_provider.dart';
import '../../features/payments/data/payment_repository_provider.dart';
import '../../features/payments/data/async_payment_staff_notification_repository_contract.dart';
import '../../features/payments/data/payment_staff_notification_repository_provider.dart';
import '../../features/pdf_outputs/data/async_pdf_output_repository_contract.dart';
import '../../features/pdf_outputs/data/pdf_output_repository_provider.dart';
import '../../features/post_op_protocols/data/async_post_op_protocol_repository_contract.dart';
import '../../features/post_op_protocols/data/post_op_protocol_repository_provider.dart';
import '../../features/surgery/data/async_surgery_procedure_note_repository_contract.dart';
import '../../features/surgery/data/surgery_procedure_note_repository_provider.dart';
import '../../features/timeline/data/timeline_repository.dart';
import '../../features/timeline/data/timeline_repository_provider.dart';
import '../../features/audit/data/async_audit_log_repository_contract.dart';
import '../../features/audit/data/audit_log_repository_provider.dart';
import '../../features/prescriptions/data/async_prescription_repository_contract.dart';
import '../../features/prescriptions/data/prescription_repository_provider.dart';
import '../../features/lab_orders/data/async_lab_order_repository_contract.dart';
import '../../features/lab_orders/data/async_lab_order_template_repository_contract.dart';
import '../../features/lab_orders/data/lab_order_repository_provider.dart';
import '../../features/lab_orders/data/lab_order_template_repository_provider.dart';
import '../../features/radiology_orders/data/async_radiology_order_repository_contract.dart';
import '../../features/radiology_orders/data/radiology_order_repository_provider.dart';
import '../../features/clinical_reports/data/async_clinical_report_repository_contract.dart';
import '../../features/clinical_reports/data/clinical_report_repository_provider.dart';
import '../../features/messages/data/async_message_template_repository_contract.dart';
import '../../features/messages/data/async_sent_message_repository_contract.dart';
import '../../features/messages/data/message_template_repository_provider.dart';
import '../../features/messages/data/sent_message_repository_provider.dart';
import '../../features/patients/data/async_patient_repository_contract.dart';
import '../../features/patients/data/patient_repository_contract.dart';
import '../../features/patients/data/patient_repository_provider.dart';
import '../auth/auth_repository_contract.dart';
import '../auth/membership_loader.dart';
import '../auth/membership_resolver.dart';
import '../auth/mock_auth_repository_adapter.dart';
import '../auth/supabase_auth_repository.dart';
import '../session/active_tenant_context_loader.dart';
import '../session/session_context_resolver.dart';
import 'repository_cache_coordinator.dart';

/// Merkezi repository erişimi.
///
/// - [auth]: mock → [MockAuthRepositoryAdapter]; supabase → [SupabaseAuthRepository]
/// - [membershipLoader]: mock → [MockMembershipLoader]; supabase → [SupabaseMembershipLoader]
/// - [tenantLoader]: mock / supabase stub (gerçek bağlantı yok)
/// - [patientsAsync]: mock veya [SupabasePatientRepository] (koşullu)
/// - [patients] sync: mock adapter (lookup fallback; production UI async/lookup)
/// - [appointmentsAsync]: mock veya [SupabaseAppointmentRepository] (koşullu)
/// - [appointments] sync: mock adapter (lookup fallback; production UI async)
/// - [clinicalEncountersAsync]: mock veya [SupabaseClinicalEncounterRepository] (doctor + koşullu)
/// - [assistantClinicalSummaries]: stub veya [SupabaseAssistantClinicalSummaryRepository] (rol + koşullu)
/// - [physiotherapistClinicalSummaries]: stub veya [SupabasePhysiotherapistClinicalSummaryRepository]
/// - [patientFileMetadata]: stub veya [SupabasePatientFileMetadataRepository] (rol + koşullu; Storage yok)
/// - [pdfOutputsAsync]: mock veya [SupabasePdfOutputRepository] (doctor + koşullu)
/// - [paymentsAsync]: mock adapter veya stub (şema hazır olunca remote)
/// - [consentsAsync]: mock adapter veya stub
/// - [inventoryAsync]: mock adapter veya stub
/// - [patientTimeline]: stub veya [SupabaseTimelineRepository] (doctor + koşullu; audit merge yok)
abstract final class RepositoryRegistry {
  static final AuthRepositoryContract auth = _resolveAuth();

  static MembershipLoader get membershipLoader => MembershipResolver.loader;

  static ActiveTenantContextLoader get tenantLoader =>
      SessionContextResolver.tenantLoader;

  static PatientRepositoryContract get patients =>
      PatientRepositoryProvider.current;

  /// Async hasta CRUD — Supabase mod + oturum/tenant hazır ise remote.
  static AsyncPatientRepositoryContract get patientsAsync =>
      PatientRepositoryProvider.asyncRepository;

  static bool get usesRemotePatients =>
      PatientRepositoryProvider.usesRemotePatients;

  static AppointmentRepositoryContract get appointments =>
      AppointmentRepositoryProvider.current;

  /// Async randevu CRUD — Supabase mod + oturum/tenant hazır ise remote.
  static AsyncAppointmentRepositoryContract get appointmentsAsync =>
      AppointmentRepositoryProvider.asyncRepository;

  static bool get usesRemoteAppointments =>
      AppointmentRepositoryProvider.usesRemoteAppointments;

  /// Async muayene CRUD — Supabase + doctor_admin + oturum/tenant hazır ise remote.
  static AsyncClinicalEncounterRepositoryContract get clinicalEncountersAsync =>
      ClinicalEncounterRepositoryProvider.asyncRepository;

  static bool get usesRemoteClinicalEncounters =>
      ClinicalEncounterRepositoryProvider.usesRemoteClinicalEncounters;

  /// Assistant/Secretary güvenli özet — full muayene repo değil.
  static AssistantClinicalSummaryRepository get assistantClinicalSummaries =>
      ClinicalRoleSummaryRepositoryProvider.assistantRepository;

  static bool get usesRemoteAssistantClinicalSummaries =>
      ClinicalRoleSummaryRepositoryProvider
          .usesRemoteAssistantClinicalSummaries;

  /// FTR güvenli özet — full muayene repo değil.
  static PhysiotherapistClinicalSummaryRepository
      get physiotherapistClinicalSummaries =>
          ClinicalRoleSummaryRepositoryProvider.physiotherapistRepository;

  static bool get usesRemotePhysiotherapistClinicalSummaries =>
      ClinicalRoleSummaryRepositoryProvider
          .usesRemotePhysiotherapistClinicalSummaries;

  /// Hasta dosya / PDF metadata — Storage binary veya signed URL yok.
  static PatientFileMetadataRepository get patientFileMetadata =>
      PatientFileMetadataRepositoryProvider.repository;

  static bool get usesRemotePatientFileMetadata =>
      PatientFileMetadataRepositoryProvider.usesRemotePatientFileMetadata;

  /// Async PDF çıktı — Supabase + doctor + oturum/tenant hazır ise remote.
  static AsyncPdfOutputRepositoryContract get pdfOutputsAsync =>
      PdfOutputRepositoryProvider.asyncRepository;

  static bool get usesRemotePdfOutputs =>
      PdfOutputRepositoryProvider.usesRemotePdfOutputs;

  /// Hasta timeline — yalnızca `list_patient_timeline_events` RPC (audit değil).
  static TimelineRepository get patientTimeline =>
      TimelineRepositoryProvider.repository;

  static bool get usesRemotePatientTimeline =>
      TimelineRepositoryProvider.usesRemotePatientTimeline;

  /// Async audit log — Supabase + view_audit_logs rolü + oturum/tenant hazır ise remote.
  static AsyncAuditLogRepositoryContract get auditLogsAsync =>
      AuditLogRepositoryProvider.asyncRepository;

  static bool get usesRemoteAuditLogs =>
      AuditLogRepositoryProvider.usesRemoteAuditLogs;

  /// Async reçete — Supabase + reçete rolü + oturum/tenant hazır ise remote.
  static AsyncPrescriptionRepositoryContract get prescriptionsAsync =>
      PrescriptionRepositoryProvider.asyncRepository;

  static bool get usesRemotePrescriptions =>
      PrescriptionRepositoryProvider.usesRemotePrescriptions;

  /// Async lab istemi — Supabase + lab rolü + oturum/tenant hazır ise remote.
  static AsyncLabOrderRepositoryContract get labOrdersAsync =>
      LabOrderRepositoryProvider.asyncRepository;

  static bool get usesRemoteLabOrders =>
      LabOrderRepositoryProvider.usesRemoteLabOrders;

  /// Async lab istem şablonu — Supabase + lab şablon rolü + oturum/tenant hazır ise remote.
  static AsyncLabOrderTemplateRepositoryContract get labOrderTemplatesAsync =>
      LabOrderTemplateRepositoryProvider.asyncRepository;

  static bool get usesRemoteLabOrderTemplates =>
      LabOrderTemplateRepositoryProvider.usesRemoteLabOrderTemplates;

  /// Async radyoloji istemi — Supabase + radyoloji rolü + oturum/tenant hazır ise remote.
  static AsyncRadiologyOrderRepositoryContract get radiologyOrdersAsync =>
      RadiologyOrderRepositoryProvider.asyncRepository;

  static bool get usesRemoteRadiologyOrders =>
      RadiologyOrderRepositoryProvider.usesRemoteRadiologyOrders;

  /// Async klinik rapor — Supabase + klinik rapor rolü + oturum/tenant hazır ise remote.
  static AsyncClinicalReportRepositoryContract get clinicalReportsAsync =>
      ClinicalReportRepositoryProvider.asyncRepository;

  static bool get usesRemoteClinicalReports =>
      ClinicalReportRepositoryProvider.usesRemoteClinicalReports;

  /// Async mesaj şablonu — Supabase + mesaj rolü + oturum/tenant hazır ise remote.
  static AsyncMessageTemplateRepositoryContract get messageTemplatesAsync =>
      MessageTemplateRepositoryProvider.asyncRepository;

  static bool get usesRemoteMessageTemplates =>
      MessageTemplateRepositoryProvider.usesRemoteMessageTemplates;

  /// Async gönderim kaydı — Supabase + view_messages rolü + oturum/tenant hazır ise remote.
  static AsyncSentMessageRepositoryContract get sentMessagesAsync =>
      SentMessageRepositoryProvider.asyncRepository;

  static bool get usesRemoteSentMessages =>
      SentMessageRepositoryProvider.usesRemoteSentMessages;

  /// Async ödeme — mock adapter veya Supabase stub (tablo hazır olunca remote).
  static AsyncPaymentRepositoryContract get paymentsAsync =>
      PaymentRepositoryProvider.asyncRepository;

  static bool get usesRemotePayments =>
      PaymentRepositoryProvider.usesRemotePayments;

  /// Async ödeme bildirimi — asistan veya ödeme rolü + oturum/tenant hazır ise remote.
  static AsyncPaymentStaffNotificationRepositoryContract
      get paymentStaffNotifications =>
          PaymentStaffNotificationRepositoryProvider.repository;

  static bool get usesRemotePaymentStaffNotifications =>
      PaymentStaffNotificationRepositoryProvider
          .usesRemotePaymentStaffNotifications;

  /// Async onam — mock adapter veya Supabase stub.
  static AsyncConsentRepositoryContract get consentsAsync =>
      ConsentRepositoryProvider.asyncRepository;

  static bool get usesRemoteConsents =>
      ConsentRepositoryProvider.usesRemoteConsents;

  /// Async stok — mock adapter veya Supabase stub.
  static AsyncInventoryRepositoryContract get inventoryAsync =>
      InventoryRepositoryProvider.asyncRepository;

  static bool get usesRemoteInventory =>
      InventoryRepositoryProvider.usesRemoteInventory;

  /// Async egzersiz programı — Supabase + egzersiz rolü + oturum/tenant hazır ise remote.
  static AsyncExercisePlanRepositoryContract get exercisePlansAsync =>
      ExercisePlanRepositoryProvider.asyncRepository;

  static bool get usesRemoteExercisePlans =>
      ExercisePlanRepositoryProvider.usesRemoteExercisePlans;

  /// Async post-op protokol — Supabase + post-op rolü + oturum/tenant hazır ise remote.
  static AsyncPostOpProtocolRepositoryContract get postOpProtocolsAsync =>
      PostOpProtocolRepositoryProvider.asyncRepository;

  static bool get usesRemotePostOpProtocols =>
      PostOpProtocolRepositoryProvider.usesRemotePostOpProtocols;

  /// Async görüntüleme notu — Supabase + imaging rolü + oturum/tenant hazır ise remote.
  static AsyncImagingRepositoryContract get imagingNotesAsync =>
      ImagingRepositoryProvider.asyncRepository;

  static bool get usesRemoteImagingNotes =>
      ImagingRepositoryProvider.usesRemoteImagingNotes;

  /// Async FTR yönlendirme — mock adapter veya Supabase remote.
  static AsyncPhysiotherapyReferralRepositoryContract
      get physiotherapyReferralsAsync =>
          PhysiotherapyReferralRepositoryProvider.asyncRepository;

  static bool get usesRemotePhysiotherapyReferrals =>
      PhysiotherapyReferralRepositoryProvider.usesRemoteReferrals;

  /// Async FTR seans notu — mock adapter veya Supabase remote.
  static AsyncPhysiotherapySessionRepositoryContract
      get physiotherapySessionsAsync =>
          PhysiotherapySessionRepositoryProvider.asyncRepository;

  static bool get usesRemotePhysiotherapySessions =>
      PhysiotherapySessionRepositoryProvider.usesRemoteSessions;

  /// Async ameliyat / girişim notu — Supabase + doctor + oturum/tenant hazır ise remote.
  static AsyncSurgeryProcedureNoteRepositoryContract
      get surgeryProcedureNotesAsync =>
          SurgeryProcedureNoteRepositoryProvider.asyncRepository;

  static bool get usesRemoteSurgeryProcedureNotes =>
      SurgeryProcedureNoteRepositoryProvider.usesRemoteSurgeryProcedureNotes;

  /// Oturum/tenant/rol/backend değişiminde tüm remote provider cache'lerini sıfırlar.
  static void resetAllCaches() {
    RepositoryCacheCoordinator.resetForSessionContextChange();
  }

  static AuthRepositoryContract _resolveAuth() {
    if (AppBackendConfig.isMock) {
      return MockAuthRepositoryAdapter();
    }
    return SupabaseAuthRepository();
  }
}
