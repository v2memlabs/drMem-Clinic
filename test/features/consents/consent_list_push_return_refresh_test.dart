import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/features/consents/consent_list_screen.dart';
import 'package:v2mem_clinic/features/consents/data/async_consent_repository_contract.dart';
import 'package:v2mem_clinic/features/consents/data/consent_list_refresh.dart';
import 'package:v2mem_clinic/features/consents/data/consent_repository_provider.dart';
import 'package:v2mem_clinic/features/consents/models/consent_record.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';

class _MutableConsentRepo implements AsyncConsentRepositoryContract {
  final List<ConsentRecord> records;

  _MutableConsentRepo(this.records);

  @override
  Future<List<ConsentRecord>> getAll() async => List.from(records);

  @override
  Future<List<ConsentRecord>> getByPatientId(String patientId) async =>
      records.where((c) => c.patientId == patientId).toList();

  @override
  Future<ConsentRecord?> getById(String id) async {
    for (final c in records) {
      if (c.id == id) return c;
    }
    return null;
  }

  @override
  Future<List<ConsentRecord>> search(String query) async => getAll();

  @override
  Future<ConsentRecord> add(ConsentRecord consent) async {
    records.insert(0, consent);
    return consent;
  }

  @override
  Future<ConsentRecord> update(ConsentRecord consent) async => consent;

  @override
  Future<int> countPending() async => 0;
}

void main() {
  tearDown(() {
    AuthSession.clear();
    ConsentRepositoryProvider.clearTestOverrides();
    ConsentRepositoryProvider.resetCache();
  });

  testWidgets('new consent push return reloads when stale', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final records = [
      ConsentRecord(
        id: 'c-push-1',
        patientId: 'p1',
        patientName: 'Onam Başlangıç',
        createdAt: DateTime(2026, 5, 1),
        consentType: ConsentType.kvkkAydinlatma,
        status: ConsentStatus.bekliyor,
        recordedBy: 'Asistan',
      ),
    ];

    AuthSession.setUser(
      AppUser(
        id: 'a1',
        username: 'asst',
        displayName: 'Asistan',
        role: AppRoles.assistant,
      ),
    );
    ConsentRepositoryProvider.resetCache();
    ConsentRepositoryProvider.testOverride = _MutableConsentRepo(records);

    late final GoRouter router;
    router = GoRouter(
      initialLocation: '/consents',
      routes: [
        GoRoute(
          path: '/consents',
          builder: (context, state) => const ConsentListScreen(),
        ),
        GoRoute(
          path: '/consents/new',
          builder: (context, state) =>
              const Scaffold(body: Text('Onam Form Stub')),
        ),
      ],
    );

    await tester.binding.setSurfaceSize(const Size(1200, 900));
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.textContaining('Onam Başlangıç'), findsWidgets);
    expect(find.textContaining('Push Return Onam'), findsNothing);

    await tester.tap(find.text('Onam Evrakı'));
    await tester.pumpAndSettle();

    records.insert(
      0,
      ConsentRecord(
        id: 'c-push-2',
        patientId: 'p2',
        patientName: 'Push Return Onam',
        createdAt: DateTime(2026, 5, 2),
        consentType: ConsentType.kvkkAydinlatma,
        status: ConsentStatus.bekliyor,
        recordedBy: 'Asistan',
      ),
    );
    ConsentListRefresh.markStale();

    router.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.textContaining('Push Return Onam'), findsWidgets);
    expect(find.textContaining('tenant_id'), findsNothing);
  });
}
