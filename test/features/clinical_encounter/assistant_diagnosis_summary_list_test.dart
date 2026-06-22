import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/features/clinical_encounter/clinical_diagnosis_summary_list_screen.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';
import 'package:v2mem_clinic/shared/widgets/access_denied_screen.dart';

void main() {
  tearDown(AuthSession.clear);

  Future<void> pumpList(WidgetTester tester, {required String role}) async {
    AuthSession.setUser(
      AppUser(
        id: 'u-$role',
        username: role,
        displayName: 'Test',
        role: role,
      ),
    );

    await tester.binding.setSurfaceSize(const Size(1200, 900));
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) =>
              const ClinicalDiagnosisSummaryListScreen(),
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
  }

  testWidgets('assistant sees safe summary list fields from mock backend', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpList(tester, role: AppRoles.assistant);

    expect(find.text('Ön tanı/Tanı özeti'), findsWidgets);
    expect(find.text('Ahmet Yılmaz'), findsWidgets);
    expect(
      find.textContaining('Sağ diz medial menisküs dejeneratif yırtık'),
      findsWidgets,
    );

    expect(find.textContaining('internalDoctorNote'), findsNothing);
    expect(find.textContaining('internal_doctor_note'), findsNothing);
    expect(find.textContaining('clinical_data'), findsNothing);
    expect(find.textContaining('İlk basamak konservatif'), findsNothing);
    expect(find.textContaining('ce1'), findsNothing);
    expect(find.textContaining('tenant_id'), findsNothing);
  });

  testWidgets('nurse role cannot view clinical diagnosis summary',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));

    AuthSession.setUser(
      AppUser(
        id: 'n1',
        username: 'nurse',
        displayName: 'Hemşire',
        role: AppRoles.nurse,
      ),
    );

    expect(AuthSession.canViewClinicalDiagnosisSummary, isFalse);

    await tester.binding.setSurfaceSize(const Size(1200, 900));
    final router = GoRouter(
      initialLocation: '/denied',
      routes: [
        GoRoute(
          path: '/denied',
          builder: (context, state) => const AccessDeniedScreen(
            message: 'Tanı özetine bu rol ile erişilemez.',
          ),
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.textContaining('erişilemez'), findsOneWidget);
    expect(find.text('Tanı / Ön Tanı Özeti'), findsNothing);
  });
}
