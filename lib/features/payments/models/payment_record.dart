// ignore_for_file: constant_identifier_names

import 'payment_rehab_billing_mode.dart';
import 'payment_source_kind.dart';

enum ServiceType {
  muayene,
  kontrol,
  enjeksiyon_girisim,
  ameliyat_girisim_notu,
  fizyoterapi_seansi,
  rehabilitasyon,
  rapor_belge,
  diger,
}

enum PaymentMethod { nakit, kredi_karti, havale_eft, karma, belirtilmedi }

enum PaymentStatus { odendi, kismi_odendi, bekliyor, iptal, iade }

enum InvoiceStatus { kesildi, bekliyor, gerekmiyor, belirtilmedi }

class PaymentRecord {
  final String id;
  final String patientId;
  final String patientName;
  final String? patientFileNumber;
  final DateTime createdAt;
  final ServiceType serviceType;
  final double totalAmount;
  final double paidAmount;
  final PaymentMethod paymentMethod;
  final PaymentStatus paymentStatus;
  final InvoiceStatus invoiceStatus;
  final DateTime transactionDate;
  final String recordedBy;
  final String notes;
  final String? clinicalEncounterId;
  final PaymentRehabBillingMode? rehabBillingMode;
  final int? packageSessionCount;
  final PaymentSourceKind sourceKind;
  final String? createdByUserId;

  PaymentRecord({
    required this.id,
    required this.patientId,
    required this.patientName,
    this.patientFileNumber,
    required this.createdAt,
    required this.serviceType,
    required this.totalAmount,
    required this.paidAmount,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.invoiceStatus,
    required this.transactionDate,
    required this.recordedBy,
    this.notes = '',
    this.clinicalEncounterId,
    this.rehabBillingMode,
    this.packageSessionCount,
    this.sourceKind = PaymentSourceKind.manual,
    this.createdByUserId,
  });

  double get remainingAmount =>
      (totalAmount - paidAmount).clamp(0, double.infinity);

  bool get isRehabilitation => serviceType == ServiceType.rehabilitasyon;

  String get serviceTypeLabel {
    switch (serviceType) {
      case ServiceType.muayene:
        return 'Muayene';
      case ServiceType.kontrol:
        return 'Kontrol';
      case ServiceType.enjeksiyon_girisim:
        return 'Enjeksiyon / Girişim';
      case ServiceType.ameliyat_girisim_notu:
        return 'Ameliyat / Girişim Notu';
      case ServiceType.fizyoterapi_seansi:
        return 'Fizyoterapi Seansı';
      case ServiceType.rehabilitasyon:
        return 'Rehabilitasyon';
      case ServiceType.rapor_belge:
        return 'Rapor / Belge';
      case ServiceType.diger:
        return 'Diğer';
    }
  }

  String? get rehabBillingSummary {
    if (!isRehabilitation || rehabBillingMode == null) return null;
    if (rehabBillingMode == PaymentRehabBillingMode.paket) {
      final count = packageSessionCount;
      if (count != null && count > 0) {
        return 'Paket — $count seans';
      }
      return 'Paket';
    }
    return 'Tek seans';
  }

  String get paymentMethodLabel {
    switch (paymentMethod) {
      case PaymentMethod.nakit:
        return 'Nakit';
      case PaymentMethod.kredi_karti:
        return 'Kredi Kartı';
      case PaymentMethod.havale_eft:
        return 'Havale / EFT';
      case PaymentMethod.karma:
        return 'Karma';
      case PaymentMethod.belirtilmedi:
        return 'Belirtilmedi';
    }
  }

  String get paymentStatusLabel {
    switch (paymentStatus) {
      case PaymentStatus.odendi:
        return 'Ödendi';
      case PaymentStatus.kismi_odendi:
        return 'Kısmi Ödendi';
      case PaymentStatus.bekliyor:
        return 'Bekliyor';
      case PaymentStatus.iptal:
        return 'İptal';
      case PaymentStatus.iade:
        return 'İade';
    }
  }

  String get invoiceStatusLabel {
    switch (invoiceStatus) {
      case InvoiceStatus.kesildi:
        return 'Fatura Kesildi';
      case InvoiceStatus.bekliyor:
        return 'Fatura Bekliyor';
      case InvoiceStatus.gerekmiyor:
        return 'Fatura Gerekmiyor';
      case InvoiceStatus.belirtilmedi:
        return 'Belirtilmedi';
    }
  }

  PaymentRecord copyWith({
    String? id,
    String? patientId,
    String? patientName,
    String? patientFileNumber,
    DateTime? createdAt,
    ServiceType? serviceType,
    double? totalAmount,
    double? paidAmount,
    PaymentMethod? paymentMethod,
    PaymentStatus? paymentStatus,
    InvoiceStatus? invoiceStatus,
    DateTime? transactionDate,
    String? recordedBy,
    String? notes,
    String? clinicalEncounterId,
    PaymentRehabBillingMode? rehabBillingMode,
    int? packageSessionCount,
    PaymentSourceKind? sourceKind,
    String? createdByUserId,
    bool clearClinicalEncounterId = false,
    bool clearRehabBillingMode = false,
    bool clearPackageSessionCount = false,
  }) {
    return PaymentRecord(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      patientFileNumber: patientFileNumber ?? this.patientFileNumber,
      createdAt: createdAt ?? this.createdAt,
      serviceType: serviceType ?? this.serviceType,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      invoiceStatus: invoiceStatus ?? this.invoiceStatus,
      transactionDate: transactionDate ?? this.transactionDate,
      recordedBy: recordedBy ?? this.recordedBy,
      notes: notes ?? this.notes,
      clinicalEncounterId: clearClinicalEncounterId
          ? null
          : (clinicalEncounterId ?? this.clinicalEncounterId),
      rehabBillingMode: clearRehabBillingMode
          ? null
          : (rehabBillingMode ?? this.rehabBillingMode),
      packageSessionCount: clearPackageSessionCount
          ? null
          : (packageSessionCount ?? this.packageSessionCount),
      sourceKind: sourceKind ?? this.sourceKind,
      createdByUserId: createdByUserId ?? this.createdByUserId,
    );
  }
}
