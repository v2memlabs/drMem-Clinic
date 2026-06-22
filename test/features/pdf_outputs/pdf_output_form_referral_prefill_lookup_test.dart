import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/features/pdf_outputs/models/pdf_output.dart';
import 'package:v2mem_clinic/features/pdf_outputs/pdf_output_form_screen.dart';
import 'package:v2mem_clinic/features/physiotherapy/data/async_physiotherapy_referral_repository_contract.dart';
import 'package:v2mem_clinic/features/physiotherapy/data/physiotherapy_referral_repository_provider.dart';
import 'package:v2mem_clinic/features/physiotherapy/models/physiotherapy_referral.dart';
import 'package:v2mem_clinic/features/patients/widgets/patient_selector_field.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';

const _remoteUuid = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';

class _FakeReferralRepo implements AsyncPhysiotherapyReferralRepositoryContract {
  _FakeReferralRepo({this.returnReferral = true});

  final bool returnReferral;

  @override
  Future<PhysiotherapyReferral?> getById(String id) async {
    if (!returnReferral || id != _remoteUuid) return null;
    return PhysiotherapyReferral(
      id: _remoteUuid,
      patientId: 'p1',
      patientName: 'Ayşe Yılmaz',
      referredAt: DateTime(2026, 5, 1),
      referredBy: 'Dr. Enes',
      physiotherapistName: 'Fizyoterapist A',
      diagnosisSummary: 'Menisküs dejenerasyonu',
      treatmentGoal: 'Kuvvet ve hareket kontrolü',
      precautions: 'Ağrı artışı olursa durunuz',
      allowedActivities: 'Yürüyüş',
      restrictedActivities: 'Sıçrama',
      targetReturnToSportDate: DateTime(2026, 12, 1),
    );
  }

  @override
  Future<List<PhysiotherapyReferral>> getAll() async => [];

  @override
  Future<List<PhysiotherapyReferral>> getByPatientId(String patientId) async =>
      [];

  @override
  Future<List<PhysiotherapyReferral>> search(String query) async => [];

  @override
  Future<List<PhysiotherapyReferral>> getFiltered({
    String? patientId,
    String? query,
    ReferralStatus? statusEnumFilter,
    String? physiotherapistFilter,
  }) async =>
      [];

  @override
  Future<PhysiotherapyReferral> add(PhysiotherapyReferral referral) async =>
      referral;

  @override
  Future<PhysiotherapyReferral> updateSafeFields(
    String id,
    PhysiotherapyReferralSafeUpdate update,
  ) async =>
      (await getById(id))!;
}

void main() {
  tearDown(() {
    AuthSession.clear();
    PhysiotherapyReferralRepositoryProvider.clearTestOverrides();
    PhysiotherapyReferralRepositoryProvider.resetCache();
  });

  AuthSession.setUser(
    AppUser(
      id: 'd1',
      username: 'doc',
      displayName: 'Dr. Test',
      role: AppRoles.doctor,
    ),
  );

  test('PDF form path does not call sync getReferralById', () {
    final formSource = File(
      'lib/features/pdf_outputs/pdf_output_form_screen.dart',
    ).readAsStringSync();
    final prefillSource = File(
      'lib/features/pdf_outputs/pdf_module_prefill.dart',
    ).readAsStringSync();
    expect(formSource.contains('getReferralById'), isFalse);
    expect(prefillSource.contains('getReferralById'), isFalse);
  });

  Future<void> pumpReferralPdfForm(
    WidgetTester tester, {
    required String referralId,
  }) async {
    final router = GoRouter(
      initialLocation:
          '/pdf-outputs/new?patientId=p1&source=$pdfSourceModulePhysiotherapyReferral&id=$referralId',
      routes: [
        GoRoute(
          path: '/pdf-outputs/new',
          builder: (context, state) {
            final params = Uri.parse(state.location).queryParameters;
            return PdfOutputFormScreen(
              patientId: params['patientId'],
              source: params['source'],
              sourceRecordId: params['id'],
            );
          },
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (find.text('Yeni PDF Çıktı').evaluate().isNotEmpty &&
          find.byType(CircularProgressIndicator).evaluate().isEmpty) {
        break;
      }
    }
  }

  testWidgets('remote referral id prefill without technical uuid in UI', (
    tester,
  ) async {
    PhysiotherapyReferralRepositoryProvider.resetCache();
    PhysiotherapyReferralRepositoryProvider.testOverride = _FakeReferralRepo();

    await pumpReferralPdfForm(tester, referralId: _remoteUuid);

    expect(find.textContaining('Kaynak: Fizyoterapi Yönlendirme'), findsOneWidget);
    final selector = tester.widget<PatientSelectorField>(
      find.byType(PatientSelectorField),
    );
    expect(selector.lockSelection, isTrue);
    expect(selector.selectedPatientId, 'p1');
    expect(
      find.textContaining('Kaynak fizyoterapi yönlendirmesi bulunamadı'),
      findsNothing,
    );
    expect(find.textContaining(_remoteUuid), findsNothing);
    expect(find.textContaining('storage_path'), findsNothing);
    expect(find.textContaining('signed_url'), findsNothing);
    expect(find.textContaining('public_url'), findsNothing);
  });

  testWidgets('notFound shows safe warning without technical id', (
    tester,
  ) async {
    PhysiotherapyReferralRepositoryProvider.resetCache();
    PhysiotherapyReferralRepositoryProvider.testOverride =
        _FakeReferralRepo(returnReferral: false);

    await pumpReferralPdfForm(tester, referralId: _remoteUuid);

    expect(
      find.textContaining('Kaynak fizyoterapi yönlendirmesi bulunamadı'),
      findsOneWidget,
    );
    expect(find.textContaining(_remoteUuid), findsNothing);
  });

  testWidgets('mock referral id prefill via default async adapter', (
    tester,
  ) async {
    PhysiotherapyReferralRepositoryProvider.resetCache();
    PhysiotherapyReferralRepositoryProvider.clearTestOverrides();

    await pumpReferralPdfForm(tester, referralId: 'ref-001');

    expect(find.textContaining('Kaynak: Fizyoterapi Yönlendirme'), findsOneWidget);
    final selector = tester.widget<PatientSelectorField>(
      find.byType(PatientSelectorField),
    );
    expect(selector.lockSelection, isTrue);
    expect(selector.selectedPatientId, 'p1');
    expect(find.textContaining('ref-001'), findsNothing);
  });
}
