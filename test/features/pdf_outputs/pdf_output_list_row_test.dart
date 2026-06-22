import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/features/pdf_outputs/models/pdf_output.dart';
import 'package:v2mem_clinic/features/pdf_outputs/pdf_output_list_screen.dart';
import 'package:v2mem_clinic/features/pdf_outputs/widgets/pdf_output_clinical_list_row.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';
import 'package:v2mem_clinic/shared/widgets/clinical_list_row.dart';
import 'package:v2mem_clinic/shared/widgets/clinical_separated_list_body.dart';
import 'package:v2mem_clinic/shared/widgets/pdf_document_card.dart';
import 'package:v2mem_clinic/shared/widgets/status_chip.dart';

void main() {
  tearDown(AuthSession.clear);

  const sensitive = [
    'storage_path',
    'storage_bucket',
    'signed_url',
    'public_url',
    'tenant_id',
  ];

  testWidgets('pdf output list uses clinical rows not PdfDocumentCard',
      (tester) async {
    AuthSession.setUser(
      AppUser(
        id: 'd1',
        username: 'doc',
        displayName: 'Doc',
        role: AppRoles.doctor,
      ),
    );

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const PdfOutputListScreen(),
        ),
        GoRoute(
          path: '/pdf-outputs/:id',
          builder: (context, state) => Scaffold(
            body: Text('PDF ${state.pathParameters['id']}'),
          ),
        ),
      ],
    );

    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(PdfOutputClinicalListRow), findsWidgets);
    expect(find.byType(ClinicalSeparatedListBody), findsWidgets);
    expect(find.byType(PdfDocumentCard), findsNothing);

    for (final token in sensitive) {
      expect(find.textContaining(token), findsNothing);
    }

    await tester.tap(find.text('Muayene Özeti - Diz Ağrısı'));
    await tester.pumpAndSettle();
    expect(find.text('PDF pdf1'), findsOneWidget);
  });

  testWidgets('hazirlandi pdf hides semantic status chip', (tester) async {
    final output = PdfOutput(
      id: 'pdf-test',
      patientId: 'p1',
      patientName: 'Test Hasta',
      createdAt: DateTime(2026, 1, 15),
      documentType: DocumentType.muayeneOzeti,
      title: 'Test Özet',
      contentSummary: 'Özet içerik listede görünmemeli',
      warningNote: '',
      createdBy: 'Dr. Test',
      status: PdfStatus.hazirlandi,
      storagePath: 'tenant/patient/secret.pdf',
      storageBucket: 'patient-files-private',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PdfOutputClinicalListRow(
            output: output,
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.text('Hazırlandı'), findsNothing);
    expect(find.textContaining('Özet içerik'), findsNothing);
    expect(find.textContaining('secret.pdf'), findsNothing);
    expect(find.text('PDF'), findsOneWidget);
  });

  testWidgets('taslak pdf shows semantic status chip', (tester) async {
    final output = PdfOutput(
      id: 'pdf-draft',
      patientId: 'p1',
      patientName: 'Test Hasta',
      createdAt: DateTime(2026, 1, 15),
      documentType: DocumentType.muayeneOzeti,
      title: 'Taslak Belge',
      contentSummary: 'Gizli özet',
      warningNote: '',
      createdBy: 'Dr. Test',
      status: PdfStatus.taslak,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PdfOutputClinicalListRow(
            output: output,
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.text('Taslak'), findsOneWidget);
    expect(find.text('PDF'), findsOneWidget);
    expect(find.textContaining('Gizli özet'), findsNothing);
  });
}
