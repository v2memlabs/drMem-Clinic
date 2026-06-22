import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/core/saas/active_tenant_context.dart';
import 'package:v2mem_clinic/core/saas/membership.dart';
import 'package:v2mem_clinic/core/saas/tenant.dart';
import 'package:v2mem_clinic/core/saas/user_profile.dart';
import 'package:v2mem_clinic/core/session/active_tenant_context_store.dart';
import 'package:v2mem_clinic/features/consents/consent_form_screen.dart';
import 'package:v2mem_clinic/features/consents/data/consent_repository.dart';
import 'package:v2mem_clinic/features/patient_files/data/mock_patient_file_storage_repository.dart';
import 'package:v2mem_clinic/features/patient_files/data/patient_file_storage_repository_provider.dart';
import 'package:v2mem_clinic/features/pdf_outputs/data/pdf_output_repository.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    AuthSession.clear();
    ActiveTenantContextStore.clearSilently();
    MockPatientFileStorageRepository.clearAll();
    PatientFileStorageRepositoryProvider.testOverride = null;
  });

  void setAssistant() {
    AuthSession.setUser(
      AppUser(
        id: 'u1',
        username: 'asst',
        displayName: 'Asistan',
        role: AppRoles.assistant,
      ),
    );
    ActiveTenantContextStore.set(
      ActiveTenantContext(
        tenant: const Tenant(id: 'tenant-a', name: 'Test Klinik'),
        membership: const Membership(
          id: 'm1',
          tenantId: 'tenant-a',
          userId: 'u1',
          role: 'assistant',
        ),
        profile: const UserProfile(userId: 'u1', displayName: 'Asistan'),
      ),
    );
  }

  testWidgets('consent form creates PDF document for selected patient',
      (tester) async {
    setAssistant();
    PatientFileStorageRepositoryProvider.testOverride =
        MockPatientFileStorageRepository();

    final consentBefore = ConsentRepository.instance.getAll().length;
    final pdfBefore = PdfOutputRepository.instance.getAll().length;

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const ConsentFormScreen(patientId: 'p1'),
        ),
        GoRoute(
          path: '/consents',
          builder: (context, state) =>
              const Scaffold(body: Text('Consent list')),
        ),
      ],
    );

    await tester.binding.setSurfaceSize(const Size(1200, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('Kullanılacak şablon'), findsOneWidget);

    await tester.tap(find.text('Evrak Oluştur'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('Consent list'), findsOneWidget);
    expect(ConsentRepository.instance.getAll().length, consentBefore + 1);
    expect(PdfOutputRepository.instance.getAll().length, pdfBefore + 1);
    expect(MockPatientFileStorageRepository.pathToBytes, isNotEmpty);
    expect(find.textContaining('onam evrakı oluşturuldu'), findsOneWidget);
  });
}
