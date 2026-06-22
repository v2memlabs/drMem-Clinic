import '../../patient_files/data/patient_file_metadata_parse_helpers.dart';
import '../models/payment_record.dart';
import '../models/payment_rehab_billing_mode.dart';
import '../models/payment_source_kind.dart';
import 'payment_repository_failure.dart';

/// `payments` tablosu ↔ [PaymentRecord] map.
abstract final class PaymentRemoteMapper {
  static const String table = 'payments';

  static const String listSelectColumns =
      'id, tenant_id, patient_id, clinical_encounter_id, service_type, '
      'rehab_billing_mode, package_session_count, source_kind, total_amount, '
      'paid_amount, payment_method, payment_status, invoice_status, '
      'transaction_date, notes, recorded_by_display, created_by, created_at, '
      'patients(first_name, last_name, file_number)';

  static PaymentRecord fromRow(Map<String, dynamic> row) {
    final map = Map<String, dynamic>.from(row);
    final patientName = _embeddedPatientFullName(map['patients']) ??
        _flatPatientFullName(map) ??
        'Hasta';
    final patientFileNumber = _embeddedPatientFileNumber(map['patients']) ??
        _flatPatientFileNumber(map);

    return PaymentRecord(
      id: PatientFileMetadataParseHelpers.requireString(map, 'id'),
      patientId:
          PatientFileMetadataParseHelpers.requireString(map, 'patient_id'),
      patientName: patientName,
      patientFileNumber: patientFileNumber,
      createdAt:
          PatientFileMetadataParseHelpers.requireDateTime(map['created_at']),
      serviceType: _enumFromDb(
        ServiceType.values,
        map['service_type'],
        PaymentRepositoryFailure.invalidRow,
      ),
      totalAmount: _parseAmount(map['total_amount']),
      paidAmount: _parseAmount(map['paid_amount']),
      paymentMethod: _enumFromDb(
        PaymentMethod.values,
        map['payment_method'],
        PaymentRepositoryFailure.invalidRow,
      ),
      paymentStatus: _enumFromDb(
        PaymentStatus.values,
        map['payment_status'],
        PaymentRepositoryFailure.invalidRow,
      ),
      invoiceStatus: _enumFromDb(
        InvoiceStatus.values,
        map['invoice_status'],
        PaymentRepositoryFailure.invalidRow,
      ),
      transactionDate: PatientFileMetadataParseHelpers.requireDateTime(
          map['transaction_date']),
      recordedBy: PatientFileMetadataParseHelpers.optionalString(
            map['recorded_by_display'],
          ) ??
          '—',
      notes: PatientFileMetadataParseHelpers.optionalString(map['notes']) ?? '',
      clinicalEncounterId: PatientFileMetadataParseHelpers.optionalString(
        map['clinical_encounter_id'],
      ),
      rehabBillingMode: _optionalEnum(
        PaymentRehabBillingMode.values,
        map['rehab_billing_mode'],
      ),
      packageSessionCount: _optionalInt(map['package_session_count']),
      sourceKind: _optionalEnum(PaymentSourceKind.values, map['source_kind']) ??
          PaymentSourceKind.manual,
      createdByUserId: PatientFileMetadataParseHelpers.optionalString(
        map['created_by'],
      ),
    );
  }

  static Map<String, dynamic> toInsertRow({
    required String tenantId,
    required PaymentRecord payment,
    String? createdByProfileId,
  }) {
    return {
      'tenant_id': tenantId,
      'patient_id': payment.patientId.trim(),
      'service_type': payment.serviceType.name,
      'total_amount': payment.totalAmount,
      'paid_amount': payment.paidAmount,
      'payment_method': payment.paymentMethod.name,
      'payment_status': payment.paymentStatus.name,
      'invoice_status': payment.invoiceStatus.name,
      'transaction_date': payment.transactionDate.toUtc().toIso8601String(),
      'notes': payment.notes.trim().isEmpty ? null : payment.notes.trim(),
      if (createdByProfileId != null) 'created_by': createdByProfileId,
      'recorded_by_display':
          payment.recordedBy.trim().isEmpty ? null : payment.recordedBy.trim(),
      if (payment.clinicalEncounterId != null &&
          payment.clinicalEncounterId!.trim().isNotEmpty)
        'clinical_encounter_id': payment.clinicalEncounterId!.trim(),
      if (payment.rehabBillingMode != null)
        'rehab_billing_mode': payment.rehabBillingMode!.name,
      if (payment.packageSessionCount != null)
        'package_session_count': payment.packageSessionCount,
      'source_kind': payment.sourceKind.name,
    };
  }

  static Map<String, dynamic> toUpdateRow(PaymentRecord payment) {
    return {
      'service_type': payment.serviceType.name,
      'total_amount': payment.totalAmount,
      'paid_amount': payment.paidAmount,
      'payment_method': payment.paymentMethod.name,
      'payment_status': payment.paymentStatus.name,
      'invoice_status': payment.invoiceStatus.name,
      'transaction_date': payment.transactionDate.toUtc().toIso8601String(),
      'notes': payment.notes.trim().isEmpty ? null : payment.notes.trim(),
      'recorded_by_display':
          payment.recordedBy.trim().isEmpty ? null : payment.recordedBy.trim(),
      'clinical_encounter_id':
          payment.clinicalEncounterId?.trim().isEmpty ?? true
              ? null
              : payment.clinicalEncounterId!.trim(),
      'rehab_billing_mode': payment.rehabBillingMode?.name,
      'package_session_count': payment.packageSessionCount,
      'source_kind': payment.sourceKind.name,
    };
  }

  static String? _embeddedPatientFullName(dynamic value) {
    if (value is Map) {
      final first = value['first_name']?.toString().trim() ?? '';
      final last = value['last_name']?.toString().trim() ?? '';
      final name = '$first $last'.trim();
      return name.isEmpty ? null : name;
    }
    return null;
  }

  static String? _embeddedPatientFileNumber(dynamic value) {
    if (value is Map) {
      final fileNumber = value['file_number']?.toString().trim();
      if (fileNumber != null && fileNumber.isNotEmpty) return fileNumber;
    }
    return null;
  }

  static String? _flatPatientFullName(Map<String, dynamic> map) {
    final first = map['patient_first_name']?.toString().trim() ?? '';
    final last = map['patient_last_name']?.toString().trim() ?? '';
    final name = '$first $last'.trim();
    return name.isEmpty ? null : name;
  }

  static String? _flatPatientFileNumber(Map<String, dynamic> map) {
    final fileNumber = map['patient_file_number']?.toString().trim();
    if (fileNumber == null || fileNumber.isEmpty) return null;
    return fileNumber;
  }

  static double _parseAmount(Object? value) {
    if (value == null) {
      throw const PaymentRepositoryException(
          PaymentRepositoryFailure.invalidRow);
    }
    if (value is num) return value.toDouble();
    final parsed = double.tryParse(value.toString());
    if (parsed == null) {
      throw const PaymentRepositoryException(
          PaymentRepositoryFailure.invalidRow);
    }
    return parsed;
  }

  static T _enumFromDb<T extends Enum>(
    List<T> values,
    Object? raw,
    PaymentRepositoryFailure failure,
  ) {
    final name = raw?.toString().trim();
    if (name == null || name.isEmpty) {
      throw PaymentRepositoryException(failure);
    }
    for (final v in values) {
      if (v.name == name) return v;
    }
    throw PaymentRepositoryException(failure);
  }

  static T? _optionalEnum<T extends Enum>(List<T> values, Object? raw) {
    final name = raw?.toString().trim();
    if (name == null || name.isEmpty) return null;
    for (final v in values) {
      if (v.name == name) return v;
    }
    return null;
  }

  static int? _optionalInt(Object? raw) {
    if (raw == null) return null;
    if (raw is int) return raw;
    return int.tryParse(raw.toString());
  }
}
