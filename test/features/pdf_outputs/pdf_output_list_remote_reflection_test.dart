import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/features/pdf_outputs/data/async_pdf_output_repository_contract.dart';
import 'package:v2mem_clinic/features/pdf_outputs/data/pdf_output_repository_provider.dart';
import 'package:v2mem_clinic/features/pdf_outputs/models/pdf_output.dart';
import 'package:v2mem_clinic/features/pdf_outputs/pdf_output_list_screen.dart';
import 'package:v2mem_clinic/features/pdf_outputs/widgets/pdf_output_clinical_list_row.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';
import 'package:v2mem_clinic/shared/widgets/clinical_separated_list_body.dart';

PdfOutput _remoteOutput({
  required String id,
  String patientId = 'p1',
  String title = 'Remote PDF Başlık',
}) {
  return PdfOutput(
    id: id,
    patientId: patientId,
    patientName: 'Remote Hasta',
    createdAt: DateTime(2026, 6, 2),
    documentType: DocumentType.muayeneOzeti,
    title: title,
    contentSummary: 'Listedeki gizli özet',
    warningNote: '',
    createdBy: 'Dr. Remote',
    status: PdfStatus.hazirlandi,
    storagePath: 'tenant/p1/$id.pdf',
    storageBucket: 'patient-files-private',
    sourceModule: pdfSourceModuleAppointment,
    sourceRecordId: 'appt-1',
  );
}

class _FakePdfOutputRepo implements AsyncPdfOutputRepositoryContract {
  _FakePdfOutputRepo(this._items);

  final List<PdfOutput> _items;

  @override
  Future<List<PdfOutput>> getAll() async => List.unmodifiable(_items);

  @override
  Future<PdfOutput?> getById(String id) async {
    for (final item in _items) {
      if (item.id == id) return item;
    }
    return null;
  }

  @override
  Future<List<PdfOutput>> getByPatientId(String patientId) async =>
      _items.where((p) => p.patientId == patientId).toList();

  @override
  Future<List<PdfOutput>> search(String query) async {
    final q = query.toLowerCase();
    return _items.where((p) => p.title.toLowerCase().contains(q)).toList();
  }
}

void main() {
  tearDown(() {
    AuthSession.clear();
    PdfOutputRepositoryProvider.testOverride = null;
    PdfOutputRepositoryProvider.resetCache();
  });

  Future<void> pumpList(WidgetTester tester) async {
    AuthSession.setUser(
      AppUser(
        id: 'd1',
        username: 'doc',
        displayName: 'Doc',
        role: AppRoles.doctor,
      ),
    );

    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final router = GoRouter(
      initialLocation: '/pdf-outputs',
      routes: [
        GoRoute(
          path: '/pdf-outputs',
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

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
  }

  group('PDF output list remote reflection', () {
    testWidgets('shows remote records in clinical list body without leaks',
        (tester) async {
      PdfOutputRepositoryProvider.testOverride = _FakePdfOutputRepo([
        _remoteOutput(id: 'pdf-remote-1'),
      ]);

      await pumpList(tester);

      expect(find.byType(PdfOutputClinicalListRow), findsOneWidget);
      expect(find.byType(ClinicalSeparatedListBody), findsOneWidget);
      expect(find.text('Remote PDF Başlık'), findsOneWidget);
      expect(find.textContaining('Listedeki gizli özet'), findsNothing);
      expect(find.textContaining('storage_path'), findsNothing);
      expect(find.textContaining('signed_url'), findsNothing);
      expect(find.textContaining('public_url'), findsNothing);
      expect(find.textContaining('tenant/p1'), findsNothing);
      expect(find.textContaining('appt-1'), findsNothing);

      await tester.tap(find.byType(PdfOutputClinicalListRow).first);
      await tester.pumpAndSettle();
      expect(find.text('PDF pdf-remote-1'), findsOneWidget);
    });
  });
}
