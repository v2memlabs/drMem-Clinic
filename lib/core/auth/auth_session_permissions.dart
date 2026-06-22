import '../../features/settings/models/tenant_role_access_settings.dart';
import '../constants/app_roles.dart';
import '../tenant/tenant_financial_feature_gate.dart';
import '../tenant/tenant_role_access_gate.dart';
import 'auth_session.dart';

/// [AuthSession] klinik izin getter'ları — tenant matrisi + varsayılanlar.
abstract final class AuthSessionPermissions {
  static bool _allow(TenantRoleAccessKey key) =>
      TenantRoleAccessGate.isAllowed(key);

  static bool get canViewPatients => _allow(TenantRoleAccessKey.viewPatients);
  static bool get canEditPatients => _allow(TenantRoleAccessKey.editPatients);
  static bool get canViewAllAppointments =>
      _allow(TenantRoleAccessKey.viewAllAppointments);
  static bool get canViewOwnScopedAppointments =>
      _allow(TenantRoleAccessKey.viewOwnScopedAppointments);
  static bool get canViewAppointments =>
      canViewAllAppointments || canViewOwnScopedAppointments;
  static bool get canEditAppointments =>
      _allow(TenantRoleAccessKey.editAppointments);
  static bool get canBookReferralAppointments =>
      canEditAppointments ||
      (AuthSession.currentUser?.role == AppRoles.physiotherapist &&
          _allow(TenantRoleAccessKey.editPhysiotherapy));
  static bool get canApproveExercisePlans =>
      _allow(TenantRoleAccessKey.editClinicalEncounters);
  static bool get canSelectAppointmentDoctor =>
      _allow(TenantRoleAccessKey.selectAppointmentDoctor);
  static bool get canStartAnamnesis =>
      _allow(TenantRoleAccessKey.startAnamnesis);
  static bool get canViewAnamnesisDetails =>
      _allow(TenantRoleAccessKey.viewAnamnesisDetails);
  static bool get canEditAnamnesis =>
      _allow(TenantRoleAccessKey.editAnamnesis);
  static bool get canViewAnamnesis => canViewAnamnesisDetails;
  static bool get canViewFullClinicalEncounter =>
      _allow(TenantRoleAccessKey.viewClinicalEncounters);
  static bool get canViewClinicalEncounters => canViewFullClinicalEncounter;
  static bool get canEditClinicalEncounters =>
      _allow(TenantRoleAccessKey.editClinicalEncounters);
  static bool get canViewClinicalDiagnosisSummary =>
      _allow(TenantRoleAccessKey.viewClinicalDiagnosisSummary);
  static bool get canViewExaminationDetails =>
      _allow(TenantRoleAccessKey.viewExaminationDetails);
  static bool get canViewTreatmentPlanDetails =>
      _allow(TenantRoleAccessKey.viewTreatmentPlanDetails);
  static bool get canViewClinicalSummary =>
      _allow(TenantRoleAccessKey.viewClinicalSummary);
  static bool get canViewClinicalDiagnosis =>
      _allow(TenantRoleAccessKey.viewClinicalDiagnosis);
  static bool get canViewClinicalTreatmentPlan =>
      _allow(TenantRoleAccessKey.viewClinicalTreatmentPlan);
  static bool get canViewExaminationNotes => canViewExaminationDetails;
  static bool get canEditExaminationNotes =>
      _allow(TenantRoleAccessKey.editExaminationNotes);
  static bool get canViewDiagnosis =>
      _allow(TenantRoleAccessKey.viewClinicalEncounters);
  static bool get canEditDiagnosis => _allow(TenantRoleAccessKey.editDiagnosis);
  static bool get canViewTreatmentPlans => canViewTreatmentPlanDetails;
  static bool get canEditTreatmentPlans =>
      _allow(TenantRoleAccessKey.editTreatmentPlans);
  static bool get canViewImaging => _allow(TenantRoleAccessKey.viewImaging);
  static bool get canEditImaging => _allow(TenantRoleAccessKey.editImaging);
  static bool get canViewPdfOutputs => _allow(TenantRoleAccessKey.viewPdfOutputs);
  static bool get canEditPdfOutputs => _allow(TenantRoleAccessKey.editPdfOutputs);
  static bool get canViewPrescriptions =>
      _allow(TenantRoleAccessKey.viewPrescriptions);
  static bool get canEditPrescriptions =>
      _allow(TenantRoleAccessKey.editPrescriptions);
  static bool get canViewClinicalReports =>
      _allow(TenantRoleAccessKey.viewClinicalReports);
  static bool get canEditClinicalReports =>
      _allow(TenantRoleAccessKey.editClinicalReports);
  static bool get canViewRadiologyOrders =>
      _allow(TenantRoleAccessKey.viewRadiologyOrders);
  static bool get canEditRadiologyOrders =>
      _allow(TenantRoleAccessKey.editRadiologyOrders);
  static bool get canViewLabOrders => _allow(TenantRoleAccessKey.viewLabOrders);
  static bool get canEditLabOrders => _allow(TenantRoleAccessKey.editLabOrders);
  static bool get canManageLabOrderTemplates =>
      _allow(TenantRoleAccessKey.manageLabOrderTemplates);
  static bool get canViewAuditLogs => _allow(TenantRoleAccessKey.viewAuditLogs);
  static bool get canViewSurgeryNotes =>
      _allow(TenantRoleAccessKey.viewSurgeryNotes);
  static bool get canEditSurgeryNotes =>
      _allow(TenantRoleAccessKey.editSurgeryNotes);
  static bool get canViewPatientTimeline =>
      _allow(TenantRoleAccessKey.viewPatientTimeline);
  static bool get canViewFiles => _allow(TenantRoleAccessKey.viewFiles);
  static bool get canEditFiles => _allow(TenantRoleAccessKey.editFiles);
  static bool get canViewConsents => _allow(TenantRoleAccessKey.viewConsents);
  static bool get canEditConsents => _allow(TenantRoleAccessKey.editConsents);
  static bool get canViewConsentTemplates =>
      _allow(TenantRoleAccessKey.viewConsentTemplates);
  static bool get canViewPayments =>
      TenantFinancialFeatureGate.paymentRecordsEnabled &&
      _allow(TenantRoleAccessKey.viewPayments);
  static bool get canCreatePayments =>
      TenantFinancialFeatureGate.paymentRecordsEnabled &&
      _allow(TenantRoleAccessKey.createPayments);
  static bool get canEditPayments =>
      TenantFinancialFeatureGate.paymentRecordsEnabled &&
      _allow(TenantRoleAccessKey.editPayments);
  static bool get canChargePatientMaterials =>
      TenantFinancialFeatureGate.materialChargesEnabled &&
      _allow(TenantRoleAccessKey.chargePatientMaterials);
  static bool get canViewMessages => _allow(TenantRoleAccessKey.viewMessages);
  static bool get canViewMessageTemplates =>
      _allow(TenantRoleAccessKey.viewMessageTemplates);
  static bool get canViewPhysiotherapy =>
      _allow(TenantRoleAccessKey.viewPhysiotherapy);
  static bool get canEditPhysiotherapy =>
      _allow(TenantRoleAccessKey.editPhysiotherapy);
  static bool get canViewExercisePlans =>
      _allow(TenantRoleAccessKey.viewExercisePlans);
  static bool get canEditExercisePlans =>
      _allow(TenantRoleAccessKey.editExercisePlans);
  static bool get canViewPostOpProtocols =>
      _allow(TenantRoleAccessKey.viewPostOpProtocols);
  static bool get canEditPostOpProtocols =>
      _allow(TenantRoleAccessKey.editPostOpProtocols);
  static bool get canViewInventory => _allow(TenantRoleAccessKey.viewInventory);
  static bool get canEditInventory => _allow(TenantRoleAccessKey.editInventory);
  static bool get canRecordInventoryMovement =>
      _allow(TenantRoleAccessKey.recordInventoryMovement);
  static bool get canViewPatientAlerts =>
      _allow(TenantRoleAccessKey.viewPatientAlerts);
  static bool get canViewPatientTags =>
      _allow(TenantRoleAccessKey.viewPatientTags);
  static bool get canCreatePatientTags =>
      _allow(TenantRoleAccessKey.createPatientTags);
  static bool get canAssignPatientTags =>
      _allow(TenantRoleAccessKey.assignPatientTags);
  static bool get canRemovePatientTags =>
      _allow(TenantRoleAccessKey.removePatientTags);
  static bool get canApproveStaffLeave =>
      _allow(TenantRoleAccessKey.approveStaffLeave);
  static bool get canViewDoctorOnlySettings =>
      _allow(TenantRoleAccessKey.viewDoctorOnlySettings);
  static bool get canEditClinicProfile =>
      _allow(TenantRoleAccessKey.editClinicProfile);
}
