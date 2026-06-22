import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/payments/data/payment_remote_mapper.dart';
import 'package:v2mem_clinic/features/payments/models/payment_record.dart';

void main() {
  test('fromRow maps remote row with patient join', () {
    final record = PaymentRemoteMapper.fromRow({
      'id': 'a0000001-0001-4001-8001-000000000001',
      'patient_id': 'b0000001-0001-4001-8001-000000000001',
      'service_type': 'muayene',
      'total_amount': 500,
      'paid_amount': 200,
      'payment_method': 'nakit',
      'payment_status': 'kismi_odendi',
      'invoice_status': 'belirtilmedi',
      'transaction_date': '2026-05-01T10:00:00Z',
      'notes': 'Test notu',
      'recorded_by_display': 'Asistan',
      'created_at': '2026-05-01T09:00:00Z',
      'patients': {
        'first_name': 'Ayşe',
        'last_name': 'Yılmaz',
        'file_number': 'H-001',
      },
    });

    expect(record.patientName, 'Ayşe Yılmaz');
    expect(record.serviceType, ServiceType.muayene);
    expect(record.paymentStatus, PaymentStatus.kismi_odendi);
    expect(record.totalAmount, 500);
    expect(record.paidAmount, 200);
    expect(record.recordedBy, 'Asistan');
    expect(record.notes, 'Test notu');
  });

  test('fromRow handles null notes', () {
    final record = PaymentRemoteMapper.fromRow({
      'id': 'a0000001-0001-4001-8001-000000000002',
      'patient_id': 'b0000001-0001-4001-8001-000000000001',
      'service_type': 'kontrol',
      'total_amount': 100,
      'paid_amount': 0,
      'payment_method': 'belirtilmedi',
      'payment_status': 'bekliyor',
      'invoice_status': 'bekliyor',
      'transaction_date': '2026-05-02T10:00:00Z',
      'notes': null,
      'recorded_by_display': null,
      'created_at': '2026-05-02T09:00:00Z',
      'patients': {'first_name': 'Ali', 'last_name': 'Demir'},
    });

    expect(record.notes, '');
    expect(record.recordedBy, '—');
  });

  test('toInsertRow uses enum names and omits mock id', () {
    final row = PaymentRemoteMapper.toInsertRow(
      tenantId: 't-1',
      payment: PaymentRecord(
        id: 'pay-mock-1',
        patientId: 'p-1',
        patientName: 'Hasta',
        createdAt: DateTime(2026, 5, 1),
        serviceType: ServiceType.muayene,
        totalAmount: 300,
        paidAmount: 0,
        paymentMethod: PaymentMethod.nakit,
        paymentStatus: PaymentStatus.bekliyor,
        invoiceStatus: InvoiceStatus.bekliyor,
        transactionDate: DateTime(2026, 5, 1),
        recordedBy: 'Asistan',
      ),
      createdByProfileId: 'profile-1',
    );

    expect(row['tenant_id'], 't-1');
    expect(row['patient_id'], 'p-1');
    expect(row['service_type'], 'muayene');
    expect(row['payment_status'], 'bekliyor');
    expect(row.containsKey('id'), isFalse);
    expect(row['created_by'], 'profile-1');
  });
}
