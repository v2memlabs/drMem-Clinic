import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/features/dashboard/doctor_dashboard_screen.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';
import 'package:v2mem_clinic/shared/widgets/dashboard_card.dart';

void main() {
  tearDown(AuthSession.clear);

  testWidgets('doctor workbench shows KPI and no module grid', (tester) async {
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
          builder: (context, state) => const DoctorDashboardScreen(),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Bugün'), findsOneWidget);
    expect(find.textContaining('Workbench'), findsNothing);
    expect(find.byType(FilledButton), findsNothing);
    expect(find.text('Yeni Muayene'), findsOneWidget);
    expect(find.text('Yeni Randevu'), findsOneWidget);
    expect(find.text('PDF Çıktı'), findsOneWidget);
    expect(find.text('Bugün PDF'), findsOneWidget);
    expect(find.textContaining('storage_path'), findsNothing);
    expect(find.textContaining('signed_url'), findsNothing);
    expect(find.textContaining('internalDoctorNote'), findsNothing);
    expect(find.textContaining('Exception'), findsNothing);
    expect(find.text('Hastalar'), findsNothing);
    expect(find.text('Muayene Kayıtları'), findsNothing);
    expect(find.text('Yeni yönlendirmeler'), findsNothing);
    expect(find.text('Bugün randevu'), findsOneWidget);
    expect(find.text('Bugünkü akış'), findsOneWidget);
    expect(find.text('Hızlı işlemler'), findsOneWidget);
    expect(find.text('Tüm randevular'), findsOneWidget);
    expect(find.byType(DashboardCardGrid), findsNothing);
  });
}
