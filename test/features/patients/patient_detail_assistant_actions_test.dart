import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/features/patients/patient_detail_screen.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';
import 'package:v2mem_clinic/shared/widgets/detail_actions_panel.dart';

void main() {
  tearDown(AuthSession.clear);

  testWidgets('assistant view shows all operational links once in patient actions',
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

    expect(find.text('Hasta İşlemleri'), findsOneWidget);
    expect(find.text('Randevular'), findsWidgets);
    expect(find.text('Dosyalar'), findsNothing);
    expect(find.text('Tümünü gör'), findsOneWidget);
    expect(find.text('Onamlar'), findsOneWidget);
    expect(find.text('Ödeme / Tahsilat'), findsOneWidget);
    expect(find.text('Tüm özetler'), findsOneWidget);
    expect(find.text('Mesajlar'), findsOneWidget);
    expect(find.text('Hasta Etiketleri'), findsOneWidget);
    expect(find.text('Malzeme Şarjı'), findsOneWidget);

    expect(find.text('Hızlı Erişim'), findsNothing);
    expect(find.byType(DetailActionsPanel), findsNothing);
  });
}
