import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/payments/data/payment_list_period_filter.dart';
import 'package:v2mem_clinic/features/payments/data/payment_outstanding_alerts.dart';
import 'package:v2mem_clinic/features/payments/data/payment_outstanding_balance.dart';
import 'package:v2mem_clinic/features/payments/data/payment_statistics_calculator.dart';
import 'package:v2mem_clinic/features/payments/models/payment_record.dart';
import 'package:v2mem_clinic/features/payments/models/payment_statistics_snapshot.dart';

PaymentRecord _record({
  required String id,
  required DateTime transactionDate,
  double total = 100,
  double paid = 100,
  PaymentStatus status = PaymentStatus.odendi,
  String patientId = 'p1',
}) {
  return PaymentRecord(
    id: id,
    patientId: patientId,
    patientName: 'Hasta $patientId',
    createdAt: transactionDate,
    serviceType: ServiceType.muayene,
    totalAmount: total,
    paidAmount: paid,
    paymentMethod: PaymentMethod.nakit,
    paymentStatus: status,
    invoiceStatus: InvoiceStatus.belirtilmedi,
    transactionDate: transactionDate,
    recordedBy: 'Test',
  );
}

void main() {
  group('PaymentListPeriodFilter', () {
    test('hides fully paid previous month records', () {
      final now = DateTime.now();
      final previousMonth = DateTime(now.year, now.month - 1, 15);
      final records = [
        _record(id: 'old-paid', transactionDate: previousMonth),
        _record(
          id: 'current',
          transactionDate: DateTime(now.year, now.month, 5),
        ),
      ];

      final visible = PaymentListPeriodFilter.applyOperationalScope(
        records: records,
        scopedToPatient: false,
      );

      expect(visible.map((r) => r.id), ['current']);
    });

    test('keeps outstanding records from previous months', () {
      final now = DateTime.now();
      final previousMonth = DateTime(now.year, now.month - 1, 15);
      final records = [
        _record(
          id: 'old-open',
          transactionDate: previousMonth,
          paid: 20,
          status: PaymentStatus.kismi_odendi,
        ),
      ];

      final visible = PaymentListPeriodFilter.applyOperationalScope(
        records: records,
        scopedToPatient: false,
      );

      expect(visible, hasLength(1));
      expect(PaymentOutstandingBalance.hasOutstanding(visible.first), isTrue);
    });

    test('does not filter when scoped to patient', () {
      final now = DateTime.now();
      final previousMonth = DateTime(now.year, now.month - 1, 15);
      final records = [
        _record(id: 'old-paid', transactionDate: previousMonth),
      ];

      final visible = PaymentListPeriodFilter.applyOperationalScope(
        records: records,
        scopedToPatient: true,
      );

      expect(visible, hasLength(1));
    });
  });

  group('PaymentOutstandingAlerts', () {
    test('groups open balances by patient', () {
      final now = DateTime.now();
      final alerts = PaymentOutstandingAlerts.fromRecords([
        _record(
          id: '1',
          patientId: 'p1',
          transactionDate: now,
          paid: 0,
          status: PaymentStatus.bekliyor,
        ),
        _record(
          id: '2',
          patientId: 'p1',
          transactionDate: now,
          paid: 50,
          status: PaymentStatus.kismi_odendi,
        ),
        _record(
          id: '3',
          patientId: 'p2',
          transactionDate: now,
          paid: 10,
          total: 200,
          status: PaymentStatus.kismi_odendi,
        ),
      ]);

      expect(alerts, hasLength(2));
      expect(alerts.first.patientId, 'p2');
      expect(alerts.first.totalRemaining, 190);
    });
  });

  group('PaymentStatisticsCalculator', () {
    test('computes monthly totals', () {
      final now = DateTime.now();
      final stats = PaymentStatisticsCalculator.compute(
        records: [
          _record(
            id: '1',
            transactionDate: DateTime(now.year, now.month, 3),
            total: 200,
            paid: 150,
          ),
          _record(
            id: '2',
            transactionDate: DateTime(now.year, now.month - 1, 3),
            total: 500,
            paid: 500,
          ),
        ],
        scope: PaymentStatisticsScope.month,
        year: now.year,
        month: now.month,
      );

      expect(stats.totalAccrual, 200);
      expect(stats.totalCollected, 150);
      expect(stats.paymentCount, 1);
      expect(stats.patientCount, 1);
    });
  });
}
