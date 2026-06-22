import '../../../core/auth/auth_session.dart';
import '../../../core/tenant/tenant_financial_feature_gate.dart';
import '../../../core/data/repository_registry.dart';
import '../../inventory/data/inventory_form_data_source.dart';
import '../../inventory/models/inventory_item.dart';
import '../../inventory/models/inventory_movement.dart';
import '../models/clinical_encounter_charge_option.dart';
import '../models/payment_record.dart';
import '../models/payment_source_kind.dart';
import 'payment_list_refresh.dart';
import 'payment_notification_data_source.dart';

class PatientMaterialChargeResult {
  final PaymentRecord payment;
  final String? errorMessage;

  const PatientMaterialChargeResult._({
    required this.payment,
    this.errorMessage,
  });

  factory PatientMaterialChargeResult.success(PaymentRecord payment) {
    return PatientMaterialChargeResult._(payment: payment);
  }

  factory PatientMaterialChargeResult.failure(String message) {
    return PatientMaterialChargeResult._(
      payment: _placeholderPayment,
      errorMessage: message,
    );
  }

  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;

  static final _placeholderPayment = PaymentRecord(
    id: '',
    patientId: '',
    patientName: '',
    createdAt: DateTime.fromMillisecondsSinceEpoch(0),
    serviceType: ServiceType.diger,
    totalAmount: 0,
    paidAmount: 0,
    paymentMethod: PaymentMethod.belirtilmedi,
    paymentStatus: PaymentStatus.bekliyor,
    invoiceStatus: InvoiceStatus.belirtilmedi,
    transactionDate: DateTime.fromMillisecondsSinceEpoch(0),
    recordedBy: '',
  );
}

/// Hasta malzeme şarjı — stok çıkışı + seçili muayene ödeme kaydı.
abstract final class PatientMaterialChargeOrchestrator {
  static Future<PatientMaterialChargeResult> charge({
    required ClinicalEncounterChargeOption encounter,
    required InventoryItem item,
    required double quantity,
    required double unitPrice,
  }) async {
    if (!TenantFinancialFeatureGate.materialChargesEnabled) {
      return PatientMaterialChargeResult.failure(
        'Bu klinik için malzeme şarjı kapalı.',
      );
    }
    if (quantity <= 0) {
      return PatientMaterialChargeResult.failure('Miktar sıfırdan büyük olmalıdır.');
    }
    if (unitPrice < 0) {
      return PatientMaterialChargeResult.failure('Birim fiyat geçersiz.');
    }

    final lineTotal = quantity * unitPrice;
    final performer = AuthSession.currentUser?.displayName ?? 'Kullanıcı';
    final movement = InventoryMovement(
      id: 'mov-${DateTime.now().millisecondsSinceEpoch}',
      inventoryItemId: item.id,
      movementType: InventoryMovementType.cikis,
      quantity: quantity,
      movementDate: DateTime.now(),
      performedBy: performer,
      note: 'Hasta şarjı: ${encounter.patientName}',
      patientId: encounter.patientId,
      relatedModule: 'clinical_encounter',
      relatedRecordId: encounter.id,
      createdAt: DateTime.now(),
    );

    final movementResult = await InventoryFormDataSource.addMovement(movement);
    if (movementResult.hasError) {
      return PatientMaterialChargeResult.failure(
        movementResult.validationError ??
            movementResult.repositoryError ??
            'Stok hareketi kaydedilemedi.',
      );
    }

    final payments = RepositoryRegistry.paymentsAsync;
    var payment = await payments.getByClinicalEncounterId(encounter.id);
    final materialLine =
        '${item.name} x$quantity = ${lineTotal.toStringAsFixed(2)} TL';

    if (payment == null) {
      payment = PaymentRecord(
        id: 'pay-${DateTime.now().millisecondsSinceEpoch}',
        patientId: encounter.patientId,
        patientName: encounter.patientName,
        createdAt: DateTime.now(),
        serviceType: ServiceType.diger,
        totalAmount: lineTotal,
        paidAmount: 0,
        paymentMethod: PaymentMethod.belirtilmedi,
        paymentStatus: PaymentStatus.bekliyor,
        invoiceStatus: InvoiceStatus.belirtilmedi,
        transactionDate: DateTime.now(),
        recordedBy: performer,
        notes: 'Malzeme: $materialLine',
        clinicalEncounterId: encounter.id,
        sourceKind: PaymentSourceKind.materialCharge,
        createdByUserId: AuthSession.currentUser?.id,
      );
      payment = await payments.add(payment);
      await PaymentNotificationDataSource.notifyAssistantForReview(payment);
    } else {
      payment = payment.copyWith(
        totalAmount: payment.totalAmount + lineTotal,
        notes: payment.notes.trim().isEmpty
            ? 'Malzeme: $materialLine'
            : '${payment.notes.trim()}\nMalzeme: $materialLine',
        sourceKind: PaymentSourceKind.materialCharge,
      );
      payment = await payments.update(payment);
    }

    PaymentListRefresh.markStale();
    return PatientMaterialChargeResult.success(payment);
  }
}
