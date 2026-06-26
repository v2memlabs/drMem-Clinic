import '../tenant/tenant_financial_feature_gate.dart';
import 'auth_session.dart';

/// Route erişim matrisi — [AppRouter] guard'ları ile aynı semantik.
///
/// UI visibility tek başına yeterli değil; doğrudan URL için de kontrol edilir.
/// Menü: [AppNavConfig]; dashboard kartları bu sınıf ile filtrelenmeli.
abstract final class AuthRoutePermissions {
  /// Dashboard / menü / kart navigasyonu için path izni (query string yok sayılır).
  static bool canAccessPath(String location) {
    final path = Uri.parse(location).path;

    if (_isPublicPath(path)) return true;

    if (!AuthSession.isLoggedIn) return false;

    return _canAccessAuthenticatedPath(path);
  }

  static bool _isPublicPath(String path) {
    return path == '/login' ||
        path.startsWith('/session/') ||
        path.startsWith('/account/');
  }

  static bool _canAccessAuthenticatedPath(String path) {
    if (AuthSession.isMaintenanceOperator) {
      return path == '/maintenance' || path.startsWith('/maintenance/');
    }

    if (path == '/maintenance' || path.startsWith('/maintenance/')) {
      return false;
    }

    if (path == '/doctor') return AuthSession.canAccessDoctorDashboard;
    if (path == '/assistant') return AuthSession.canAccessAssistantDashboard;
    if (path == '/physio') return AuthSession.canAccessPhysioDashboard;
    if (path == '/nurse') return AuthSession.canAccessNurseDashboard;
    if (path == '/clinic-workflow' || path == '/settings/clinic-workflow') {
      return AuthSession.canViewSettings;
    }

    if (path == '/staff-leave-requests') {
      return AuthSession.canRequestStaffLeave;
    }

    if (path == '/staff-leaves' ||
        path == '/settings/clinic-workflow/staff-leaves') {
      return AuthSession.canViewSettings;
    }

    if (path == '/settings' || path.startsWith('/settings/')) {
      if (path == '/settings/users-roles' ||
          path.startsWith('/settings/users-roles/')) {
        return AuthSession.canEditClinicProfile;
      }
      if (path == '/settings/clinic-finance') {
        return AuthSession.canViewDoctorOnlySettings &&
            TenantFinancialFeatureGate.paymentRecordsEnabled;
      }
      if (path == '/settings/clinic' ||
          path == '/settings/patient-settings' ||
          path == '/settings/demo-usage' ||
          path == '/settings/subscription') {
        return AuthSession.canViewDoctorOnlySettings;
      }
      return AuthSession.canViewSettings;
    }

    if (path.startsWith('/clinical-records/diagnosis-summary')) {
      return AuthSession.canViewClinicalDiagnosisSummary;
    }

    if (path.startsWith('/physiotherapy/clinical-summaries')) {
      return AuthSession.canViewClinicalSummary;
    }

    if (path.startsWith('/clinical-records')) {
      if (RegExp(r'^/clinical-records/[^/]+/wizard-payment$').hasMatch(path)) {
        return AuthSession.canEditClinicalEncounters &&
            TenantFinancialFeatureGate.encounterPaymentStepEnabled &&
            AuthSession.canEditPayments;
      }
      if (path.endsWith('/new') || path.contains('/edit')) {
        return AuthSession.canEditClinicalEncounters;
      }
      return AuthSession.canViewClinicalEncounters;
    }

    if (path == '/patients') return AuthSession.canViewPatients;
    if (path == '/patients/new') return AuthSession.canEditPatients;
    if (_isPatientEdit(path)) return AuthSession.canEditPatients;
    if (_isPatientDetail(path)) return AuthSession.canViewPatients;

    if (path == '/patient-timeline') return AuthSession.canViewPatientTimeline;
    if (path == '/patient-alerts') return AuthSession.canViewPatientAlerts;
    if (path == '/patient-tags') return AuthSession.canViewPatientTags;

    if (path.startsWith('/appointments')) {
      if (path.endsWith('/new') || path.contains('/edit')) {
        return AuthSession.canEditAppointments ||
            AuthSession.canBookReferralAppointments;
      }
      return AuthSession.canViewAppointments;
    }

    if (path.startsWith('/surgery-notes')) {
      if (path.endsWith('/new') || path.contains('/edit')) {
        return AuthSession.canEditSurgeryNotes;
      }
      return AuthSession.canViewSurgeryNotes;
    }

    if (path.startsWith('/post-op-protocols')) {
      if (path.endsWith('/new')) return AuthSession.canEditPostOpProtocols;
      return AuthSession.canViewPostOpProtocols;
    }

    if (path.startsWith('/imaging')) {
      if (path.endsWith('/new')) return AuthSession.canEditImaging;
      return AuthSession.canViewImaging;
    }

    if (path.startsWith('/files')) {
      if (path.endsWith('/upload')) return AuthSession.canEditFiles;
      return AuthSession.canViewFiles;
    }

    if (path.startsWith('/pdf-outputs')) {
      if (path.endsWith('/new')) return AuthSession.canEditPdfOutputs;
      return AuthSession.canViewPdfOutputs;
    }

    if (path.startsWith('/prescriptions')) {
      if (path.endsWith('/new') || path.contains('/edit')) {
        return AuthSession.canEditPrescriptions;
      }
      return AuthSession.canViewPrescriptions;
    }

    if (path.startsWith('/clinical-reports')) {
      if (path.endsWith('/new') || path.contains('/edit')) {
        return AuthSession.canEditClinicalReports;
      }
      return AuthSession.canViewClinicalReports;
    }

    if (path.startsWith('/radiology-orders')) {
      if (path.endsWith('/new') || path.contains('/edit')) {
        return AuthSession.canEditRadiologyOrders;
      }
      return AuthSession.canViewRadiologyOrders;
    }

    if (path.startsWith('/lab-order-templates')) {
      if (path.endsWith('/new') || path.contains('/edit')) {
        return AuthSession.canManageLabOrderTemplates;
      }
      return AuthSession.canManageLabOrderTemplates;
    }

    if (path.startsWith('/lab-orders')) {
      if (path.endsWith('/new') || path.contains('/edit')) {
        return AuthSession.canEditLabOrders;
      }
      return AuthSession.canViewLabOrders;
    }

    if (path.startsWith('/audit-logs')) return AuthSession.canViewAuditLogs;

    if (path.startsWith('/consent-templates')) {
      if (path.endsWith('/new') || path.contains('/edit')) {
        return AuthSession.canEditClinicalEncounters;
      }
      return AuthSession.canViewConsentTemplates;
    }

    if (path.startsWith('/consents')) {
      if (path.contains('/first-visit-wizard')) {
        return AuthSession.canEditConsents;
      }
      if (path.endsWith('/new')) return AuthSession.canEditConsents;
      return AuthSession.canViewConsents;
    }

    if (path.startsWith('/inventory')) {
      if (path == '/inventory/new' || path.contains('/edit')) {
        return AuthSession.canEditInventory;
      }
      return AuthSession.canViewInventory;
    }

    if (path.startsWith('/payments')) {
      if (path.endsWith('/new')) return AuthSession.canCreatePayments;
      if (path.endsWith('/edit')) return AuthSession.canEditPayments;
      return AuthSession.canViewPayments;
    }

    if (path.startsWith('/messages/templates')) {
      return AuthSession.canViewMessageTemplates;
    }
    if (path.startsWith('/messages')) {
      return AuthSession.canViewMessages;
    }

    if (path.startsWith('/physiotherapy/referrals')) {
      if (path.endsWith('/new')) return AuthSession.canEditClinicalEncounters;
      return AuthSession.canViewPhysiotherapy;
    }

    if (path.startsWith('/physiotherapy/sessions')) {
      if (path.endsWith('/new')) return AuthSession.canEditPhysiotherapy;
      return AuthSession.canViewPhysiotherapy;
    }

    if (path.startsWith('/exercise-plans')) {
      if (path.endsWith('/new')) return AuthSession.canEditExercisePlans;
      return AuthSession.canViewExercisePlans;
    }

    return false;
  }

  static bool _isPatientDetail(String path) {
    final match = RegExp(r'^/patients/[^/]+$').hasMatch(path);
    return match && path != '/patients/new';
  }

  static bool _isPatientEdit(String path) {
    return RegExp(r'^/patients/[^/]+/edit$').hasMatch(path);
  }
}
