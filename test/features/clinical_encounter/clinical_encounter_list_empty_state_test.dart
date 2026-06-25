import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/features/clinical_encounter/clinical_encounter_list_screen.dart';
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
          builder: (context, state) => const ClinicalEncounterListScreen(),
        ),
        GoRoute(
          path: '/clinical-encounters/new',
          builder: (context, state) => const Scaffold(body: Text('new')),
        ),
      ],
    );

    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
  }

  testWidgets('empty filter shows ClinicalStateMessage with Yeni Muayene action',
      (tester) async {
    await pumpList(tester);

    final search = find.byType(TextField);
    expect(search, findsWidgets);
    await tester.enterText(search.first, '___no_encounter___');
    await tester.pumpAndSettle();

    expect(find.byType(ClinicalStateMessage), findsWidgets);
    expect(
      find.descendant(
        of: find.byType(ClinicalStateMessage),
        matching: find.text('Yeni Muayene'),
      ),
      findsOneWidget,
    );
    expect(find.byType(OutlinedButton), findsWidgets);

    final texts = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data ?? '')
        .join(' ');
    expect(texts.toLowerCase(), isNot(contains('internaldoctornote')));
    expect(texts.toLowerCase(), isNot(contains('clinical_data')));
  });
}
