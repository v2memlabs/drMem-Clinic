import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/features/dashboard/assistant_dashboard_screen.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';
import 'package:v2mem_clinic/shared/widgets/dashboard_card.dart';

void main() {
  tearDown(AuthSession.clear);

  testWidgets('assistant workbench has operational CTAs not full clinical',
      (tester) async {
    AuthSession.setUser(
      AppUser(
        id: 'a1',
        username: 'asst',
        displayName: 'Asst',
        role: AppRoles.assistant,
      ),
    );

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const AssistantDashboardScreen(),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Operasyon'), findsOneWidget);
    expect(find.textContaining('Workbench'), findsNothing);
    expect(find.byType(FilledButton), findsNothing);
    expect(find.text('Yeni Randevu'), findsOneWidget);
    expect(find.text('KVKK / Onam'), findsOneWidget);
    expect(find.text('Ödeme'), findsOneWidget);
    expect(find.text('Dosya Yükle'), findsOneWidget);
    expect(find.text('Hastalar'), findsNothing);
    expect(find.text('Randevular'), findsNothing);
    expect(find.text('Tanı / Ön Tanı Özeti'), findsNothing);
    expect(find.text('Muayene Kayıtları'), findsNothing);
    expect(find.text('Yeni Muayene'), findsNothing);
    expect(find.byType(DashboardCardGrid), findsNothing);
  });
}
