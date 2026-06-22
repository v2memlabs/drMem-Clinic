import 'user_display_names.dart';
import '../constants/app_roles.dart';
import '../session/mock_tenant_context_bridge.dart';
import '../session/session_persona.dart';
import '../../shared/models/app_user.dart';
import 'auth_session_permissions.dart';

/// In-memory session for the mock frontend (no backend).
class AuthSession {
  static AppUser? currentUser;
  static SessionPersona _persona = SessionPersona.clinical;

  static bool get isLoggedIn => currentUser != null;

  static SessionPersona get persona => _persona;

  /// Bakım operatörü oturumu (klinik route kapalı).
  static bool get isMaintenanceOperator =>
      _persona == SessionPersona.maintenanceOperator;

  /// Üretim hedefi: yalnız bakım konsolu, klinik üyelik olsa bile.
  static bool get isMaintenanceOperatorOnly => isMaintenanceOperator;

  static bool get _isClinicalSession => !isMaintenanceOperator;

  static bool get _isDoctor =>
      _isClinicalSession && currentUser?.role == AppRoles.doctor;
  static bool get _isAssistant =>
      _isClinicalSession && currentUser?.role == AppRoles.assistant;
  static bool get _isPhysiotherapist =>
      _isClinicalSession && currentUser?.role == AppRoles.physiotherapist;
  static bool get _isNurse =>
      _isClinicalSession && currentUser?.role == AppRoles.nurse;

  static void setUser(AppUser? user) {
    currentUser = user;
    _persona = SessionPersona.clinical;
    MockTenantContextBridge.bindFromAppUser(user);
  }

  /// IT bakım operatörü — tenant bağlamı yok.
  static void setMaintenanceUser(AppUser user) {
    currentUser = user;
    _persona = SessionPersona.maintenanceOperator;
    MockTenantContextBridge.bindFromAppUser(null);
  }

  static void clear() {
    currentUser = null;
    _persona = SessionPersona.clinical;
    MockTenantContextBridge.bindFromAppUser(null);
  }

  /// Oturumdaki kullanıcının görünen adını günceller (mock/local).
  static void updateDisplayName(String displayName) {
    final user = currentUser;
    if (user == null) return;
    final trimmed = displayName.trim();
    setUser(
      AppUser(
        id: user.id,
        username: user.username,
        displayName: trimmed.isEmpty
            ? UserDisplayNames.defaultForRole(user.role)
            : trimmed,
        role: user.role,
      ),
    );
  }

  // --- Hasta & randevu ---
  static bool get canViewPatients => AuthSessionPermissions.canViewPatients;
  static bool get canEditPatients => AuthSessionPermissions.canEditPatients;
  static bool get canViewAllAppointments =>
      AuthSessionPermissions.canViewAllAppointments;
  static bool get canViewOwnScopedAppointments =>
      AuthSessionPermissions.canViewOwnScopedAppointments;
  static bool get canViewAppointments =>
      AuthSessionPermissions.canViewAppointments;
  static bool get canEditAppointments =>
      AuthSessionPermissions.canEditAppointments;
  static bool get canBookReferralAppointments =>
      AuthSessionPermissions.canBookReferralAppointments;
  static bool get canApproveExercisePlans =>
      AuthSessionPermissions.canApproveExercisePlans;
  static bool get isPhysiotherapist => _isPhysiotherapist;
  static bool get canSelectAppointmentDoctor =>
      AuthSessionPermissions.canSelectAppointmentDoctor;
  static bool get canStartAnamnesis => AuthSessionPermissions.canStartAnamnesis;
  static bool get canViewAnamnesis => AuthSessionPermissions.canViewAnamnesis;
  static bool get canEditAnamnesis => AuthSessionPermissions.canEditAnamnesis;

  // --- Klinik: Muayene Kayıtları (ClinicalEncounter) ---
  static bool get canViewFullClinicalEncounter =>
      AuthSessionPermissions.canViewFullClinicalEncounter;
  static bool get canViewClinicalEncounters =>
      AuthSessionPermissions.canViewClinicalEncounters;
  static bool get canEditClinicalEncounters =>
      AuthSessionPermissions.canEditClinicalEncounters;
  static bool get canViewClinicalDiagnosisSummary =>
      AuthSessionPermissions.canViewClinicalDiagnosisSummary;
  static bool get canViewAnamnesisDetails =>
      AuthSessionPermissions.canViewAnamnesisDetails;
  static bool get canViewClinicalSummary =>
      AuthSessionPermissions.canViewClinicalSummary;
  static bool get canViewClinicalDiagnosis =>
      AuthSessionPermissions.canViewClinicalDiagnosis;
  static bool get canViewClinicalTreatmentPlan =>
      AuthSessionPermissions.canViewClinicalTreatmentPlan;

  static bool get canViewImaging => AuthSessionPermissions.canViewImaging;
  static bool get canEditImaging => AuthSessionPermissions.canEditImaging;
  static bool get canViewPdfOutputs => AuthSessionPermissions.canViewPdfOutputs;
  static bool get canEditPdfOutputs => AuthSessionPermissions.canEditPdfOutputs;
  static bool get canViewPrescriptions =>
      AuthSessionPermissions.canViewPrescriptions;
  static bool get canEditPrescriptions =>
      AuthSessionPermissions.canEditPrescriptions;
  static bool get canViewClinicalReports =>
      AuthSessionPermissions.canViewClinicalReports;
  static bool get canEditClinicalReports =>
      AuthSessionPermissions.canEditClinicalReports;
  static bool get canViewRadiologyOrders =>
      AuthSessionPermissions.canViewRadiologyOrders;
  static bool get canEditRadiologyOrders =>
      AuthSessionPermissions.canEditRadiologyOrders;
  static bool get canViewLabOrders => AuthSessionPermissions.canViewLabOrders;
  static bool get canEditLabOrders => AuthSessionPermissions.canEditLabOrders;
  static bool get canManageLabOrderTemplates =>
      AuthSessionPermissions.canManageLabOrderTemplates;
  static bool get canViewAuditLogs => AuthSessionPermissions.canViewAuditLogs;
  static bool get canViewSurgeryNotes =>
      AuthSessionPermissions.canViewSurgeryNotes;
  static bool get canEditSurgeryNotes =>
      AuthSessionPermissions.canEditSurgeryNotes;
  static bool get canViewPatientTimeline =>
      AuthSessionPermissions.canViewPatientTimeline;

  // --- Dosya, onam, ödeme, mesaj ---
  static bool get canViewFiles => AuthSessionPermissions.canViewFiles;
  static bool get canEditFiles => AuthSessionPermissions.canEditFiles;
  static bool get canViewConsents => AuthSessionPermissions.canViewConsents;
  static bool get canEditConsents => AuthSessionPermissions.canEditConsents;
  static bool get canViewConsentTemplates =>
      AuthSessionPermissions.canViewConsentTemplates;
  static bool get canViewPayments => AuthSessionPermissions.canViewPayments;
  static bool get canCreatePayments => AuthSessionPermissions.canCreatePayments;
  static bool get canEditPayments => AuthSessionPermissions.canEditPayments;
  static bool get canChargePatientMaterials =>
      AuthSessionPermissions.canChargePatientMaterials;
  static bool get canViewMessages => AuthSessionPermissions.canViewMessages;
  static bool get canViewMessageTemplates =>
      AuthSessionPermissions.canViewMessageTemplates;

  // --- Fizyoterapi & egzersiz ---
  static bool get canViewPhysiotherapy =>
      AuthSessionPermissions.canViewPhysiotherapy;
  static bool get canEditPhysiotherapy =>
      AuthSessionPermissions.canEditPhysiotherapy;
  static bool get canViewExercisePlans =>
      AuthSessionPermissions.canViewExercisePlans;
  static bool get canEditExercisePlans =>
      AuthSessionPermissions.canEditExercisePlans;

  // --- Post-op ---
  static bool get canViewPostOpProtocols =>
      AuthSessionPermissions.canViewPostOpProtocols;
  static bool get canEditPostOpProtocols =>
      AuthSessionPermissions.canEditPostOpProtocols;

  // --- Stok / sarf ---
  static bool get canViewInventory => AuthSessionPermissions.canViewInventory;
  static bool get canEditInventory => AuthSessionPermissions.canEditInventory;
  static bool get canRecordInventoryMovement =>
      AuthSessionPermissions.canRecordInventoryMovement;

  // --- Hasta meta ---
  static bool get canViewPatientAlerts =>
      AuthSessionPermissions.canViewPatientAlerts;
  static bool get canViewPatientTags =>
      AuthSessionPermissions.canViewPatientTags;
  static bool get canCreatePatientTags =>
      AuthSessionPermissions.canCreatePatientTags;
  static bool get canAssignPatientTags =>
      AuthSessionPermissions.canAssignPatientTags;
  static bool get canRemovePatientTags =>
      AuthSessionPermissions.canRemovePatientTags;

  // --- Dashboard ---
  static bool get canAccessDoctorDashboard => _isDoctor;
  static bool get canAccessAssistantDashboard => _isAssistant;
  static bool get canAccessPhysioDashboard => _isPhysiotherapist;
  static bool get canAccessNurseDashboard => _isNurse;

  /// Ayarlar — klinik roller; bakım operatörü erişemez.
  static bool get canViewSettings => _isClinicalSession && isLoggedIn;

  /// Personel izin talebi oluşturma — tüm klinik personel.
  static bool get canRequestStaffLeave => _isClinicalSession && isLoggedIn;

  /// İzin talebi onay/red — tenant matrisinden.
  static bool get canApproveStaffLeave =>
      AuthSessionPermissions.canApproveStaffLeave;

  /// Hemşire, asistan, fizyoterapist (doktor hariç klinik personel).
  static bool get isClinicalNonDoctorStaff =>
      _isAssistant || _isNurse || _isPhysiotherapist;

  /// Klinik bilgileri, hasta ayarları, demo ve abonelik.
  static bool get canViewDoctorOnlySettings =>
      AuthSessionPermissions.canViewDoctorOnlySettings;

  static bool get canEditClinicProfile =>
      AuthSessionPermissions.canEditClinicProfile;

  static String get dashboardRoute {
    if (currentUser == null) return '/login';
    if (isMaintenanceOperator) return '/maintenance';

    switch (currentUser!.role) {
      case AppRoles.assistant:
        return '/assistant';
      case AppRoles.physiotherapist:
        return '/physio';
      case AppRoles.nurse:
        return '/nurse';
      case AppRoles.doctor:
        return '/doctor';
      default:
        return '/doctor';
    }
  }
}
