import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/features/consents/consent_list_screen.dart';
import 'package:v2mem_clinic/features/consents/data/async_consent_repository_contract.dart';
import 'package:v2mem_clinic/features/consents/data/consent_repository_provider.dart';
import 'package:v2mem_clinic/features/consents/models/consent_record.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';

class _FakeConsentRepo implements AsyncConsentRepositoryContract {
  final List<ConsentRecord> _records;

  _FakeConsentRepo(this._records);

  @override
  Future<List<ConsentRecord>> getAll() async => List.from(_records);

  @override
  Future<List<ConsentRecord>> getByPatientId(String patientId) async =>
      _records.where((c) => c.patientId == patientId).toList();

  @override
  Future<ConsentRecord?> getById(String id) async {
    for (final c in _records) {
      if (c.id == id) return c;
    }
    return null;
  }

  @override
  Future<List<ConsentRecord>> search(String query) async => getAll();

  @override
  Future<ConsentRecord> add(ConsentRecord consent) async {
    _records.insert(0, consent);
    return consent;
  }

  @override
  Future<ConsentRecord> update(ConsentRecord consent) async => consent;

  @override
  Future<int> countPending() async =>
      _records.where((c) => c.status == ConsentStatus.bekliyor).length;
}

void main() {
  tearDown(() {
    AuthSession.clear();
    ConsentRepositoryProvider.clearTestOverrides();
    ConsentRepositoryProvider.resetCache();
  });

  testWidgets('consent list shows safe fields from fake repo', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));

    AuthSession.setUser(
      AppUser(
        id: 'a1',
        username: 'asst',
        displayName: 'Asistan',
        role: AppRoles.assistant,
      ),
    );
    ConsentRepositoryProvider.resetCache();
    ConsentRepositoryProvider.testOverride = _FakeConsentRepo([
      ConsentRecord(
        id: 'c-test-1',
        patientId: 'p1',
        patientName: 'Onam Hasta',
        createdAt: DateTime(2026, 5, 1),
        consentType: ConsentType.kvkkAydinlatma,
        status: ConsentStatus.bekliyor,
        recordedBy: 'Asistan',
        notes: 'Güvenli onam notu',
      ),
    ]);

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const ConsentListScreen(),
        ),
      ],
    );

    await tester.binding.setSurfaceSize(const Size(1200, 900));
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('Onam Hasta'), findsWidgets);
    expect(find.textContaining('Güvenli onam notu'), findsNothing);
    expect(find.textContaining('c-test-1'), findsNothing);
    expect(find.textContaining('tenant_id'), findsNothing);
    expect(find.textContaining('internalDoctorNote'), findsNothing);
  });
}
