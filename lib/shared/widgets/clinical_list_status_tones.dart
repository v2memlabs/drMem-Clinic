import 'package:flutter/material.dart';

import '../../features/appointments/models/appointment.dart';
import '../../features/clinical_encounter/models/clinical_encounter.dart';
import '../../features/consents/models/consent_record.dart';
import '../../features/inventory/data/inventory_repository.dart';
import '../../features/inventory/models/inventory_item.dart';
import '../../features/payments/models/payment_record.dart';
import '../../features/pdf_outputs/models/pdf_output.dart';
import '../../features/post_op_protocols/models/post_op_protocol.dart';
import 'status_chip.dart';

/// Liste satırları — klinik/operasyonel anlam için sakin semantic tonlar.
abstract final class ClinicalListStatusTones {
  static StatusChipTone appointmentStatus(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.iptal:
      case AppointmentStatus.gelmedi:
        return StatusChipTone.danger;
      case AppointmentStatus.geldi:
        return StatusChipTone.success;
      case AppointmentStatus.planlandi:
      case AppointmentStatus.ertelendi:
        return StatusChipTone.warning;
    }
  }

  static StatusChipTone clinicalEncounterStatus(ClinicalEncounterStatus status) {
    switch (status) {
      case ClinicalEncounterStatus.taslak:
        return StatusChipTone.neutral;
      case ClinicalEncounterStatus.tamamlandi:
        return StatusChipTone.success;
      case ClinicalEncounterStatus.kontrolPlanlandi:
      case ClinicalEncounterStatus.ameliyatPlanlandi:
        return StatusChipTone.warning;
      case ClinicalEncounterStatus.fizyoterapiyeYonlendirildi:
        return StatusChipTone.info;
    }
  }

  /// Liste satırında status chip yalnızca kritik/istisnai durumlarda.
  static bool shouldShowAppointmentStatusChip(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.gelmedi:
      case AppointmentStatus.iptal:
      case AppointmentStatus.ertelendi:
        return true;
      case AppointmentStatus.planlandi:
      case AppointmentStatus.geldi:
        return false;
    }
  }

  static bool shouldShowClinicalEncounterStatusChip(
    ClinicalEncounterStatus status,
  ) {
    switch (status) {
      case ClinicalEncounterStatus.taslak:
      case ClinicalEncounterStatus.kontrolPlanlandi:
      case ClinicalEncounterStatus.ameliyatPlanlandi:
        return true;
      case ClinicalEncounterStatus.tamamlandi:
      case ClinicalEncounterStatus.fizyoterapiyeYonlendirildi:
        return false;
    }
  }

  static StatusChipTone paymentStatus(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.odendi:
        return StatusChipTone.success;
      case PaymentStatus.kismi_odendi:
      case PaymentStatus.bekliyor:
        return StatusChipTone.warning;
      case PaymentStatus.iptal:
      case PaymentStatus.iade:
        return StatusChipTone.danger;
    }
  }

  static bool shouldShowPaymentStatusChip(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.bekliyor:
      case PaymentStatus.kismi_odendi:
      case PaymentStatus.iptal:
      case PaymentStatus.iade:
        return true;
      case PaymentStatus.odendi:
        return false;
    }
  }

  static StatusChipTone consentStatus(ConsentStatus status) {
    switch (status) {
      case ConsentStatus.alindi:
        return StatusChipTone.success;
      case ConsentStatus.bekliyor:
      case ConsentStatus.suresiDoldu:
        return StatusChipTone.warning;
      case ConsentStatus.reddedildi:
      case ConsentStatus.iptalEdildi:
        return StatusChipTone.danger;
    }
  }

  static bool shouldShowConsentStatusChip(ConsentStatus status) {
    switch (status) {
      case ConsentStatus.bekliyor:
      case ConsentStatus.reddedildi:
      case ConsentStatus.iptalEdildi:
      case ConsentStatus.suresiDoldu:
        return true;
      case ConsentStatus.alindi:
        return false;
    }
  }

  /// Stok uyarı tonu — uyarı yoksa null marker.
  static StatusChipTone? inventoryAlertTone(InventoryItem item) {
    if (InventoryRepository.isExpired(item)) {
      return StatusChipTone.danger;
    }
    if (InventoryRepository.isLowStock(item) ||
        InventoryRepository.isExpiringSoon(item)) {
      return StatusChipTone.warning;
    }
    return null;
  }

  static bool shouldShowInventoryAlertChip(InventoryItem item) {
    return inventoryAlertTone(item) != null;
  }

  static StatusChipTone pdfStatus(PdfStatus status) {
    switch (status) {
      case PdfStatus.taslak:
        return StatusChipTone.neutral;
      case PdfStatus.hazirlandi:
        return StatusChipTone.info;
      case PdfStatus.hastayaVerildi:
      case PdfStatus.gonderildi:
        return StatusChipTone.success;
      case PdfStatus.iptal:
        return StatusChipTone.danger;
    }
  }

  static bool shouldShowPdfStatusChip(PdfStatus status) {
    switch (status) {
      case PdfStatus.taslak:
      case PdfStatus.iptal:
        return true;
      case PdfStatus.hazirlandi:
      case PdfStatus.hastayaVerildi:
      case PdfStatus.gonderildi:
        return false;
    }
  }

  static StatusChipTone inventoryAlertChipTone(InventoryItem item) {
    return inventoryAlertTone(item) ?? StatusChipTone.neutral;
  }

  static StatusChipTone postOpProtocolStatus(PostOpProtocolStatus status) {
    switch (status) {
      case PostOpProtocolStatus.taslak:
        return StatusChipTone.neutral;
      case PostOpProtocolStatus.aktif:
        return StatusChipTone.info;
      case PostOpProtocolStatus.hastayaVerildi:
      case PostOpProtocolStatus.tamamlandi:
        return StatusChipTone.success;
      case PostOpProtocolStatus.fizyoterapistlePaylasildi:
        return StatusChipTone.info;
      case PostOpProtocolStatus.guncellenecek:
        return StatusChipTone.warning;
    }
  }

  static bool shouldShowPostOpProtocolStatusChip(PostOpProtocolStatus status) {
    switch (status) {
      case PostOpProtocolStatus.taslak:
      case PostOpProtocolStatus.guncellenecek:
        return true;
      case PostOpProtocolStatus.aktif:
      case PostOpProtocolStatus.hastayaVerildi:
      case PostOpProtocolStatus.fizyoterapistlePaylasildi:
      case PostOpProtocolStatus.tamamlandi:
        return false;
    }
  }

  /// Küçük durum noktası — satırı domine etmez.
  static Color? markerColorForTone(StatusChipTone tone) {
    switch (tone) {
      case StatusChipTone.danger:
        return const Color(0xFFC62828);
      case StatusChipTone.success:
        return const Color(0xFF2E7D32);
      case StatusChipTone.warning:
        return const Color(0xFFF9A825);
      case StatusChipTone.info:
        return const Color(0xFF1565C0);
      case StatusChipTone.neutral:
        return null;
    }
  }
}
