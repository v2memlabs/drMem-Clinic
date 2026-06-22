import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/payments/widgets/payment_summary_kpi_strip.dart';

void main() {
  testWidgets('compact strip shows all summary labels and values', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PaymentSummaryKpiStrip(
            totalAccrual: '12.000 ₺',
            totalPaid: '8.000 ₺',
            pendingAmount: '4.000 ₺',
            pendingCount: '3',
          ),
        ),
      ),
    );

    expect(find.text('Toplam Tahakkuk'), findsOneWidget);
    expect(find.text('Tahsil Edilen'), findsOneWidget);
    expect(find.text('Kalan Bakiye'), findsOneWidget);
    expect(find.text('Bekleyen Kayıt'), findsOneWidget);
    expect(find.text('12.000 ₺'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.byType(Card), findsNothing);
  });

  testWidgets('tablet width uses single row without overflow', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PaymentSummaryKpiStrip(
            totalAccrual: '99.999 ₺',
            totalPaid: '1 ₺',
            pendingAmount: '98.998 ₺',
            pendingCount: '12',
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(Row), findsWidgets);
  });

  testWidgets('mobile width wraps metrics in two columns', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 240));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PaymentSummaryKpiStrip(
            totalAccrual: '1 ₺',
            totalPaid: '2 ₺',
            pendingAmount: '3 ₺',
            pendingCount: '4',
          ),
        ),
      ),
    );

    expect(find.byType(Wrap), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
