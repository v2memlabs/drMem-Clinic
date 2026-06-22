import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/features/payments/data/async_payment_repository_contract.dart';
import 'package:v2mem_clinic/features/payments/data/payment_repository_provider.dart';
import 'package:v2mem_clinic/features/payments/models/payment_outstanding_patient_alert.dart';
import 'package:v2mem_clinic/features/payments/models/payment_record.dart';
import 'package:v2mem_clinic/features/payments/models/payment_statistics_snapshot.dart';
import 'package:v2mem_clinic/features/payments/payment_list_screen.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';

class _FakePaymentRepo implements AsyncPaymentRepositoryContract {
  final List<PaymentRecord> _records;

  _FakePaymentRepo(this._records);

  @override
  Future<List<PaymentRecord>> getAll() async => List.from(_records);

  @override
  Future<List<PaymentRecord>> getByPatientId(String patientId) async =>
      _records.where((p) => p.patientId == patientId).toList();

  @override
  Future<PaymentRecord?> getById(String id) async {
    for (final p in _records) {
      if (p.id == id) return p;
    }
    return null;
  }

  @override
  Future<List<PaymentRecord>> search(String query) async => getAll();

  @override
  Future<List<PaymentRecord>> listFiltered({
    String? patientId,
    String query = '',
    ServiceType? serviceTypeFilter,
    PaymentStatus? paymentStatusFilter,
    PaymentMethod? paymentMethodFilter,
    bool operationalScope = true,
  }) async =>
      patientId == null ? getAll() : getByPatientId(patientId);

  @override
  Future<PaymentStatisticsSnapshot> loadStatistics({
    required PaymentStatisticsScope scope,
    required int year,
    int? month,
  }) async =>
      PaymentStatisticsSnapshot(
        scope: scope,
        year: year,
        month: month,
        periodLabel: '$year',
        totalAccrual: 0,
        totalCollected: 0,
        openBalanceAllTime: 0,
        paymentCount: 0,
        patientCount: 0,
        outstandingPatientCount: 0,
        collectedByService: const {},
      );

  @override
  Future<List<PaymentOutstandingPatientAlert>> loadOutstandingAlerts() async =>
      const [];

  @override
  Future<PaymentRecord> add(PaymentRecord payment) async {
    _records.insert(0, payment);
    return payment;
  }

  @override
  Future<PaymentRecord> update(PaymentRecord payment) async => payment;

  @override
  Future<PaymentRecord?> getByClinicalEncounterId(String encounterId) async =>
      null;
}

void main() {
  tearDown(() {
    AuthSession.clear();
    PaymentRepositoryProvider.clearTestOverrides();
    PaymentRepositoryProvider.resetCache();
  });

  testWidgets('create appears in list via async data source', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repo = _FakePaymentRepo([
      PaymentRecord(
        id: 'pay-reflect-1',
        patientId: 'p1',
        patientName: 'Ödeme Hasta',
        createdAt: DateTime(2026, 5, 1),
        serviceType: ServiceType.muayene,
        totalAmount: 500,
        paidAmount: 200,
        paymentMethod: PaymentMethod.nakit,
        paymentStatus: PaymentStatus.kismi_odendi,
        invoiceStatus: InvoiceStatus.belirtilmedi,
        transactionDate: DateTime(2026, 5, 1),
        recordedBy: 'Asistan',
        notes: 'Güvenli ödeme notu',
      ),
    ]);

    AuthSession.setUser(
      AppUser(
        id: 'a1',
        username: 'asst',
        displayName: 'Asistan',
        role: AppRoles.assistant,
      ),
    );
    PaymentRepositoryProvider.resetCache();
    PaymentRepositoryProvider.testOverride = repo;

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const PaymentListScreen(),
        ),
      ],
    );

    await tester.binding.setSurfaceSize(const Size(1200, 900));
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.textContaining('Ödeme Hasta'), findsWidgets);
    expect(find.textContaining('Güvenli ödeme notu'), findsNothing);
    expect(find.textContaining('pay-reflect-1'), findsNothing);
    expect(find.textContaining('tenant_id'), findsNothing);
    expect(find.textContaining('Exception'), findsNothing);
  });
}
