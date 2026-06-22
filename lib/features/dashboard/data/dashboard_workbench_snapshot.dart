import '../../appointments/models/appointment.dart';

/// Dashboard workbench — tek yükleme anındaki özet veri.
class DashboardWorkbenchSnapshot {
  final List<Appointment> todayAppointments;
  final int? todayAppointmentCount;
  final int? pendingAppointmentCount;
  final int? todayClinicalEncounterCount;
  final int? lowStockCount;
  final int? expiringSoonCount;
  final int? expiredStockCount;
  final int? pendingConsentCount;
  final int? unreadPaymentNotificationCount;
  final int? todayPdfOutputCount;
  final int? newPhysiotherapyReferralCount;
  final bool appointmentsUnavailable;
  final bool clinicalEncountersUnavailable;
  final bool pdfOutputsUnavailable;
  final bool inventoryUnavailable;
  final bool physiotherapyReferralsUnavailable;

  const DashboardWorkbenchSnapshot({
    this.todayAppointments = const [],
    this.todayAppointmentCount,
    this.pendingAppointmentCount,
    this.todayClinicalEncounterCount,
    this.lowStockCount,
    this.expiringSoonCount,
    this.expiredStockCount,
    this.pendingConsentCount,
    this.unreadPaymentNotificationCount,
    this.todayPdfOutputCount,
    this.newPhysiotherapyReferralCount,
    this.appointmentsUnavailable = false,
    this.clinicalEncountersUnavailable = false,
    this.pdfOutputsUnavailable = false,
    this.inventoryUnavailable = false,
    this.physiotherapyReferralsUnavailable = false,
  });

  static const int schedulePreviewMax = 7;

  List<Appointment> get schedulePreview {
    final sorted = List<Appointment>.from(todayAppointments)
      ..sort((a, b) => a.appointmentDateTime.compareTo(b.appointmentDateTime));
    if (sorted.length <= schedulePreviewMax) return sorted;
    return sorted.sublist(0, schedulePreviewMax);
  }
}
