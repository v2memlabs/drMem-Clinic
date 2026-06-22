import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/features/patients/data/patient_list_state_messages.dart';
import 'package:v2mem_clinic/features/patients/patient_list_screen.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';
import 'package:v2mem_clinic/shared/widgets/clinical_state_message.dart';
import 'package:v2mem_clinic/shared/widgets/empty_state.dart';

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
        GoRoute(path: '/', builder: (context, state) => const PatientListScreen()),
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
            message: 'Hastalar yükleniyor…',
          ),
        ),
      ),
    );
    expect(find.text('Hastalar yükleniyor…'), findsOneWidget);
  });

  testWidgets('list body never uses legacy EmptyState', (tester) async {
    await pumpList(tester);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(EmptyState), findsNothing);
  });

  testWidgets('no-match search shows ClinicalStateMessage.empty', (tester) async {
    await pumpList(tester);
    await tester.pumpAndSettle();

    final search = find.byType(TextField);
    expect(search, findsWidgets);
    await tester.enterText(search.first, '___zz_no_patient___');
    await tester.pumpAndSettle();

    expect(find.byType(ClinicalStateMessage), findsWidgets);
    expect(find.text(PatientListStateMessages.emptySearchTitle), findsOneWidget);
    expect(find.byType(EmptyState), findsNothing);
    expect(find.textContaining('Exception'), findsNothing);
    expect(find.textContaining('stack trace'), findsNothing);
  });
}
