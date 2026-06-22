import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/features/settings/clinic_workflow_settings_screen.dart';
import 'package:v2mem_clinic/features/settings/data/clinic_workflow_settings_repository.dart';
import 'package:v2mem_clinic/features/settings/data/clinic_workflow_settings_repository_provider.dart';
import 'package:v2mem_clinic/features/settings/models/clinic_workflow_settings.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';

class _RecordingWorkflowRepo implements ClinicWorkflowSettingsRepository {
  _RecordingWorkflowRepo({this.stored});

  ClinicWorkflowSettings? stored;
  int saveCount = 0;

  @override
  Future<ClinicWorkflowSettings?> load() async => stored;

  @override
  Future<void> save(ClinicWorkflowSettings settings) async {
    saveCount++;
    stored = settings;
  }
}

void main() {
  tearDown(() {
    AuthSession.clear();
    ClinicWorkflowSettingsRepositoryProvider.testOverride = null;
  });

  Future<void> pumpScreen(WidgetTester tester, {required String role}) async {
    AuthSession.setUser(
      AppUser(
        id: 'u1',
        username: 'test',
        displayName: 'Test',
        role: role,
      ),
    );

    final router = GoRouter(
      initialLocation: '/settings/clinic-workflow',
      routes: [
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SizedBox.shrink(),
        ),
        GoRoute(
          path: '/settings/clinic-workflow',
          builder: (context, state) => const ClinicWorkflowSettingsScreen(),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
  }

  group('ClinicWorkflowSettingsScreen', () {
    testWidgets('doctor can edit and save', (tester) async {
      final repo = _RecordingWorkflowRepo(
        stored: ClinicWorkflowSettings.defaultClinic(),
      );
      ClinicWorkflowSettingsRepositoryProvider.testOverride = repo;

      await tester.binding.setSurfaceSize(const Size(900, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await pumpScreen(tester, role: AppRoles.doctor);

      expect(
        find.textContaining('müsait saatler bu ayarlara göre'),
        findsOneWidget,
      );
      expect(find.text('Kaydet'), findsOneWidget);
      expect(find.byType(DropdownButtonFormField<int>), findsOneWidget);
      expect(find.byType(Switch), findsWidgets);

      await tester.ensureVisible(find.text('Kaydet'));
      await tester.tap(find.text('Kaydet'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(repo.saveCount, 1);
    });

    testWidgets('assistant sees read-only without save', (tester) async {
      ClinicWorkflowSettingsRepositoryProvider.testOverride =
          _RecordingWorkflowRepo(
        stored: ClinicWorkflowSettings.defaultClinic(),
      );

      await tester.binding.setSurfaceSize(const Size(900, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await pumpScreen(tester, role: AppRoles.assistant);

      expect(find.text('Kaydet'), findsNothing);
      expect(
        find.textContaining('Görüntüleme modundasınız'),
        findsOneWidget,
      );
      expect(find.text('Pazartesi'), findsOneWidget);
    });

    testWidgets('slot duration dropdown visible', (tester) async {
      ClinicWorkflowSettingsRepositoryProvider.testOverride =
          _RecordingWorkflowRepo(
        stored: ClinicWorkflowSettings(
          slotDurationMinutes: 45,
          lunchBreak: ClinicWorkflowSettings.defaultClinic().lunchBreak,
          weekdays: ClinicWorkflowSettings.defaultClinic().weekdays,
        ),
      );

      await tester.binding.setSurfaceSize(const Size(900, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await pumpScreen(tester, role: AppRoles.doctor);
      expect(find.text('45 dakika'), findsOneWidget);
    });

    testWidgets('closed date can be removed when editable', (tester) async {
      ClinicWorkflowSettingsRepositoryProvider.testOverride =
          _RecordingWorkflowRepo(
        stored: ClinicWorkflowSettings(
          slotDurationMinutes: 30,
          lunchBreak: ClinicWorkflowSettings.defaultClinic().lunchBreak,
          weekdays: ClinicWorkflowSettings.defaultClinic().weekdays,
          closedDates: [DateTime(2026, 1, 1)],
        ),
      );

      await tester.binding.setSurfaceSize(const Size(900, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await pumpScreen(tester, role: AppRoles.doctor);
      expect(find.textContaining('1 Ocak 2026'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      expect(find.textContaining('1 Ocak 2026'), findsNothing);
    });
  });
}
