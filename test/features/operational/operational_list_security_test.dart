import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/features/consents/consent_list_screen.dart';
import 'package:v2mem_clinic/features/consents/data/async_consent_repository_contract.dart';
import 'package:v2mem_clinic/features/consents/data/consent_repository_provider.dart';
import 'package:v2mem_clinic/features/consents/models/consent_record.dart';
import 'package:v2mem_clinic/features/inventory/data/async_inventory_repository_contract.dart';
import 'package:v2mem_clinic/features/inventory/data/inventory_repository_provider.dart';
import 'package:v2mem_clinic/features/inventory/inventory_list_screen.dart';
import 'package:v2mem_clinic/features/inventory/models/inventory_item.dart';
import 'package:v2mem_clinic/features/inventory/models/inventory_movement.dart';
import 'package:v2mem_clinic/features/payments/data/async_payment_repository_contract.dart';
import 'package:v2mem_clinic/features/payments/data/payment_repository_provider.dart';
import 'package:v2mem_clinic/features/payments/models/payment_outstanding_patient_alert.dart';
import 'package:v2mem_clinic/features/payments/models/payment_record.dart';
import 'package:v2mem_clinic/features/payments/models/payment_statistics_snapshot.dart';
import 'package:v2mem_clinic/features/payments/payment_list_screen.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';
import 'package:v2mem_clinic/shared/widgets/clinical_ui_text_sanitizer.dart';

/// Operasyonel liste ekranları — sanitizer ile hizalı yasak token seti.
/// Maintenance route'ları bu taramanın dışındadır (bakım allowlist testine bakın).
final _forbiddenTokens = [
  ...ClinicalUiTextSanitizer.forbiddenUiTokens,
  'StackTrace',
];

void main() {
  tearDown(() {
    AuthSession.clear();
    PaymentRepositoryProvider.clearTestOverrides();
    PaymentRepositoryProvider.resetCache();
    ConsentRepositoryProvider.clearTestOverrides();
    ConsentRepositoryProvider.resetCache();
    InventoryRepositoryProvider.clearTestOverrides();
    InventoryRepositoryProvider.resetCache();
  });

  Future<void> pumpOperationalList(
    WidgetTester tester, {
    required Widget screen,
    required String role,
  }) async {
    AuthSession.setUser(
      AppUser(
        id: 'u-$role',
        username: role,
        displayName: 'Test',
        role: role,
      ),
    );

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (context, state) => screen),
      ],
    );

    await tester.binding.setSurfaceSize(const Size(1200, 900));
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
  }

  testWidgets('payment list hides technical fields', (tester) async {
    PaymentRepositoryProvider.resetCache();
    PaymentRepositoryProvider.testOverride = _PaymentRepo();

    await pumpOperationalList(
      tester,
      screen: const PaymentListScreen(),
      role: AppRoles.assistant,
    );

    for (final token in _forbiddenTokens) {
      expect(find.textContaining(token), findsNothing);
    }
  });

  testWidgets('consent list hides technical fields', (tester) async {
    ConsentRepositoryProvider.resetCache();
    ConsentRepositoryProvider.testOverride = _ConsentRepo();

    await pumpOperationalList(
      tester,
      screen: const ConsentListScreen(),
      role: AppRoles.assistant,
    );

    for (final token in _forbiddenTokens) {
      expect(find.textContaining(token), findsNothing);
    }
  });

  testWidgets('inventory list hides technical fields', (tester) async {
    InventoryRepositoryProvider.resetCache();
    InventoryRepositoryProvider.testOverride = _InventoryRepo();

    await pumpOperationalList(
      tester,
      screen: const InventoryListScreen(),
      role: AppRoles.nurse,
    );

    for (final token in _forbiddenTokens) {
      expect(find.textContaining(token), findsNothing);
    }
  });
}

class _PaymentRepo implements AsyncPaymentRepositoryContract {
  @override
  Future<List<PaymentRecord>> getAll() async => [
        PaymentRecord(
          id: 'pay-sec-1',
          patientId: 'p-secret',
          patientName: 'Güvenli',
          createdAt: DateTime(2026, 1, 1),
          serviceType: ServiceType.muayene,
          totalAmount: 100,
          paidAmount: 0,
          paymentMethod: PaymentMethod.belirtilmedi,
          paymentStatus: PaymentStatus.bekliyor,
          invoiceStatus: InvoiceStatus.belirtilmedi,
          transactionDate: DateTime(2026, 1, 1),
          recordedBy: 'Test',
          notes: '',
        ),
      ];

  @override
  Future<List<PaymentRecord>> getByPatientId(String patientId) async => getAll();

  @override
  Future<PaymentRecord?> getById(String id) async => null;

  @override
  Future<List<PaymentRecord>> search(String query) async => getAll();

  @override
  Future<PaymentRecord> add(PaymentRecord payment) async => payment;

  @override
  Future<List<PaymentRecord>> listFiltered({
    String? patientId,
    String query = '',
    ServiceType? serviceTypeFilter,
    PaymentStatus? paymentStatusFilter,
    PaymentMethod? paymentMethodFilter,
    bool operationalScope = true,
  }) async =>
      getAll();

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
  Future<PaymentRecord> update(PaymentRecord payment) async => payment;

  @override
  Future<PaymentRecord?> getByClinicalEncounterId(String encounterId) async =>
      null;
}

class _ConsentRepo implements AsyncConsentRepositoryContract {
  @override
  Future<List<ConsentRecord>> getAll() async => [
        ConsentRecord(
          id: 'c-sec-1',
          patientId: 'p-secret',
          patientName: 'Güvenli',
          createdAt: DateTime(2026, 1, 1),
          consentType: ConsentType.kvkkAydinlatma,
          status: ConsentStatus.bekliyor,
          recordedBy: 'Test',
        ),
      ];

  @override
  Future<List<ConsentRecord>> getByPatientId(String patientId) async => getAll();

  @override
  Future<ConsentRecord?> getById(String id) async => null;

  @override
  Future<List<ConsentRecord>> search(String query) async => getAll();

  @override
  Future<ConsentRecord> add(ConsentRecord consent) async => consent;

  @override
  Future<ConsentRecord> update(ConsentRecord consent) async => consent;

  @override
  Future<int> countPending() async => 1;
}

class _InventoryRepo implements AsyncInventoryRepositoryContract {
  @override
  Future<List<InventoryItem>> getFiltered({
    String? query,
    InventoryCategory? category,
    bool lowStockOnly = false,
    bool expiringSoonOnly = false,
    bool expiredOnly = false,
    bool includeInactive = false,
  }) async =>
      [
        InventoryItem(
          id: 'inv-sec-1',
          name: 'Güvenli Sarf',
          category: InventoryCategory.sarfMalzeme,
          unit: 'adet',
          currentQuantity: 1,
          minimumQuantity: 2,
          isActive: true,
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
      ];

  @override
  Future<InventoryItem?> getById(String id) async => null;

  @override
  Future<InventoryItem> add(InventoryItem item) async => item;

  @override
  Future<InventoryItem> update(InventoryItem item) async => item;

  @override
  Future<String?> addMovement(InventoryMovement movement) async => null;

  @override
  Future<List<InventoryMovement>> getMovementsByItemId(
    String inventoryItemId,
  ) async =>
      [];

  @override
  Future<int> countLowStock() async => 1;

  @override
  Future<int> countExpiringSoon({int days = 30}) async => 0;

  @override
  Future<int> countExpired() async => 0;
}
