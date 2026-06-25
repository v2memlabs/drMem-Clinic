import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../auth/invitation_deep_link.dart';
import '../auth/auth_session.dart';
import 'auth_route_guard.dart';
import '../../features/system/account_access_status_screen.dart';
import '../../features/system/session_initializing_screen.dart';
import '../../shared/widgets/access_denied_screen.dart';
import '../../core/session/account_access_reason.dart';
import '../../features/imaging/imaging_list_screen.dart';
import '../../features/imaging/imaging_form_screen.dart';
import '../../features/imaging/imaging_detail_screen.dart';
import '../../features/files/file_list_screen.dart';
import '../../features/files/file_upload_screen.dart';
import '../../features/files/file_detail_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/invite_accept_screen.dart';
import '../../features/auth/update_password_screen.dart';
import '../../features/auth/forgot_password_screen.dart';
import '../../features/dashboard/doctor_dashboard_screen.dart';
import '../../features/dashboard/assistant_dashboard_screen.dart';
import '../../features/dashboard/physiotherapist_dashboard_screen.dart';
import '../../features/dashboard/nurse_dashboard_screen.dart';
import '../../features/inventory/inventory_list_screen.dart';
import '../../features/inventory/inventory_detail_screen.dart';
import '../../features/inventory/inventory_form_screen.dart';
import '../../features/patients/patient_list_screen.dart';
import '../../features/patients/patient_detail_screen.dart';
import '../../features/patients/patient_form_screen.dart';
import '../../features/patients/patient_timeline_screen.dart';
import '../../features/patients/patient_alerts_screen.dart';
import '../../features/patient_tags/screens/patient_tag_list_screen.dart';
import '../../features/appointments/appointment_list_screen.dart';
import '../../features/appointments/appointment_detail_screen.dart';
import '../../features/appointments/appointment_form_screen.dart';
import '../../features/clinical_encounter/clinical_encounter_list_screen.dart';
import '../../features/clinical_encounter/clinical_encounter_detail_screen.dart';
import '../../features/clinical_encounter/clinical_encounter_form_screen.dart';
import '../../features/clinical_encounter/post_encounter_wizard/post_encounter_payment_step_screen.dart';
import '../../features/clinical_encounter/post_encounter_wizard/post_encounter_wizard_navigation.dart';
import '../../features/clinical_encounter/clinical_diagnosis_summary_list_screen.dart';
import '../../features/clinical_encounter/clinical_diagnosis_summary_detail_screen.dart';
import '../../features/clinical_encounter/screens/physio_clinical_summary_list_screen.dart';
import '../../features/clinical_encounter/screens/physio_clinical_summary_detail_screen.dart';
import '../../features/pdf_outputs/pdf_output_list_screen.dart';
import '../../features/pdf_outputs/pdf_output_form_screen.dart';
import '../../features/pdf_outputs/pdf_output_detail_screen.dart';
import '../../features/audit/audit_log_list_screen.dart';
import '../../features/audit/audit_log_detail_screen.dart';
import '../../features/consents/consent_list_screen.dart';
import '../../features/consents/consent_form_screen.dart';
import '../../features/consents/consent_detail_screen.dart';
import '../../features/consents/consent_template_list_screen.dart';
import '../../features/consents/consent_template_detail_screen.dart';
import '../../features/consents/consent_template_prepare_screen.dart';
import '../../features/consents/consent_template_form_screen.dart';
import '../../features/consents/first_visit_consent_wizard_screen.dart';
import '../../features/messages/message_template_list_screen.dart';
import '../../features/messages/message_template_form_screen.dart';
import '../../features/messages/sent_message_list_screen.dart';
import '../../features/messages/message_send_screen.dart';
import '../../features/messages/sent_message_detail_screen.dart';
import '../../features/payments/payment_list_screen.dart';
import '../../features/payments/payment_form_screen.dart';
import '../../features/payments/payment_detail_screen.dart';
import '../../features/prescriptions/prescription_list_screen.dart';
import '../../features/prescriptions/prescription_form_screen.dart';
import '../../features/prescriptions/prescription_detail_screen.dart';
import '../../features/clinical_reports/clinical_report_list_screen.dart';
import '../../features/clinical_reports/clinical_report_form_screen.dart';
import '../../features/clinical_reports/clinical_report_detail_screen.dart';
import '../../features/radiology_orders/radiology_order_list_screen.dart';
import '../../features/radiology_orders/radiology_order_form_screen.dart';
import '../../features/radiology_orders/radiology_order_detail_screen.dart';
import '../../features/lab_orders/lab_order_list_screen.dart';
import '../../features/lab_orders/lab_order_form_screen.dart';
import '../../features/lab_orders/lab_order_detail_screen.dart';
import '../../features/lab_orders/lab_order_template_list_screen.dart';
import '../../features/lab_orders/lab_order_catalog_settings_screen.dart';
import '../../features/lab_orders/lab_order_template_form_screen.dart';
import '../../features/lab_orders/lab_order_template_detail_screen.dart';
import '../../features/settings/clinic_settings_screen.dart';
import '../../features/settings/clinic_workflow_settings_screen.dart';
import '../../features/settings/staff_leave_settings_screen.dart';
import '../../features/settings/staff_leave_request_screen.dart';
import '../../features/settings/clinic_finance_statistics_screen.dart';
import '../../features/settings/demo_usage_settings_screen.dart';
import '../../features/settings/display_region_settings_screen.dart';
import '../../features/settings/patient_settings_screen.dart';
import '../../features/settings/profile_settings_screen.dart';
import '../../features/settings/saas_subscription_settings_screen.dart';
import '../../features/settings/settings_hub_screen.dart';
import '../../features/settings/system_security_settings_screen.dart';
import '../../features/settings/users_roles_settings_screen.dart';
import '../../features/settings/users_roles_invite_screen.dart';
import '../../features/physiotherapy/screens/physiotherapy_referral_list_screen.dart';
import '../../features/physiotherapy/screens/physiotherapy_referral_detail_screen.dart';
import '../../features/physiotherapy/screens/physiotherapy_referral_form_screen.dart';
import '../../features/physiotherapy/screens/physiotherapy_session_list_screen.dart';
import '../../features/physiotherapy/screens/physiotherapy_session_detail_screen.dart';
import '../../features/physiotherapy/screens/physiotherapy_session_form_screen.dart';
import '../../features/exercises/screens/exercise_plan_list_screen.dart';
import '../../features/exercises/exercise_plan_detail_screen.dart';
import '../../features/exercises/exercise_plan_form_screen.dart';
import '../../features/surgery/surgery_note_list_screen.dart';
import '../../features/surgery/surgery_note_form_screen.dart';
import '../../features/surgery/surgery_note_detail_screen.dart';
import '../../features/surgery/surgery_note_template_list_screen.dart';
import '../../features/surgery/surgery_note_template_form_screen.dart';
import '../../features/post_op_protocols/post_op_protocol_list_screen.dart';
import '../../features/post_op_protocols/post_op_protocol_form_screen.dart';
import '../../features/post_op_protocols/post_op_protocol_detail_screen.dart';
import 'maintenance_route_guard.dart';
import '../../features/maintenance/maintenance_dashboard_screen.dart';
import '../../features/maintenance/maintenance_diagnostics_screen.dart';
import '../../features/maintenance/maintenance_auth_profile_screen.dart';
import '../../features/maintenance/maintenance_tenants_screen.dart';
import '../../features/maintenance/maintenance_tenant_form_screen.dart';
import '../../features/maintenance/maintenance_tenant_financial_features_screen.dart';
import '../../features/maintenance/maintenance_tenant_role_access_screen.dart';
import '../../core/tenant/tenant_financial_feature_gate.dart';
import '../../features/maintenance/maintenance_memberships_screen.dart';
import '../../features/maintenance/maintenance_bootstrap_wizard_screen.dart';

class AppRouter {
  static String? _authRedirect(GoRouterState state) =>
      AuthRouteGuard.redirectFor(state);

  static Widget _deny(String message) => AccessDeniedScreen(message: message);

  static String _redirectPreserveQuery(String target, GoRouterState state) {
    final uri = Uri.parse(state.location);
    if (uri.queryParameters.isEmpty) return target;
    return Uri(path: target, queryParameters: uri.queryParameters).toString();
  }

  static final GoRouter router = GoRouter(
    initialLocation: '/login',
    redirect: (context, state) => _authRedirect(state),
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/auth/update-password',
        builder: (context, state) => const UpdatePasswordScreen(),
      ),
      GoRoute(
        path: '/auth/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/invite/accept',
        builder: (context, state) {
          final membershipId = InvitationDeepLink.parseMembershipId(state.location);
          return InviteAcceptScreen(membershipId: membershipId);
        },
      ),
      GoRoute(
        path: '/session/initializing',
        builder: (context, state) => const SessionInitializingScreen(),
      ),
      GoRoute(
        path: '/account/no-access',
        builder: (context, state) {
          final reason = AccountAccessReasonParsing.fromQuery(
            Uri.parse(state.location).queryParameters['reason'],
          );
          return AccountAccessStatusScreen(reason: reason);
        },
      ),
      GoRoute(
        path: '/doctor',
        builder: (context, state) {
          if (!AuthSession.canAccessDoctorDashboard) {
            return _deny('Bu panele yalnızca doktor erişebilir.');
          }
          return const DoctorDashboardScreen();
        },
      ),
      GoRoute(
        path: '/assistant',
        builder: (context, state) {
          if (!AuthSession.canAccessAssistantDashboard) {
            return _deny('Bu panele yalnızca asistan erişebilir.');
          }
          return const AssistantDashboardScreen();
        },
      ),
      GoRoute(
        path: '/physio',
        builder: (context, state) {
          if (!AuthSession.canAccessPhysioDashboard) {
            return _deny('Bu panele yalnızca fizyoterapist erişebilir.');
          }
          return const PhysiotherapistDashboardScreen();
        },
      ),
      GoRoute(
        path: '/nurse',
        builder: (context, state) {
          if (!AuthSession.canAccessNurseDashboard) {
            return _deny('Bu panele yalnızca hemşire erişebilir.');
          }
          return const NurseDashboardScreen();
        },
      ),
      GoRoute(
        path: '/patients',
        builder: (context, state) {
          if (!AuthSession.canViewPatients) return _deny('Hasta listesine bu rol ile erişilemez.');
          return const PatientListScreen();
        },
      ),
      GoRoute(
        path: '/patients/new',
        builder: (context, state) {
          if (!AuthSession.canEditPatients) {
            return _deny('Yeni hasta kaydı bu rol ile oluşturulamaz.');
          }
          return const PatientFormScreen();
        },
      ),
      GoRoute(
        path: '/patients/:id/edit',
        builder: (context, state) {
          if (!AuthSession.canEditPatients) {
            return _deny('Hasta düzenleme bu rol ile yapılamaz.');
          }
          return PatientFormScreen(patientId: state.pathParameters['id']);
        },
      ),
      GoRoute(
        path: '/patients/:id',
        builder: (context, state) {
          if (!AuthSession.canViewPatients) return _deny('Hasta detayına bu rol ile erişilemez.');
          return PatientDetailScreen(id: state.pathParameters['id']!);
        },
      ),
      GoRoute(
        path: '/patient-timeline',
        builder: (context, state) {
          if (!AuthSession.canViewPatientTimeline) {
            return _deny('Hasta zaman çizelgesine yalnızca doktor erişebilir.');
          }
          final params = Uri.parse(state.location).queryParameters;
          return PatientTimelineScreen(patientId: params['patientId']);
        },
      ),
      GoRoute(
        path: '/patient-alerts',
        builder: (context, state) {
          if (!AuthSession.canViewPatientAlerts) {
            return _deny('Klinik uyarılara yalnızca doktor ve asistan erişebilir.');
          }
          final params = Uri.parse(state.location).queryParameters;
          return PatientAlertsScreen(patientId: params['patientId']);
        },
      ),
      GoRoute(
        path: '/patient-tags',
        builder: (context, state) {
          if (!AuthSession.canViewPatientTags) {
            return _deny('Hasta etiketlerine bu rol ile erişilemez.');
          }
          return const PatientTagListScreen();
        },
      ),
      GoRoute(
        path: '/clinic-workflow',
        builder: (context, state) {
          if (!AuthSession.canViewSettings) {
            return _deny('Klinik işleyiş ayarlarına erişim yetkiniz yok.');
          }
          return const ClinicWorkflowSettingsScreen();
        },
      ),
      GoRoute(
        path: '/staff-leave-requests',
        builder: (context, state) {
          if (!AuthSession.canRequestStaffLeave) {
            return _deny('İzin talebine erişim yetkiniz yok.');
          }
          return const StaffLeaveRequestScreen();
        },
      ),
      GoRoute(
        path: '/staff-leaves',
        builder: (context, state) {
          if (!AuthSession.canViewSettings) {
            return _deny('Personel izinlerine erişim yetkiniz yok.');
          }
          return const StaffLeaveSettingsScreen();
        },
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) {
          if (!AuthSession.canViewSettings) {
            return _deny('Ayarlar için giriş yapmanız gerekir.');
          }
          return const SettingsHubScreen();
        },
      ),
      GoRoute(
        path: '/settings/profile',
        builder: (context, state) {
          if (!AuthSession.canViewSettings) {
            return _deny('Ayarlar için giriş yapmanız gerekir.');
          }
          return const ProfileSettingsScreen();
        },
      ),
      GoRoute(
        path: '/settings/clinic',
        builder: (context, state) {
          if (!AuthSession.canViewSettings) {
            return _deny('Ayarlar için giriş yapmanız gerekir.');
          }
          return const ClinicSettingsScreen();
        },
      ),
      GoRoute(
        path: '/settings/display-region',
        builder: (context, state) {
          if (!AuthSession.canViewSettings) {
            return _deny('Ayarlar için giriş yapmanız gerekir.');
          }
          return const DisplayRegionSettingsScreen();
        },
      ),
      GoRoute(
        path: '/settings/clinic-workflow',
        builder: (context, state) {
          if (!AuthSession.canViewSettings) {
            return _deny('Ayarlar için giriş yapmanız gerekir.');
          }
          return const ClinicWorkflowSettingsScreen();
        },
      ),
      GoRoute(
        path: '/settings/clinic-workflow/staff-leaves',
        builder: (context, state) {
          if (!AuthSession.canViewSettings) {
            return _deny('Ayarlar için giriş yapmanız gerekir.');
          }
          return const StaffLeaveSettingsScreen();
        },
      ),
      GoRoute(
        path: '/settings/patient-settings',
        builder: (context, state) {
          if (!AuthSession.canViewSettings) {
            return _deny('Ayarlar için giriş yapmanız gerekir.');
          }
          return const PatientSettingsScreen();
        },
      ),
      GoRoute(
        path: '/settings/users-roles',
        builder: (context, state) {
          if (!AuthSession.canEditClinicProfile) {
            return _deny('Kullanıcılar ve roller yalnızca doktor hesabı tarafından yönetilebilir.');
          }
          return const UsersRolesSettingsScreen();
        },
        routes: [
          GoRoute(
            path: 'invite',
            builder: (context, state) {
              if (!AuthSession.canEditClinicProfile) {
                return _deny('Kullanıcı daveti yalnızca doktor hesabı tarafından gönderilebilir.');
              }
              return const UsersRolesInviteScreen();
            },
          ),
        ],
      ),
      GoRoute(
        path: '/settings/system-security',
        builder: (context, state) {
          if (!AuthSession.canViewSettings) {
            return _deny('Ayarlar için giriş yapmanız gerekir.');
          }
          return const SystemSecuritySettingsScreen();
        },
      ),
      GoRoute(
        path: '/settings/clinic-finance',
        builder: (context, state) {
          if (!clinicFinanceStatisticsVisible()) {
            return _deny('Finansal istatistiklere yalnızca klinik yönetimi erişebilir.');
          }
          return const ClinicFinanceStatisticsScreen();
        },
      ),
      GoRoute(
        path: '/settings/demo-usage',
        builder: (context, state) {
          if (!AuthSession.canViewSettings) {
            return _deny('Ayarlar için giriş yapmanız gerekir.');
          }
          return const DemoUsageSettingsScreen();
        },
      ),
      GoRoute(
        path: '/settings/subscription',
        builder: (context, state) {
          if (!AuthSession.canViewSettings) {
            return _deny('Ayarlar için giriş yapmanız gerekir.');
          }
          return const SaasSubscriptionSettingsScreen();
        },
      ),
      GoRoute(
        path: '/appointments',
        builder: (context, state) {
          if (!AuthSession.canViewAppointments) return _deny('Randevulara bu rol ile erişilemez.');
          final params = Uri.parse(state.location).queryParameters;
          return AppointmentListScreen(patientId: params['patientId']);
        },
      ),
      GoRoute(
        path: '/appointments/new',
        builder: (context, state) {
          if (!AuthSession.canBookReferralAppointments &&
              !AuthSession.canEditAppointments) {
            return _deny('Yeni randevu bu rol ile oluşturulamaz.');
          }
          final params = Uri.parse(state.location).queryParameters;
          return AppointmentFormScreen(
            patientId: params['patientId'],
            referralId: params['referralId'],
            initialTypeQuery: params['type'],
            initialDateQuery: params['date'],
          );
        },
      ),
      GoRoute(
        path: '/appointments/:id/edit',
        builder: (context, state) {
          if (!AuthSession.canEditAppointments &&
              !AuthSession.canBookReferralAppointments) {
            return _deny('Randevu düzenleme bu rol ile yapılamaz.');
          }
          return AppointmentFormScreen(
            appointmentId: state.pathParameters['id'],
          );
        },
      ),
      GoRoute(
        path: '/appointments/:id',
        builder: (context, state) {
          if (!AuthSession.canViewAppointments) return _deny('Randevu detayına bu rol ile erişilemez.');
          return AppointmentDetailScreen(id: state.pathParameters['id']!);
        },
      ),
      GoRoute(
        path: '/anamnesis',
        redirect: (context, state) =>
            _redirectPreserveQuery('/clinical-records', state),
      ),
      GoRoute(
        path: '/anamnesis/new',
        redirect: (context, state) => '/clinical-records/new',
      ),
      GoRoute(
        path: '/anamnesis/:id',
        redirect: (context, state) =>
            _redirectPreserveQuery('/clinical-records', state),
      ),
      GoRoute(
        path: '/clinical-records',
        builder: (context, state) {
          if (!AuthSession.canViewClinicalEncounters) {
            return _deny('Muayene kayıtlarına yalnızca doktor erişebilir.');
          }
          final params = Uri.parse(state.location).queryParameters;
          return ClinicalEncounterListScreen(patientId: params['patientId']);
        },
      ),
      GoRoute(
        path: '/clinical-records/new',
        builder: (context, state) {
          if (!AuthSession.canEditClinicalEncounters) {
            return _deny('Muayene kaydı oluşturmak yalnızca doktora açıktır.');
          }
          final params = Uri.parse(state.location).queryParameters;
          return ClinicalEncounterFormScreen(
            patientId: params['patientId'],
            appointmentId: params['appointmentId'],
          );
        },
      ),
      GoRoute(
        path: '/clinical-records/diagnosis-summary',
        builder: (context, state) {
          if (!AuthSession.canViewClinicalDiagnosisSummary) {
            return _deny('Tanı özetine bu rol ile erişilemez.');
          }
          final params = Uri.parse(state.location).queryParameters;
          return ClinicalDiagnosisSummaryListScreen(patientId: params['patientId']);
        },
      ),
      GoRoute(
        path: '/clinical-records/diagnosis-summary/:id',
        builder: (context, state) {
          if (!AuthSession.canViewClinicalDiagnosisSummary) {
            return _deny('Tanı özetine bu rol ile erişilemez.');
          }
          return ClinicalDiagnosisSummaryDetailScreen(id: state.pathParameters['id']!);
        },
      ),
      GoRoute(
        path: '/clinical-records/:encounterId/wizard-payment',
        builder: (context, state) {
          if (!AuthSession.canEditClinicalEncounters) {
            return _deny('Muayene sonrası ödeme yalnızca doktora açıktır.');
          }
          if (!TenantFinancialFeatureGate.encounterPaymentStepEnabled) {
            return _deny('Bu klinik için muayene sonrası ödeme adımı kapalı.');
          }
          if (!AuthSession.canEditPayments) {
            return _deny('Ödeme kaydı oluşturma yetkiniz yok.');
          }
          final params = Uri.parse(state.location).queryParameters;
          final current = int.tryParse(params['step'] ?? '') ?? 1;
          final total = int.tryParse(params['total'] ?? '') ?? 1;
          return PostEncounterPaymentStepScreen(
            encounterId: state.pathParameters['encounterId']!,
            progressCurrent: current,
            progressTotal: total,
          );
        },
      ),
      GoRoute(
        path: '/clinical-records/:id/edit',
        builder: (context, state) {
          if (!AuthSession.canEditClinicalEncounters) {
            return _deny('Muayene kaydı düzenlemek yalnızca doktora açıktır.');
          }
          return ClinicalEncounterFormScreen(encounterId: state.pathParameters['id']!);
        },
      ),
      GoRoute(
        path: '/clinical-records/:id',
        builder: (context, state) {
          if (!AuthSession.canViewClinicalEncounters) {
            return _deny('Muayene kaydı detayına yalnızca doktor erişebilir.');
          }
          return ClinicalEncounterDetailScreen(id: state.pathParameters['id']!);
        },
      ),
      GoRoute(
        path: '/examinations',
        redirect: (context, state) =>
            _redirectPreserveQuery('/clinical-records', state),
      ),
      GoRoute(
        path: '/examinations/new',
        redirect: (context, state) => '/clinical-records/new',
      ),
      GoRoute(
        path: '/examinations/:id',
        redirect: (context, state) =>
            _redirectPreserveQuery('/clinical-records', state),
      ),
      GoRoute(
        path: '/surgery-notes',
        builder: (context, state) {
          if (!AuthSession.canViewSurgeryNotes) {
            return _deny('Ameliyat / girişim notlarına yalnızca doktor erişebilir.');
          }
          final params = Uri.parse(state.location).queryParameters;
          return SurgeryNoteListScreen(patientId: params['patientId']);
        },
      ),
      GoRoute(
        path: '/surgery-notes/new',
        builder: (context, state) {
          if (!AuthSession.canEditSurgeryNotes) {
            return _deny('Ameliyat / girişim notu oluşturmak yalnızca doktora açıktır.');
          }
          final params = Uri.parse(state.location).queryParameters;
          return SurgeryNoteFormScreen(patientId: params['patientId']);
        },
      ),
      GoRoute(
        path: '/surgery-notes/:id/edit',
        builder: (context, state) {
          if (!AuthSession.canEditSurgeryNotes) {
            return _deny('Ameliyat / girişim notu düzenleme yetkiniz yok.');
          }
          return SurgeryNoteFormScreen(noteId: state.pathParameters['id']!);
        },
      ),
      GoRoute(
        path: '/surgery-notes/:id',
        builder: (context, state) {
          if (!AuthSession.canViewSurgeryNotes) {
            return _deny('Ameliyat / girişim notlarına yalnızca doktor erişebilir.');
          }
          return SurgeryNoteDetailScreen(id: state.pathParameters['id']!);
        },
      ),
      GoRoute(
        path: '/surgery-note-templates/new',
        builder: (context, state) {
          if (!AuthSession.canEditSurgeryNotes) {
            return _deny('Ameliyat notu şablonu oluşturma yetkiniz yok.');
          }
          return const SurgeryNoteTemplateFormScreen();
        },
      ),
      GoRoute(
        path: '/surgery-note-templates/:id/edit',
        builder: (context, state) {
          if (!AuthSession.canEditSurgeryNotes) {
            return _deny('Ameliyat notu şablonu düzenleme yetkiniz yok.');
          }
          return SurgeryNoteTemplateFormScreen(
            templateId: state.pathParameters['id'],
          );
        },
      ),
      GoRoute(
        path: '/surgery-note-templates',
        builder: (context, state) {
          if (!AuthSession.canEditSurgeryNotes) {
            return _deny('Ameliyat notu şablonlarına erişim yetkiniz yok.');
          }
          return const SurgeryNoteTemplateListScreen();
        },
      ),
      GoRoute(
        path: '/post-op-protocols',
        builder: (context, state) {
          if (!AuthSession.canViewPostOpProtocols) {
            return _deny('Post-op protokollere yalnızca doktor ve fizyoterapist erişebilir.');
          }
          final params = Uri.parse(state.location).queryParameters;
          return PostOpProtocolListScreen(
            patientId: params['patientId'],
            surgeryNoteId: params['surgeryNoteId'],
          );
        },
      ),
      GoRoute(
        path: '/post-op-protocols/new',
        builder: (context, state) {
          if (!AuthSession.canEditPostOpProtocols) {
            return _deny('Post-op protokol oluşturmak yalnızca doktora açıktır.');
          }
          final params = Uri.parse(state.location).queryParameters;
          return PostOpProtocolFormScreen(
            patientId: params['patientId'],
            surgeryNoteId: params['surgeryNoteId'],
          );
        },
      ),
      GoRoute(
        path: '/post-op-protocols/:id',
        builder: (context, state) {
          if (!AuthSession.canViewPostOpProtocols) {
            return _deny('Post-op protokollere yalnızca doktor ve fizyoterapist erişebilir.');
          }
          return PostOpProtocolDetailScreen(id: state.pathParameters['id']!);
        },
      ),
      GoRoute(
        path: '/diagnoses',
        redirect: (context, state) =>
            _redirectPreserveQuery('/clinical-records/diagnosis-summary', state),
      ),
      GoRoute(
        path: '/diagnoses/new',
        redirect: (context, state) => '/clinical-records/new',
      ),
      GoRoute(
        path: '/diagnoses/:id',
        redirect: (context, state) =>
            _redirectPreserveQuery('/clinical-records/diagnosis-summary', state),
      ),
      GoRoute(
        path: '/treatment-plans',
        redirect: (context, state) =>
            _redirectPreserveQuery('/clinical-records', state),
      ),
      GoRoute(
        path: '/treatment-plans/new',
        redirect: (context, state) => '/clinical-records/new',
      ),
      GoRoute(
        path: '/treatment-plans/:id',
        redirect: (context, state) =>
            _redirectPreserveQuery('/clinical-records', state),
      ),
      GoRoute(
        path: '/imaging',
        builder: (context, state) {
          if (!AuthSession.canViewImaging) {
            return _deny('Görüntüleme notlarına bu rol ile erişilemez.');
          }
          final params = Uri.parse(state.location).queryParameters;
          return ImagingListScreen(patientId: params['patientId']);
        },
      ),
      GoRoute(
        path: '/imaging/new',
        builder: (context, state) {
          if (!AuthSession.canEditImaging) {
            return _deny('Görüntüleme notu oluşturmak yalnızca doktora açıktır.');
          }
          final params = Uri.parse(state.location).queryParameters;
          return ImagingFormScreen(
            patientId: params['patientId'],
            isAssistant: params['assistant'] == 'true',
          );
        },
      ),
      GoRoute(
        path: '/imaging/:id',
        builder: (context, state) {
          if (!AuthSession.canViewImaging) {
            return _deny('Görüntüleme detayına bu rol ile erişilemez.');
          }
          return ImagingDetailScreen(id: state.pathParameters['id']!);
        },
      ),
      GoRoute(
        path: '/files',
        builder: (context, state) {
          if (!AuthSession.canViewFiles) return _deny('Dosyalara bu rol ile erişilemez.');
          final params = Uri.parse(state.location).queryParameters;
          return FileListScreen(patientId: params['patientId']);
        },
      ),
      GoRoute(
        path: '/files/upload',
        builder: (context, state) {
          if (!AuthSession.canEditFiles) {
            return _deny('Dosya yükleme yalnızca doktor ve asistan için açıktır.');
          }
          final params = Uri.parse(state.location).queryParameters;
          return FileUploadScreen(
            patientId: params['patientId'],
          );
        },
      ),
      GoRoute(
        path: '/files/:id',
        builder: (context, state) {
          if (!AuthSession.canViewFiles) return _deny('Dosya detayına bu rol ile erişilemez.');
          return FileDetailScreen(id: state.pathParameters['id']!);
        },
      ),
      GoRoute(
        path: '/radiology-orders/new',
        builder: (context, state) {
          if (!AuthSession.canEditRadiologyOrders) {
            return _deny('Radyoloji istemi oluşturma yetkiniz yok.');
          }
          final params = Uri.parse(state.location).queryParameters;
          final wizardMode =
              PostEncounterWizardNavigation.isEnabled(params);
          return RadiologyOrderFormScreen(
            patientId: params['patientId'],
            clinicalEncounterId: params['clinicalEncounterId'],
            encounterWizardMode: wizardMode,
          );
        },
      ),
      GoRoute(
        path: '/radiology-orders/:id/edit',
        builder: (context, state) {
          if (!AuthSession.canEditRadiologyOrders) {
            return _deny('Radyoloji istemi düzenleme yetkiniz yok.');
          }
          return RadiologyOrderFormScreen(orderId: state.pathParameters['id']);
        },
      ),
      GoRoute(
        path: '/radiology-orders/:id',
        builder: (context, state) {
          if (!AuthSession.canViewRadiologyOrders) {
            return _deny('Radyoloji istemlerine erişim yetkiniz yok.');
          }
          return RadiologyOrderDetailScreen(id: state.pathParameters['id']!);
        },
      ),
      GoRoute(
        path: '/radiology-orders',
        builder: (context, state) {
          if (!AuthSession.canViewRadiologyOrders) {
            return _deny('Radyoloji istemlerine erişim yetkiniz yok.');
          }
          final params = Uri.parse(state.location).queryParameters;
          return RadiologyOrderListScreen(patientId: params['patientId']);
        },
      ),
      GoRoute(
        path: '/lab-order-templates/catalog-settings',
        builder: (context, state) {
          if (!AuthSession.canManageLabOrderTemplates) {
            return _deny('Laboratuvar test listesi ayarına erişim yetkiniz yok.');
          }
          return const LabOrderCatalogSettingsScreen();
        },
      ),
      GoRoute(
        path: '/lab-order-templates/new',
        builder: (context, state) {
          if (!AuthSession.canManageLabOrderTemplates) {
            return _deny('Laboratuvar şablonu oluşturma yetkiniz yok.');
          }
          return const LabOrderTemplateFormScreen();
        },
      ),
      GoRoute(
        path: '/lab-order-templates/:id/edit',
        builder: (context, state) {
          if (!AuthSession.canManageLabOrderTemplates) {
            return _deny('Laboratuvar şablonu düzenleme yetkiniz yok.');
          }
          return LabOrderTemplateFormScreen(
            templateId: state.pathParameters['id'],
          );
        },
      ),
      GoRoute(
        path: '/lab-order-templates/:id',
        builder: (context, state) {
          if (!AuthSession.canManageLabOrderTemplates) {
            return _deny('Laboratuvar şablonlarına erişim yetkiniz yok.');
          }
          return LabOrderTemplateDetailScreen(id: state.pathParameters['id']!);
        },
      ),
      GoRoute(
        path: '/lab-order-templates',
        builder: (context, state) {
          if (!AuthSession.canManageLabOrderTemplates) {
            return _deny('Laboratuvar şablonlarına erişim yetkiniz yok.');
          }
          return const LabOrderTemplateListScreen();
        },
      ),
      GoRoute(
        path: '/lab-orders/new',
        builder: (context, state) {
          if (!AuthSession.canEditLabOrders) {
            return _deny('Laboratuvar istemi oluşturma yetkiniz yok.');
          }
          final params = Uri.parse(state.location).queryParameters;
          final wizardMode =
              PostEncounterWizardNavigation.isEnabled(params);
          return LabOrderFormScreen(
            patientId: params['patientId'],
            clinicalEncounterId: params['clinicalEncounterId'],
            templateId: params['templateId'],
            encounterWizardMode: wizardMode,
          );
        },
      ),
      GoRoute(
        path: '/lab-orders/:id/edit',
        builder: (context, state) {
          if (!AuthSession.canEditLabOrders) {
            return _deny('Laboratuvar istemi düzenleme yetkiniz yok.');
          }
          return LabOrderFormScreen(orderId: state.pathParameters['id']);
        },
      ),
      GoRoute(
        path: '/lab-orders/:id',
        builder: (context, state) {
          if (!AuthSession.canViewLabOrders) {
            return _deny('Laboratuvar istemlerine erişim yetkiniz yok.');
          }
          return LabOrderDetailScreen(id: state.pathParameters['id']!);
        },
      ),
      GoRoute(
        path: '/lab-orders',
        builder: (context, state) {
          if (!AuthSession.canViewLabOrders) {
            return _deny('Laboratuvar istemlerine erişim yetkiniz yok.');
          }
          final params = Uri.parse(state.location).queryParameters;
          return LabOrderListScreen(patientId: params['patientId']);
        },
      ),
      GoRoute(
        path: '/prescriptions/new',
        builder: (context, state) {
          if (!AuthSession.canEditPrescriptions) {
            return _deny('Reçete oluşturmak yalnızca doktora açıktır.');
          }
          final params = Uri.parse(state.location).queryParameters;
          final wizardMode =
              PostEncounterWizardNavigation.isEnabled(params);
          return PrescriptionFormScreen(
            patientId: params['patientId'],
            clinicalEncounterId: params['clinicalEncounterId'],
            encounterWizardMode: wizardMode,
          );
        },
      ),
      GoRoute(
        path: '/prescriptions/:id/edit',
        builder: (context, state) {
          if (!AuthSession.canEditPrescriptions) {
            return _deny('Reçete düzenlemek yalnızca doktora açıktır.');
          }
          return PrescriptionFormScreen(
            prescriptionId: state.pathParameters['id'],
          );
        },
      ),
      GoRoute(
        path: '/prescriptions/:id',
        builder: (context, state) {
          if (!AuthSession.canViewPrescriptions) {
            return _deny('Reçetelere bu rol ile erişilemez.');
          }
          return PrescriptionDetailScreen(id: state.pathParameters['id']!);
        },
      ),
      GoRoute(
        path: '/prescriptions',
        builder: (context, state) {
          if (!AuthSession.canViewPrescriptions) {
            return _deny('Reçetelere bu rol ile erişilemez.');
          }
          final params = Uri.parse(state.location).queryParameters;
          return PrescriptionListScreen(patientId: params['patientId']);
        },
      ),
      GoRoute(
        path: '/clinical-reports/new',
        builder: (context, state) {
          if (!AuthSession.canEditClinicalReports) {
            return _deny('Rapor oluşturmak yalnızca doktora açıktır.');
          }
          final params = Uri.parse(state.location).queryParameters;
          final wizardMode =
              PostEncounterWizardNavigation.isEnabled(params);
          return ClinicalReportFormScreen(
            patientId: params['patientId'],
            clinicalEncounterId: params['clinicalEncounterId'],
            reportType: params['reportType'],
            encounterWizardMode: wizardMode,
          );
        },
      ),
      GoRoute(
        path: '/clinical-reports/:id/edit',
        builder: (context, state) {
          if (!AuthSession.canEditClinicalReports) {
            return _deny('Rapor düzenlemek yalnızca doktora açıktır.');
          }
          return ClinicalReportFormScreen(
            reportId: state.pathParameters['id'],
          );
        },
      ),
      GoRoute(
        path: '/clinical-reports/:id',
        builder: (context, state) {
          if (!AuthSession.canViewClinicalReports) {
            return _deny('Raporlara bu rol ile erişilemez.');
          }
          return ClinicalReportDetailScreen(id: state.pathParameters['id']!);
        },
      ),
      GoRoute(
        path: '/clinical-reports',
        builder: (context, state) {
          if (!AuthSession.canViewClinicalReports) {
            return _deny('Raporlara bu rol ile erişilemez.');
          }
          final params = Uri.parse(state.location).queryParameters;
          return ClinicalReportListScreen(patientId: params['patientId']);
        },
      ),
      GoRoute(
        path: '/pdf-outputs',
        builder: (context, state) {
          if (!AuthSession.canViewPdfOutputs) {
            return _deny('PDF çıktılara bu rol ile erişilemez.');
          }
          final params = Uri.parse(state.location).queryParameters;
          return PdfOutputListScreen(patientId: params['patientId']);
        },
      ),
      GoRoute(
        path: '/pdf-outputs/new',
        builder: (context, state) {
          if (!AuthSession.canEditPdfOutputs) return _deny('PDF oluşturmak yalnızca doktora açıktır.');
          final params = Uri.parse(state.location).queryParameters;
          return PdfOutputFormScreen(
            patientId: params['patientId'],
            source: params['source'],
            sourceRecordId: params['id'],
          );
        },
      ),
      GoRoute(
        path: '/pdf-outputs/:id',
        builder: (context, state) {
          if (!AuthSession.canViewPdfOutputs) {
            return _deny('PDF detayına bu rol ile erişilemez.');
          }
          return PdfOutputDetailScreen(id: state.pathParameters['id']!);
        },
      ),
      GoRoute(
        path: '/audit-logs',
        builder: (context, state) {
          if (!AuthSession.canViewAuditLogs) return _deny('Audit loglara yalnızca doktor erişebilir.');
          final params = Uri.parse(state.location).queryParameters;
          return AuditLogListScreen(patientId: params['patientId']);
        },
      ),
      GoRoute(
        path: '/audit-logs/:id',
        builder: (context, state) {
          if (!AuthSession.canViewAuditLogs) return _deny('Audit log detayına yalnızca doktor erişebilir.');
          return AuditLogDetailScreen(id: state.pathParameters['id']!);
        },
      ),
      GoRoute(
        path: '/consent-templates/new',
        builder: (context, state) {
          if (!AuthSession.canEditClinicalEncounters) {
            return _deny('Onam şablonu oluşturmak yalnızca doktora açıktır.');
          }
          return const ConsentTemplateFormScreen();
        },
      ),
      GoRoute(
        path: '/consent-templates/:id/edit',
        builder: (context, state) {
          if (!AuthSession.canEditClinicalEncounters) {
            return _deny('Onam şablonu düzenlemek yalnızca doktora açıktır.');
          }
          return ConsentTemplateFormScreen(
            templateId: state.pathParameters['id'],
          );
        },
      ),
      GoRoute(
        path: '/consent-templates/prepare/:id',
        builder: (context, state) {
          if (!AuthSession.canViewConsentTemplates) {
            return _deny('Onam form şablonlarına bu rol ile erişilemez.');
          }
          return ConsentTemplatePrepareScreen(
            templateId: state.pathParameters['id']!,
          );
        },
      ),
      GoRoute(
        path: '/consent-templates/:id',
        builder: (context, state) {
          if (!AuthSession.canViewConsentTemplates) {
            return _deny('Onam form şablonu detayına bu rol ile erişilemez.');
          }
          return ConsentTemplateDetailScreen(id: state.pathParameters['id']!);
        },
      ),
      GoRoute(
        path: '/consent-templates',
        builder: (context, state) {
          if (!AuthSession.canViewConsentTemplates) {
            return _deny('Onam form şablonlarına bu rol ile erişilemez.');
          }
          return const ConsentTemplateListScreen();
        },
      ),
      GoRoute(
        path: '/consents',
        builder: (context, state) {
          if (!AuthSession.canViewConsents) return _deny('Onam kayıtlarına bu rol ile erişilemez.');
          final params = Uri.parse(state.location).queryParameters;
          return ConsentListScreen(patientId: params['patientId']);
        },
      ),
      GoRoute(
        path: '/consents/first-visit-wizard',
        builder: (context, state) {
          if (!AuthSession.canEditConsents) {
            return _deny('Onam sihirbazı bu rol ile kullanılamaz.');
          }
          final params = Uri.parse(state.location).queryParameters;
          final patientId = params['patientId']?.trim() ?? '';
          if (patientId.isEmpty) {
            return _deny('Hasta seçilmeden onam sihirbazı açılamaz.');
          }
          return FirstVisitConsentWizardScreen(patientId: patientId);
        },
      ),
      GoRoute(
        path: '/consents/new',
        builder: (context, state) {
          if (!AuthSession.canEditConsents) {
            return _deny('Onam oluşturmak yalnızca doktor ve asistan için açıktır.');
          }
          final params = Uri.parse(state.location).queryParameters;
          return ConsentFormScreen(
            patientId: params['patientId'],
            encounterId: params['encounterId'],
            initialConsentType: params['type'],
          );
        },
      ),
      GoRoute(
        path: '/consents/:id',
        builder: (context, state) {
          if (!AuthSession.canViewConsents) return _deny('Onam detayına bu rol ile erişilemez.');
          return ConsentDetailScreen(id: state.pathParameters['id']!);
        },
      ),
      GoRoute(
        path: '/inventory',
        builder: (context, state) {
          if (!AuthSession.canViewInventory) {
            return _deny('Stok modülüne bu rol ile erişilemez.');
          }
          return const InventoryListScreen();
        },
      ),
      GoRoute(
        path: '/inventory/new',
        builder: (context, state) {
          if (!AuthSession.canEditInventory) {
            return _deny('Stok kartı oluşturmak bu rol ile yapılamaz.');
          }
          return const InventoryFormScreen();
        },
      ),
      GoRoute(
        path: '/inventory/:id/edit',
        builder: (context, state) {
          if (!AuthSession.canEditInventory) {
            return _deny('Stok kartı düzenlemek bu rol ile yapılamaz.');
          }
          return InventoryFormScreen(inventoryId: state.pathParameters['id']);
        },
      ),
      GoRoute(
        path: '/inventory/:id',
        builder: (context, state) {
          if (!AuthSession.canViewInventory) {
            return _deny('Stok detayına bu rol ile erişilemez.');
          }
          return InventoryDetailScreen(id: state.pathParameters['id']!);
        },
      ),
      GoRoute(
        path: '/payments',
        builder: (context, state) {
          if (!AuthSession.canViewPayments) return _deny('Ödeme kayıtlarına bu rol ile erişilemez.');
          final params = Uri.parse(state.location).queryParameters;
          return PaymentListScreen(patientId: params['patientId']);
        },
      ),
      GoRoute(
        path: '/payments/new',
        builder: (context, state) {
          if (!AuthSession.canCreatePayments) {
            return _deny('Ödeme kaydı oluşturma yetkiniz yok.');
          }
          final params = Uri.parse(state.location).queryParameters;
          return PaymentFormScreen(patientId: params['patientId']);
        },
      ),
      GoRoute(
        path: '/payments/:id/edit',
        builder: (context, state) {
          if (!AuthSession.canEditPayments) {
            return _deny('Ödeme kaydı düzenleme yetkiniz yok.');
          }
          return PaymentFormScreen(paymentId: state.pathParameters['id']);
        },
      ),
      GoRoute(
        path: '/payments/:id',
        builder: (context, state) {
          if (!AuthSession.canViewPayments) return _deny('Ödeme detayına bu rol ile erişilemez.');
          return PaymentDetailScreen(id: state.pathParameters['id']!);
        },
      ),
      GoRoute(
        path: '/messages/templates/new',
        builder: (context, state) {
          if (!AuthSession.canViewMessageTemplates) {
            return _deny('Mesaj şablonu oluşturmaya yalnızca doktor erişebilir.');
          }
          return const MessageTemplateFormScreen();
        },
      ),
      GoRoute(
        path: '/messages/templates/:id/edit',
        builder: (context, state) {
          if (!AuthSession.canViewMessageTemplates) {
            return _deny('Mesaj şablonu düzenlemeye yalnızca doktor erişebilir.');
          }
          return MessageTemplateFormScreen(
            templateId: state.pathParameters['id'],
          );
        },
      ),
      GoRoute(
        path: '/messages/templates',
        builder: (context, state) {
          if (!AuthSession.canViewMessageTemplates) {
            return _deny('Mesaj şablonlarına yalnızca doktor erişebilir.');
          }
          return const MessageTemplateListScreen();
        },
      ),
      GoRoute(
        path: '/messages/sent',
        builder: (context, state) {
          if (!AuthSession.canViewMessages) return _deny('Mesaj kayıtlarına bu rol ile erişilemez.');
          final params = Uri.parse(state.location).queryParameters;
          return SentMessageListScreen(patientId: params['patientId']);
        },
      ),
      GoRoute(
        path: '/messages/send',
        builder: (context, state) {
          if (!AuthSession.canViewMessages) {
            return _deny('Mesaj gönderme yalnızca doktor ve asistan için açıktır.');
          }
          final params = Uri.parse(state.location).queryParameters;
          return MessageSendScreen(patientId: params['patientId']);
        },
      ),
      GoRoute(
        path: '/messages/sent/:id',
        builder: (context, state) {
          if (!AuthSession.canViewMessages) return _deny('Mesaj detayına bu rol ile erişilemez.');
          return SentMessageDetailScreen(id: state.pathParameters['id']!);
        },
      ),
      GoRoute(
        path: '/physiotherapy/clinical-summaries',
        builder: (context, state) {
          if (!AuthSession.canViewClinicalSummary) {
            return _deny('Klinik özetlere bu rol ile erişilemez.');
          }
          final params = Uri.parse(state.location).queryParameters;
          return PhysioClinicalSummaryListScreen(patientId: params['patientId']);
        },
      ),
      GoRoute(
        path: '/physiotherapy/clinical-summaries/:id',
        builder: (context, state) {
          if (!AuthSession.canViewClinicalSummary) {
            return _deny('Klinik özet detayına bu rol ile erişilemez.');
          }
          return PhysioClinicalSummaryDetailScreen(
            id: state.pathParameters['id']!,
          );
        },
      ),
      GoRoute(
        path: '/physiotherapy/referrals/pending',
        builder: (context, state) {
          if (!AuthSession.canViewPhysiotherapy) {
            return _deny('Fizyoterapi modülüne bu rol ile erişilemez.');
          }
          return const PhysiotherapyReferralListScreen(pendingOnly: true);
        },
      ),
      GoRoute(
        path: '/physiotherapy/referrals',
        builder: (context, state) {
          if (!AuthSession.canViewPhysiotherapy) {
            return _deny('Fizyoterapi modülüne bu rol ile erişilemez.');
          }
          final params = Uri.parse(state.location).queryParameters;
          return PhysiotherapyReferralListScreen(patientId: params['patientId']);
        },
      ),
      GoRoute(
        path: '/physiotherapy/referrals/new',
        builder: (context, state) {
          if (!AuthSession.canEditClinicalEncounters) {
            return _deny(
              'Fizyoterapi yönlendirmesi oluşturmak yalnızca doktora açıktır.',
            );
          }
          final params = Uri.parse(state.location).queryParameters;
          return PhysiotherapyReferralFormScreen(
            patientId: params['patientId'],
            clinicalEncounterId: params['clinicalEncounterId'],
          );
        },
      ),
      GoRoute(
        path: '/physiotherapy/referrals/:id',
        builder: (context, state) {
          if (!AuthSession.canViewPhysiotherapy) {
            return _deny('Fizyoterapi yönlendirme detayına bu rol ile erişilemez.');
          }
          return PhysiotherapyReferralDetailScreen(id: state.pathParameters['id']!);
        },
      ),
      GoRoute(
        path: '/physiotherapy/sessions',
        builder: (context, state) {
          if (!AuthSession.canViewPhysiotherapy) {
            return _deny('Fizyoterapi seanslarına bu rol ile erişilemez.');
          }
          final params = Uri.parse(state.location).queryParameters;
          return PhysiotherapySessionListScreen(patientId: params['patientId']);
        },
      ),
      GoRoute(
        path: '/physiotherapy/sessions/new',
        builder: (context, state) {
          if (!AuthSession.canEditPhysiotherapy) {
            return _deny('Seans notu oluşturmak yalnızca doktor ve fizyoterapist için açıktır.');
          }
          final params = Uri.parse(state.location).queryParameters;
          return PhysiotherapySessionFormScreen(
            patientId: params['patientId'],
            referralId: params['referralId'],
          );
        },
      ),
      GoRoute(
        path: '/physiotherapy/sessions/:id',
        builder: (context, state) {
          if (!AuthSession.canViewPhysiotherapy) {
            return _deny('Fizyoterapi seans detayına bu rol ile erişilemez.');
          }
          return PhysiotherapySessionDetailScreen(id: state.pathParameters['id']!);
        },
      ),
      GoRoute(
        path: '/exercise-plans',
        builder: (context, state) {
          if (!AuthSession.canViewExercisePlans) {
            return _deny('Egzersiz programlarına bu rol ile erişilemez.');
          }
          final params = Uri.parse(state.location).queryParameters;
          final approvedRaw = params['approvedByDoctor'];
          bool? initialApproved;
          if (approvedRaw == 'true') {
            initialApproved = true;
          } else if (approvedRaw == 'false') {
            initialApproved = false;
          }
          return ExercisePlanListScreen(
            patientId: params['patientId'],
            initialApprovedByDoctor: initialApproved,
          );
        },
      ),
      GoRoute(
        path: '/exercise-plans/new',
        builder: (context, state) {
          if (!AuthSession.canEditExercisePlans) {
            return _deny('Egzersiz programı oluşturmak bu rol için kapalıdır.');
          }
          final params = Uri.parse(state.location).queryParameters;
          return ExercisePlanFormScreen(
            patientId: params['patientId'],
            referralId: params['referralId'],
          );
        },
      ),
      GoRoute(
        path: '/exercise-plans/:id',
        builder: (context, state) {
          if (!AuthSession.canViewExercisePlans) {
            return _deny('Egzersiz programı detayına bu rol ile erişilemez.');
          }
          return ExercisePlanDetailScreen(id: state.pathParameters['id']!);
        },
      ),
      ..._maintenanceRoutes,
    ],
  );

  static List<RouteBase> get _maintenanceRoutes {
    if (!MaintenanceRouteGuard.routesShouldRegister) {
      return const [];
    }
    return [
      GoRoute(
        path: '/maintenance',
        builder: (context, state) => const MaintenanceDashboardScreen(),
      ),
      GoRoute(
        path: '/maintenance/diagnostics',
        builder: (context, state) => const MaintenanceDiagnosticsScreen(),
      ),
      GoRoute(
        path: '/maintenance/auth-profile',
        builder: (context, state) => const MaintenanceAuthProfileScreen(),
      ),
      GoRoute(
        path: '/maintenance/tenants/new',
        builder: (context, state) => const MaintenanceTenantFormScreen(),
      ),
      GoRoute(
        path: '/maintenance/tenants/:tenantId/role-access',
        builder: (context, state) {
          final qp = Uri.parse(state.location).queryParameters;
          return MaintenanceTenantRoleAccessScreen(
            tenantId: state.pathParameters['tenantId']!,
            tenantName: qp['tenantName'] ?? 'Klinik',
          );
        },
      ),
      GoRoute(
        path: '/maintenance/tenants/:tenantId/financial',
        builder: (context, state) {
          final qp = Uri.parse(state.location).queryParameters;
          return MaintenanceTenantFinancialFeaturesScreen(
            tenantId: state.pathParameters['tenantId']!,
            tenantName: qp['tenantName'] ?? 'Klinik',
          );
        },
      ),
      GoRoute(
        path: '/maintenance/tenants',
        builder: (context, state) => const MaintenanceTenantsScreen(),
      ),
      GoRoute(
        path: '/maintenance/bootstrap/new',
        builder: (context, state) {
          final qp = Uri.parse(state.location).queryParameters;
          return MaintenanceBootstrapWizardScreen(
            initialTenantId: qp['tenantId'],
            initialTenantName: qp['tenantName'],
          );
        },
      ),
      GoRoute(
        path: '/maintenance/memberships',
        builder: (context, state) => const MaintenanceMembershipsScreen(),
      ),
      GoRoute(
        path: '/maintenance/memberships/new',
        builder: (context, state) => const MaintenanceMembershipFormScreen(),
      ),
      GoRoute(
        path: '/maintenance/memberships/:id',
        builder: (context, state) => MaintenanceMembershipDetailScreen(
          membershipId: state.pathParameters['id']!,
        ),
      ),
    ];
  }
}
