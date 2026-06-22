import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/features/payments/payment_detail_screen.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';
import 'package:v2mem_clinic/shared/widgets/clinical_state_message.dart';

void main() {
  tearDown(AuthSession.clear);

  const sensitive = ['Hasta ID', 'tenant_id', 'profile_id'];

  testWidgets('not-found shows ClinicalStateMessage.empty without technical ids',
      (tester) async {
    AuthSession.setUser(
      AppUser(
        id: 'd1',
        username: 'doc',
        displayName: 'Doc',
        role: AppRoles.doctor,
      ),
    );

    final router = GoRouter(
      initialLocation: '/payments/__nonexistent_payment__',
      routes: [
        GoRoute(
          path: '/payments/:id',
          builder: (context, state) =>
              PaymentDetailScreen(id: state.pathParameters['id']!),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.byType(ClinicalStateMessage), findsWidgets);
    expect(find.text('Ödeme kaydı bulunamadı'), findsOneWidget);
    for (final token in sensitive) {
      expect(find.textContaining(token), findsNothing);
    }
  });
}
