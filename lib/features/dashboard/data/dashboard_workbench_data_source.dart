import '../../../core/auth/auth_session.dart';
import '../../../core/constants/app_roles.dart';
import '../../../core/data/repository_registry.dart';
import '../../../core/tenant/tenant_financial_feature_gate.dart';
import '../../appointments/data/appointment_repository_failure.dart';
import '../../appointments/models/appointment.dart';
import '../../clinical_encounter/data/clinical_encounter_repository_failure.dart';
import '../../clinical_encounter/data/supabase_clinical_encounter_repository.dart';
import '../../consents/data/consent_repository_failure.dart';
import '../../inventory/data/inventory_repository_failure.dart';
import '../../pdf_outputs/data/pdf_output_repository_failure.dart';
import '../../pdf_outputs/data/supabase_pdf_output_repository.dart';
import '../../payments/data/payment_notification_data_source.dart';
import '../../physiotherapy/data/physiotherapy_referral_repository_failure.dart';
import '../../physiotherapy/data/supabase_physiotherapy_referral_repository.dart';
import '../../physiotherapy/models/physiotherapy_referral.dart';
import 'dashboard_workbench_snapshot.dart';

enum DashboardWorkbenchProfile {
  doctor,
  assistant,
  physiotherapist,
  nurse,
}

/// Dashboard özet verisi — [RepositoryRegistry] async provider hattı.
abstract final class DashboardWorkbenchDataSource {
  static Future<DashboardWorkbenchSnapshot> load(
    DashboardWorkbenchProfile profile,
  ) async {
    final appointmentPart = await _loadAppointments();
    final clinicalCount = profile == DashboardWorkbenchProfile.doctor
        ? await _loadTodayClinicalEncounterCount()
        : null;
    final nurseInventory = profile == DashboardWorkbenchProfile.nurse
        ? await _loadNurseInventoryCounts()
        : null;
    final assistantOps = profile == DashboardWorkbenchProfile.assistant
        ? await _loadAssistantOperationalCounts()
        : null;
    final pendingConsents = AuthSession.canViewConsents
        ? await _loadPendingConsentCount()
        : null;
    final pdfCount = profile == DashboardWorkbenchProfile.doctor &&
            AuthSession.canViewPdfOutputs
        ? await _loadTodayPdfOutputCount()
        : null;
    final physioReferrals = profile == DashboardWorkbenchProfile.physiotherapist &&
            AuthSession.canViewPhysiotherapy
        ? await _loadNewPhysiotherapyReferralCount()
        : null;

    return DashboardWorkbenchSnapshot(
      todayAppointments: appointmentPart.appointments,
      todayAppointmentCount: appointmentPart.count,
      pendingAppointmentCount: appointmentPart.pending,
      todayClinicalEncounterCount: clinicalCount?.count,
      clinicalEncountersUnavailable: clinicalCount?.unavailable ?? false,
      appointmentsUnavailable: appointmentPart.unavailable,
      lowStockCount: nurseInventory?.low,
      expiringSoonCount: nurseInventory?.expiring,
      expiredStockCount: nurseInventory?.expired,
      inventoryUnavailable: nurseInventory?.unavailable ?? false,
      pendingConsentCount: pendingConsents,
      unreadPaymentNotificationCount: assistantOps?.unreadPaymentNotifications,
      todayPdfOutputCount: pdfCount?.count,
      pdfOutputsUnavailable: pdfCount?.unavailable ?? false,
      newPhysiotherapyReferralCount: physioReferrals?.count,
      physiotherapyReferralsUnavailable: physioReferrals?.unavailable ?? false,
    );
  }

  static Future<_AppointmentPart> _loadAppointments() async {
    if (!AuthSession.canViewAppointments) {
      return const _AppointmentPart(
        appointments: [],
        count: 0,
        pending: 0,
      );
    }

    try {
      final repo = RepositoryRegistry.appointmentsAsync;
      final today = await repo.getToday();
      final pending = today
          .where((a) => a.status == AppointmentStatus.planlandi)
          .length;
      return _AppointmentPart(
        appointments: today,
        count: today.length,
        pending: pending,
      );
    } on AppointmentRepositoryException catch (e) {
      if (_isSoftAppointmentFailure(e.reason)) {
        return const _AppointmentPart(
          appointments: [],
          unavailable: true,
        );
      }
      return const _AppointmentPart(
        appointments: [],
        count: 0,
        pending: 0,
      );
    } catch (_) {
      return const _AppointmentPart(
        appointments: [],
        unavailable: true,
      );
    }
  }

  static bool _isSoftAppointmentFailure(AppointmentRepositoryFailure reason) {
    return reason == AppointmentRepositoryFailure.notConfigured ||
        reason == AppointmentRepositoryFailure.noActiveTenant ||
        reason == AppointmentRepositoryFailure.network;
  }

  static Future<_ClinicalCountPart?> _loadTodayClinicalEncounterCount() async {
    if (!AuthSession.canViewClinicalEncounters) {
      return null;
    }

    try {
      final repo = RepositoryRegistry.clinicalEncountersAsync;
      if (RepositoryRegistry.usesRemoteClinicalEncounters &&
          repo is SupabaseClinicalEncounterRepository) {
        return _ClinicalCountPart(count: await repo.countToday());
      }
      final list = await repo.getAll();
      final now = DateTime.now();
      final count =
          list.where((e) => _isSameCalendarDay(e.createdAt, now)).length;
      return _ClinicalCountPart(count: count);
    } on ClinicalEncounterRepositoryException catch (e) {
      if (_isSoftClinicalFailure(e.reason)) {
        return const _ClinicalCountPart(unavailable: true);
      }
      return const _ClinicalCountPart(count: 0);
    } catch (_) {
      return const _ClinicalCountPart(unavailable: true);
    }
  }

  static bool _isSoftClinicalFailure(ClinicalEncounterRepositoryFailure reason) {
    return reason == ClinicalEncounterRepositoryFailure.notConfigured ||
        reason == ClinicalEncounterRepositoryFailure.noActiveTenant ||
        reason == ClinicalEncounterRepositoryFailure.network ||
        reason == ClinicalEncounterRepositoryFailure.forbidden;
  }

  static Future<_NurseInventoryPart> _loadNurseInventoryCounts() async {
    if (!AuthSession.canViewInventory) {
      return const _NurseInventoryPart();
    }

    try {
      final repo = RepositoryRegistry.inventoryAsync;
      return _NurseInventoryPart(
        low: await repo.countLowStock(),
        expiring: await repo.countExpiringSoon(),
        expired: await repo.countExpired(),
      );
    } on InventoryRepositoryException catch (e) {
      if (_isSoftInventoryFailure(e.reason)) {
        return const _NurseInventoryPart(unavailable: true);
      }
      return const _NurseInventoryPart(low: 0, expiring: 0, expired: 0);
    } catch (_) {
      return const _NurseInventoryPart(unavailable: true);
    }
  }

  static bool _isSoftInventoryFailure(InventoryRepositoryFailure reason) {
    return reason == InventoryRepositoryFailure.notConfigured ||
        reason == InventoryRepositoryFailure.noActiveTenant ||
        reason == InventoryRepositoryFailure.network ||
        reason == InventoryRepositoryFailure.forbidden;
  }

  static Future<int?> _loadPendingConsentCount() async {
    try {
      return await RepositoryRegistry.consentsAsync.countPending();
    } on ConsentRepositoryException catch (e) {
      return _isSoftConsentFailure(e.reason) ? 0 : 0;
    } catch (_) {
      return 0;
    }
  }

  static Future<_AssistantOpsPart> _loadAssistantOperationalCounts() async {
    int? unreadPayments;
    if (TenantFinancialFeatureGate.assistantFinanceNotificationsEnabled &&
        AuthSession.currentUser?.role == AppRoles.assistant) {
      unreadPayments = await PaymentNotificationDataSource.unreadCount();
    }

    return _AssistantOpsPart(
      unreadPaymentNotifications: unreadPayments,
    );
  }

  static bool _isSoftConsentFailure(ConsentRepositoryFailure reason) {
    return reason == ConsentRepositoryFailure.notConfigured ||
        reason == ConsentRepositoryFailure.noActiveTenant ||
        reason == ConsentRepositoryFailure.network ||
        reason == ConsentRepositoryFailure.forbidden;
  }

  static Future<_PdfCountPart?> _loadTodayPdfOutputCount() async {
    if (!AuthSession.canViewPdfOutputs) {
      return null;
    }

    try {
      final repo = RepositoryRegistry.pdfOutputsAsync;
      if (RepositoryRegistry.usesRemotePdfOutputs &&
          repo is SupabasePdfOutputRepository) {
        return _PdfCountPart(count: await repo.countToday());
      }
      final list = await repo.getAll();
      final now = DateTime.now();
      final count =
          list.where((p) => _isSameCalendarDay(p.createdAt, now)).length;
      return _PdfCountPart(count: count);
    } on PdfOutputRepositoryException catch (e) {
      if (_isSoftPdfFailure(e.reason)) {
        return const _PdfCountPart(unavailable: true);
      }
      return const _PdfCountPart(count: 0);
    } catch (_) {
      return const _PdfCountPart(unavailable: true);
    }
  }

  static bool _isSoftPdfFailure(PdfOutputRepositoryFailure reason) {
    return reason == PdfOutputRepositoryFailure.notConfigured ||
        reason == PdfOutputRepositoryFailure.noActiveTenant ||
        reason == PdfOutputRepositoryFailure.network ||
        reason == PdfOutputRepositoryFailure.forbidden;
  }

  static Future<_PhysioReferralCountPart>
      _loadNewPhysiotherapyReferralCount() async {
    if (!AuthSession.canViewPhysiotherapy) {
      return const _PhysioReferralCountPart();
    }

    try {
      final repo = RepositoryRegistry.physiotherapyReferralsAsync;
      if (RepositoryRegistry.usesRemotePhysiotherapyReferrals &&
          repo is SupabasePhysiotherapyReferralRepository) {
        return _PhysioReferralCountPart(
          count: await repo.countPendingForAssignedPhysiotherapist(),
        );
      }
      final list = await repo.getFiltered(statusEnumFilter: ReferralStatus.yeni);
      final pending = list.where((r) => r.isPendingPhysioAction).length;
      return _PhysioReferralCountPart(count: pending);
    } on PhysiotherapyReferralRepositoryException catch (e) {
      if (_isSoftReferralFailure(e.reason)) {
        return const _PhysioReferralCountPart(unavailable: true);
      }
      return const _PhysioReferralCountPart(count: 0);
    } catch (_) {
      return const _PhysioReferralCountPart(unavailable: true);
    }
  }

  static bool _isSoftReferralFailure(
    PhysiotherapyReferralRepositoryFailure reason,
  ) {
    return reason == PhysiotherapyReferralRepositoryFailure.notConfigured ||
        reason == PhysiotherapyReferralRepositoryFailure.noActiveTenant ||
        reason == PhysiotherapyReferralRepositoryFailure.network ||
        reason == PhysiotherapyReferralRepositoryFailure.forbidden;
  }

  static bool _isSameCalendarDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _AppointmentPart {
  final List<Appointment> appointments;
  final int? count;
  final int? pending;
  final bool unavailable;

  const _AppointmentPart({
    this.appointments = const [],
    this.count,
    this.pending,
    this.unavailable = false,
  });
}

class _ClinicalCountPart {
  final int? count;
  final bool unavailable;

  const _ClinicalCountPart({this.count, this.unavailable = false});
}

class _NurseInventoryPart {
  final int? low;
  final int? expiring;
  final int? expired;
  final bool unavailable;

  const _NurseInventoryPart({
    this.low,
    this.expiring,
    this.expired,
    this.unavailable = false,
  });
}

class _AssistantOpsPart {
  final int? unreadPaymentNotifications;

  const _AssistantOpsPart({
    this.unreadPaymentNotifications,
  });
}

class _PdfCountPart {
  final int? count;
  final bool unavailable;

  const _PdfCountPart({this.count, this.unavailable = false});
}

class _PhysioReferralCountPart {
  final int? count;
  final bool unavailable;

  const _PhysioReferralCountPart({this.count, this.unavailable = false});
}
