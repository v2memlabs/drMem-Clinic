import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/features/pdf_outputs/data/async_pdf_output_repository_contract.dart';
import 'package:v2mem_clinic/features/pdf_outputs/data/pdf_output_repository_provider.dart';
import 'package:v2mem_clinic/features/pdf_outputs/models/pdf_output.dart';
import 'package:v2mem_clinic/features/pdf_outputs/pdf_output_detail_screen.dart';
import 'package:v2mem_clinic/features/physiotherapy/data/async_physiotherapy_referral_repository_contract.dart';
import 'package:v2mem_clinic/features/physiotherapy/data/physiotherapy_referral_repository_provider.dart';
import 'package:v2mem_clinic/features/physiotherapy/models/physiotherapy_referral.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';

const _remoteUuid = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';
const _pdfId = 'pdf-ref-lookup-test';

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
      treatmentGoal: 'Kuvvet',
      precautions: '',
      allowedActivities: '',
      restrictedActivities: '',
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

class _FakePdfOutputRepo implements AsyncPdfOutputRepositoryContract {
  _FakePdfOutputRepo(this._output);

  final PdfOutput _output;

  @override
  Future<List<PdfOutput>> getAll() async => [_output];

  @override
  Future<PdfOutput?> getById(String id) async =>
      id == _output.id ? _output : null;

  @override
  Future<List<PdfOutput>> getByPatientId(String patientId) async => [];

  @override
  Future<List<PdfOutput>> search(String query) async => [];
}

PdfOutput _referralSourcePdf({required String sourceRecordId}) {
  return PdfOutput(
    id: _pdfId,
    patientId: 'p1',
    patientName: 'Ayşe Yılmaz',
    createdAt: DateTime(2026, 6, 1),
    documentType: DocumentType.fizyoterapiYonlendirme,
    title: 'Fizyoterapi Yönlendirme — Ayşe Yılmaz',
    relatedDiagnosis: 'Menisküs dejenerasyonu',
    relatedTreatmentPlan: 'Kuvvet',
    contentSummary: 'Yönlendirme özeti',
    warningNote: 'Uyarı',
    createdBy: 'Dr. Test',
    status: PdfStatus.taslak,
    sourceModule: pdfSourceModulePhysiotherapyReferral,
    sourceRecordId: sourceRecordId,
    storagePath: 'tenant/p1/secret.pdf',
    storageBucket: 'patient-files-private',
  );
}

void main() {
  tearDown(() {
    AuthSession.clear();
    PdfOutputRepositoryProvider.testOverride = null;
    PdfOutputRepositoryProvider.resetCache();
    PhysiotherapyReferralRepositoryProvider.clearTestOverrides();
    PhysiotherapyReferralRepositoryProvider.resetCache();
  });

  test('PDF detail path delegates source lookup to data source', () {
    final source = File(
      'lib/features/pdf_outputs/pdf_output_detail_screen.dart',
    ).readAsStringSync();
    expect(source.contains('getReferralById'), isFalse);
    expect(source.contains('PhysiotherapyReferralLookupDataSource'), isFalse);
    expect(
      source.contains('PdfOutputSourceRecordLookupDataSource.resolveDisplayLabel'),
      isTrue,
    );
  });

  Future<void> pumpDetail(WidgetTester tester, PdfOutput output) async {
    AuthSession.setUser(
      AppUser(
        id: 'd1',
        username: 'doc',
        displayName: 'Dr. Test',
        role: AppRoles.doctor,
      ),
    );
    PdfOutputRepositoryProvider.testOverride = _FakePdfOutputRepo(output);

    final router = GoRouter(
      initialLocation: '/pdf-outputs/$_pdfId',
      routes: [
        GoRoute(
          path: '/pdf-outputs/:id',
          builder: (context, state) => PdfOutputDetailScreen(
            id: state.pathParameters['id']!,
          ),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    await tester.pumpAndSettle();
  }

  testWidgets('shows safe FTR source label for remote referral id', (
    tester,
  ) async {
    PhysiotherapyReferralRepositoryProvider.testOverride = _FakeReferralRepo();

    await pumpDetail(tester, _referralSourcePdf(sourceRecordId: _remoteUuid));

    expect(find.text('Fizyoterapi Yönlendirme'), findsOneWidget);
    expect(find.textContaining('FTR — Ayşe Yılmaz'), findsOneWidget);
    expect(find.textContaining(_remoteUuid), findsNothing);
    expect(find.textContaining('storage_path'), findsNothing);
    expect(find.textContaining('signed_url'), findsNothing);
    expect(find.textContaining('public_url'), findsNothing);
    expect(find.textContaining('tenant/p1/secret.pdf'), findsNothing);
  });

  testWidgets('fallback does not show source id when referral not found', (
    tester,
  ) async {
    PhysiotherapyReferralRepositoryProvider.testOverride =
        _FakeReferralRepo(returnReferral: false);

    await pumpDetail(tester, _referralSourcePdf(sourceRecordId: _remoteUuid));

    expect(find.text('Yönlendirme kaydı bulunamadı'), findsOneWidget);
    expect(find.textContaining(_remoteUuid), findsNothing);
  });
}
