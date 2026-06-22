import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/features/patients/patient_detail_screen.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';
import 'package:v2mem_clinic/shared/widgets/detail_action_labels.dart';
import 'package:v2mem_clinic/shared/widgets/detail_actions_panel.dart';

void main() {
  tearDown(AuthSession.clear);

  testWidgets('assistant view avoids duplicate list routes in action panel',
      (tester) async {
    AuthSession.setUser(
      AppUser(
        id: 'a1',
        username: 'asst',
        displayName: 'Asistan',
        role: AppRoles.assistant,
      ),
    );

    final router = GoRouter(
      initialLocation: '/patients/p1',
      routes: [
        GoRoute(
          path: '/patients/:id',
          builder: (context, state) =>
              PatientDetailScreen(id: state.pathParameters['id']!),
        ),
      ],
    );

    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.text('Randevular'), findsWidgets);
    expect(find.text('Dosyalar'), findsWidgets);
    expect(find.text('Onamlar'), findsWidgets);
    expect(find.text('Ödeme / Tahsilat'), findsWidgets);

    expect(find.text('Randevu'), findsNothing);
    expect(find.text('Onam'), findsNothing);
    expect(find.text('Dosyayı Görüntüle'), findsNothing);

    if (find.byType(DetailActionsPanel).evaluate().isNotEmpty) {
      final panel = tester.widget<DetailActionsPanel>(
        find.byType(DetailActionsPanel),
      );
      expect(panel.actions.length, lessThanOrEqualTo(1));
      for (final action in panel.actions) {
        expect(action.label, isNot('Randevu'));
        expect(action.label, isNot('Onam'));
        expect(action.label, isNot(DetailActionLabels.viewFile));
        expect(action.label, isNot('Ödeme / Tahsilat'));
      }
    }
  });
}
