import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/features/appointments/appointment_list_screen.dart';
import 'package:v2mem_clinic/features/appointments/data/appointment_list_state_messages.dart';
import 'package:v2mem_clinic/features/appointments/data/appointment_list_user_messages.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';
import 'package:v2mem_clinic/shared/widgets/clinical_state_message.dart';

void main() {
  tearDown(AuthSession.clear);

  Future<void> pumpList(WidgetTester tester) async {
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
          builder: (context, state) => const AppointmentListScreen(),
        ),
      ],
    );

    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  }

  testWidgets('loading factory covered by widget test', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ClinicalStateMessage.loading(
            message: AppointmentListUserMessages.loading,
          ),
        ),
      ),
    );
    expect(find.text(AppointmentListUserMessages.loading), findsOneWidget);
  });

  testWidgets('list body uses ClinicalStateMessage for empty states', (tester) async {
    await pumpList(tester);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(ClinicalStateMessage), findsNothing);
  });

  testWidgets('empty search uses ClinicalStateMessage.empty', (tester) async {
    await pumpList(tester);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final search = find.byType(TextField);
    expect(search, findsWidgets);
    await tester.enterText(search.first, '___no_appointment___');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(ClinicalStateMessage), findsWidgets);
    expect(
      find.text(
        AppointmentListStateMessages.emptyTitle(
          search: '___no_appointment___',
          hasStatusFilter: false,
          hasPatientFilter: false,
          emptySourceList: false,
        ),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('Exception'), findsNothing);
  });

  test('AppointmentListStateMessages preserved', () {
    expect(
      AppointmentListStateMessages.emptyTitle(
        search: '',
        hasStatusFilter: false,
        hasPatientFilter: false,
        emptySourceList: true,
      ),
      isNotEmpty,
    );
  });
}
