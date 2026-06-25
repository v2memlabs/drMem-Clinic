import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/features/consents/consent_list_screen.dart';
import 'package:v2mem_clinic/features/inventory/inventory_list_screen.dart';
import 'package:v2mem_clinic/features/payments/payment_list_screen.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';
import 'package:v2mem_clinic/shared/widgets/clinical_state_message.dart';

void main() {
  tearDown(AuthSession.clear);

  Future<void> pumpScreen(WidgetTester tester, Widget screen) async {
    AuthSession.setUser(
      AppUser(
        id: 'd1',
        username: 'doc',
        displayName: 'Doc',
        role: AppRoles.doctor,
      ),
    );

    final router = GoRouter(
      routes: [GoRoute(path: '/', builder: (context, state) => screen)],
    );

    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
  }

  for (final entry in <String, Widget>{
    'payment': const PaymentListScreen(),
    'consent': const ConsentListScreen(),
    'inventory': const InventoryListScreen(),
  }.entries) {
    testWidgets('${entry.key} empty filter uses ClinicalStateMessage', (tester) async {
      await pumpScreen(tester, entry.value);

      final search = find.byType(TextField);
      expect(search, findsWidgets);
      await tester.enterText(search.first, '___no_match___');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(find.byType(ClinicalStateMessage), findsWidgets);
    });
  }
}
