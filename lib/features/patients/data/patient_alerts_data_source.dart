import '../../../core/auth/auth_session.dart';
import '../../../core/data/repository_registry.dart';
import '../../clinical_encounter/models/clinical_encounter.dart';
import '../../consents/models/consent_record.dart';
import '../../payments/data/payment_outstanding_alerts_data_source.dart';
import '../../payments/widgets/payment_ui_helpers.dart';
import '../models/patient_alert.dart';
import 'patient_alerts_load_result.dart';

/// Operasyonel kaynaklardan türetilmiş hasta uyarıları — mock liste yok.
abstract final class PatientAlertsDataSource {
  static const _controlSoonDays = 14;

  static Future<PatientAlertsLoadResult> load() async {
    final alerts = <PatientAlert>[];
    var partialError = false;

    partialError = await _appendPaymentAlerts(alerts) || partialError;
    partialError = await _appendConsentAlerts(alerts) || partialError;
    partialError = await _appendControlDateAlerts(alerts) || partialError;
    partialError = await _appendPhysioReferralAlerts(alerts) || partialError;

    alerts.sort(_compareAlerts);

    return PatientAlertsLoadResult(
      alerts: alerts,
      isPartialError: partialError,
    );
  }

  static int _compareAlerts(PatientAlert a, PatientAlert b) {
    final severity = b.severity.index.compareTo(a.severity.index);
    if (severity != 0) return severity;
    return b.createdAt.compareTo(a.createdAt);
  }

  static Future<bool> _appendPaymentAlerts(List<PatientAlert> out) async {
    if (!AuthSession.canViewPayments) return false;

    try {
      final paymentAlerts =
          await PaymentOutstandingAlertsDataSource.loadAlerts();
      for (final alert in paymentAlerts) {
        out.add(
          PatientAlert(
            id: 'payment:${alert.patientId}',
            patientId: alert.patientId,
            patientName: alert.patientName,
            createdAt: alert.oldestUnpaidDate,
            alertType: PatientAlertType.odemeBekliyor,
            severity: alert.totalRemaining > 5000
                ? AlertSeverity.yuksek
                : AlertSeverity.orta,
            title: 'Açık bakiye',
            description:
                '${formatPaymentAmount(alert.totalRemaining)} · '
                '${alert.openRecordCount} açık kayıt',
            dueDate: alert.oldestUnpaidDate,
            relatedModule: 'Ödeme / Tahsilat',
            createdBy: 'Sistem',
            actionRoute: '/payments?patientId=${alert.patientId}',
          ),
        );
      }
      return false;
    } catch (_) {
      return true;
    }
  }

  static Future<bool> _appendConsentAlerts(List<PatientAlert> out) async {
    if (!AuthSession.canViewConsents) return false;

    try {
      final records = await RepositoryRegistry.consentsAsync.getAll();
      for (final record in records) {
        if (record.status != ConsentStatus.bekliyor) continue;
        out.add(
          PatientAlert(
            id: 'consent:${record.id}',
            patientId: record.patientId,
            patientName: record.patientName,
            createdAt: record.createdAt,
            alertType: PatientAlertType.eksikOnam,
            severity: AlertSeverity.orta,
            title: 'Bekleyen onam',
            description: _consentTypeLabel(record.consentType),
            dueDate: record.expiresAt,
            relatedModule: 'KVKK / Onam',
            createdBy: record.recordedBy,
            actionRoute: '/consents?patientId=${record.patientId}',
          ),
        );
      }
      return false;
    } catch (_) {
      return true;
    }
  }

  static Future<bool> _appendControlDateAlerts(List<PatientAlert> out) async {
    if (!AuthSession.canViewClinicalEncounters) return false;

    try {
      final encounters = await RepositoryRegistry.clinicalEncountersAsync
          .getAll();
      final latestByPatient = <String, ClinicalEncounter>{};
      for (final encounter in encounters) {
        if (encounter.controlDate == null) continue;
        final existing = latestByPatient[encounter.patientId];
        if (existing == null ||
            encounter.controlDate!.isAfter(existing.controlDate!)) {
          latestByPatient[encounter.patientId] = encounter;
        }
      }

      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);

      for (final encounter in latestByPatient.values) {
        final control = encounter.controlDate!.toLocal();
        final controlDate =
            DateTime(control.year, control.month, control.day);
        final days = controlDate.difference(todayDate).inDays;
        if (days > _controlSoonDays) continue;

        final overdue = days < 0;
        out.add(
          PatientAlert(
            id: 'control:${encounter.id}',
            patientId: encounter.patientId,
            patientName: encounter.patientName,
            createdAt: encounter.createdAt,
            alertType: overdue
                ? PatientAlertType.kontrolGecikmis
                : PatientAlertType.kontrolTarihiYaklasiyor,
            severity: overdue ? AlertSeverity.yuksek : AlertSeverity.orta,
            title: overdue ? 'Kontrol gecikmiş' : 'Kontrol tarihi yaklaşıyor',
            description: overdue
                ? '${-days} gün gecikme'
                : days == 0
                    ? 'Bugün'
                    : '$days gün kaldı',
            dueDate: controlDate,
            relatedModule: 'Muayene',
            createdBy: encounter.doctorName,
            actionRoute: '/clinical-records/${encounter.id}',
          ),
        );
      }
      return false;
    } catch (_) {
      return true;
    }
  }

  static Future<bool> _appendPhysioReferralAlerts(List<PatientAlert> out) async {
    if (!AuthSession.canViewPhysiotherapy) return false;

    try {
      final referrals =
          await RepositoryRegistry.physiotherapyReferralsAsync.getAll();
      for (final referral in referrals) {
        if (!referral.isPendingPhysioAction) continue;
        out.add(
          PatientAlert(
            id: 'ftr:${referral.id}',
            patientId: referral.patientId,
            patientName: referral.patientName,
            createdAt: referral.referredAt,
            alertType: PatientAlertType.fizyoterapistNotuBekleniyor,
            severity: AlertSeverity.orta,
            title: 'FTR yönlendirme bekliyor',
            description: referral.diagnosisSummary.trim().isEmpty
                ? 'Yeni yönlendirme aksiyonu gerekli'
                : referral.diagnosisSummary,
            dueDate: referral.plannedStartDate,
            relatedModule: 'Rehabilitasyon',
            createdBy: referral.referredBy,
            actionRoute:
                '/physiotherapy/referrals?patientId=${referral.patientId}',
          ),
        );
      }
      return false;
    } catch (_) {
      return true;
    }
  }

  static String _consentTypeLabel(ConsentType type) {
    switch (type) {
      case ConsentType.kvkkAydinlatma:
        return 'KVKK aydınlatma';
      case ConsentType.acikRiza:
        return 'Açık rıza';
      case ConsentType.whatsappIzin:
        return 'WhatsApp izni';
      case ConsentType.smsIzin:
        return 'SMS izni';
      case ConsentType.emailIzin:
        return 'E-posta izni';
      case ConsentType.fizyoterapistPaylasim:
        return 'Fizyoterapist paylaşım';
      case ConsentType.fotoVideoIzin:
        return 'Foto / video izni';
      case ConsentType.ameliyatOnami:
        return 'Ameliyat onamı';
    }
  }
}
