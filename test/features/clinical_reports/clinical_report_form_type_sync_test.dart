import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/features/clinical_reports/clinical_report_form_screen.dart';
import 'package:v2mem_clinic/features/clinical_reports/models/clinical_report.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';

void main() {
  tearDown(AuthSession.clear);

  Future<void> pumpReportForm(WidgetTester tester) async {
    AuthSession.setUser(
      AppUser(
        id: 'd1',
        username: 'doc',
        displayName: 'Doc',
        role: AppRoles.doctor,
      ),
    );

    await tester.binding.setSurfaceSize(const Size(900, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final router = GoRouter(
      initialLocation: '/clinical-reports/new?patientId=p-test-1',
      routes: [
        GoRoute(
          path: '/clinical-reports/new',
          builder: (context, state) {
            final params = Uri.parse(state.location).queryParameters;
            return ClinicalReportFormScreen(patientId: params['patientId']);
          },
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> selectReportType(
    WidgetTester tester,
    ClinicalReportType type,
  ) async {
    final dropdown = find.byWidgetPredicate(
      (widget) =>
          widget is DropdownButtonFormField<ClinicalReportType> &&
          widget.decoration?.labelText == 'Rapor tipi',
    );
    expect(dropdown, findsOneWidget);

    await tester.tap(dropdown);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    final label = clinicalReportTypeLabel(type);
    final menuItem = find.text(label).last;
    await tester.ensureVisible(menuItem);
    await tester.tap(menuItem);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
  }

  group('ClinicalReportFormScreen type sync', () {
    testWidgets('uses clinical form scaffold layout', (tester) async {
      await pumpReportForm(tester);

      expect(find.text('Yeni Rapor'), findsOneWidget);
      expect(find.text('Hasta ve Rapor Tipi'), findsOneWidget);
      expect(find.text('İptal'), findsOneWidget);
      expect(find.text('Kaydet'), findsOneWidget);
    });

    testWidgets('default istirahat shows istirahat fields', (tester) async {
      await pumpReportForm(tester);

      expect(find.text('İstirahat Bilgileri'), findsOneWidget);
      expect(find.text('Durum Bildirir Bilgileri'), findsNothing);
      expect(find.text('Uçuş Değerlendirmesi'), findsNothing);
    });

    testWidgets('switching to durum bildirir swaps type-specific section',
        (tester) async {
      await pumpReportForm(tester);

      await selectReportType(tester, ClinicalReportType.durumBildirir);

      expect(find.text('Durum Bildirir Bilgileri'), findsOneWidget);
      expect(find.text('İstirahat Bilgileri'), findsNothing);
    });

    testWidgets('switching to ucabilir swaps type-specific section',
        (tester) async {
      await pumpReportForm(tester);

      await selectReportType(tester, ClinicalReportType.ucabilir);

      expect(find.text('Uçuş Değerlendirmesi'), findsOneWidget);
      expect(find.text('İstirahat Bilgileri'), findsNothing);
    });

    testWidgets('diagnosis change refreshes istirahat body template',
        (tester) async {
      await pumpReportForm(tester);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Tanı'),
        'Sağ diz ağrısı',
      );
      await tester.pump();

      final bodyField = tester.widget<TextFormField>(
        find.widgetWithText(
          TextFormField,
          'Metin (yalnızca hitap satırı girintili)',
        ),
      );
      expect(bodyField.controller?.text, contains('Sağ diz ağrısı'));
    });

    testWidgets('diger type hides structured type sections', (tester) async {
      await pumpReportForm(tester);

      await selectReportType(tester, ClinicalReportType.diger);

      expect(find.text('İstirahat Bilgileri'), findsNothing);
      expect(find.text('Durum Bildirir Bilgileri'), findsNothing);
      expect(
        find.widgetWithText(TextFormField, 'Serbest metin'),
        findsOneWidget,
      );
    });
  });
}
