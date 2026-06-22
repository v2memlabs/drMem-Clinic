import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/auth/user_display_names.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/features/surgery/data/surgery_procedure_list_display.dart';
import 'package:v2mem_clinic/features/surgery/models/surgery_procedure_note.dart';
import 'package:v2mem_clinic/features/surgery/data/mock_async_surgery_procedure_note_repository_adapter.dart';
import 'package:v2mem_clinic/features/surgery/data/surgery_procedure_note_repository_provider.dart';
import 'package:v2mem_clinic/features/surgery/surgery_note_list_screen.dart';
import 'package:v2mem_clinic/features/surgery/widgets/surgery_procedure_clinical_list_row.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';
import 'package:v2mem_clinic/shared/widgets/clinical_status_legend.dart';
import 'package:v2mem_clinic/shared/widgets/data_list_card.dart';

SurgeryProcedureNote _note({
  ProcedureType type = ProcedureType.ameliyat,
}) {
  return SurgeryProcedureNote(
    id: 's1',
    patientId: 'p1',
    patientName: 'Ayşe Çalışkan',
    procedureDate: DateTime(2026, 3, 12),
    procedureType: type,
    bodyRegion: SurgeryBodyRegion.diz,
    side: SurgerySide.sag,
    diagnosis: 'Menisküs yırtığı',
    procedureName: 'Artroskopik meniskektomi',
    anesthesiaType: '',
    implantOrMaterialInfo: '',
    arthroscopyFindings: '',
    procedureDetails: '',
    complications: '',
    postOpRecommendations: '',
    physiotherapyStartRecommendation: '',
    controlSchedule: '',
    surgeonName: 'Op. Dr. Mehmet Yılmaz',
    assistantInfo: '',
  );
}

void main() {
  tearDown(() {
    AuthSession.clear();
    SurgeryProcedureNoteRepositoryProvider.testOverride = null;
    SurgeryProcedureNoteRepositoryProvider.resetCache();
  });

  setUp(() {
    SurgeryProcedureNoteRepositoryProvider.resetCache();
    SurgeryProcedureNoteRepositoryProvider.testOverride =
        MockAsyncSurgeryProcedureNoteRepositoryAdapter();
  });

  test('procedure note label and implant encoding', () {
    expect(
      procedureNoteFieldLabel(ProcedureType.ameliyat),
      'Ameliyat Notu',
    );
    expect(
      procedureNoteFieldLabel(ProcedureType.artroskopi),
      'İşlem Detayları',
    );
    expect(
      encodeImplantMaterialLines(['Vida 4.5', '  ', 'Plak']),
      'Vida 4.5\nPlak',
    );
    expect(
      decodeImplantMaterialLines('Vida 4.5\nPlak'),
      ['Vida 4.5', 'Plak'],
    );
  });

  test('procedure type maps to list color categories', () {
    expect(
      SurgeryProcedureListDisplay.listCategoryForType(ProcedureType.ameliyat),
      SurgeryProcedureListCategory.ameliyat,
    );
    expect(
      SurgeryProcedureListDisplay.listCategoryForType(ProcedureType.artroskopi),
      SurgeryProcedureListCategory.girisim,
    );
    expect(
      SurgeryProcedureListDisplay.listCategoryForType(
        ProcedureType.kontrolAmacli,
      ),
      SurgeryProcedureListCategory.islem,
    );
    expect(
      SurgeryProcedureListDisplay.listCategoryForType(
        ProcedureType.yaraPansuman,
      ),
      SurgeryProcedureListCategory.pansuman,
    );
  });

  test('meta and detail lines format without type chips', () {
    expect(
      SurgeryProcedureListDisplay.metaLine(
        fileNumber: 'A-1042',
        diagnosis: 'Menisküs yırtığı',
      ),
      'Dosya: A-1042 · Menisküs yırtığı',
    );
    expect(
      SurgeryProcedureListDisplay.detailLine(
        procedureName: 'Artroskopik meniskektomi',
        surgeonName: 'Op. Dr. Mehmet Yılmaz',
      ),
      'Artroskopik meniskektomi · Cerrah: Op. Dr. Mehmet Yılmaz',
    );
  });

  testWidgets('clinical row shows two-line layout without DataListCard', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SurgeryProcedureClinicalListRow(
            note: _note(),
            onTap: () {},
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(DataListCard), findsNothing);
    expect(find.textContaining('Artroskopik meniskektomi'), findsOneWidget);
    expect(find.textContaining('Cerrah:'), findsOneWidget);
    expect(find.text('12.03.2026'), findsOneWidget);
    expect(find.text('Ameliyat'), findsNothing);
    expect(find.text('Tanı:'), findsNothing);
  });

  testWidgets('list screen shows procedure color legend at bottom', (
    tester,
  ) async {
    AuthSession.setUser(
      AppUser(
        id: 'd1',
        username: 'doc',
        displayName: UserDisplayNames.mockDoctorLabel,
        role: AppRoles.doctor,
      ),
    );

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const SurgeryNoteListScreen(),
        ),
      ],
    );

    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    for (var i = 0; i < 50; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.byType(SurgeryProcedureClinicalListRow).evaluate().isNotEmpty) {
        break;
      }
    }

    expect(find.byType(SurgeryProcedureClinicalListRow), findsWidgets);
    expect(find.byType(ClinicalStatusLegend), findsOneWidget);
    expect(find.text('İşlem renkleri'), findsOneWidget);
    expect(find.text('Ameliyat'), findsOneWidget);
    expect(find.text('Girişim'), findsOneWidget);
    expect(find.text('İşlem'), findsOneWidget);
    expect(find.text('Pansuman'), findsOneWidget);
  });
}
