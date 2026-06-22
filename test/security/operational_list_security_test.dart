import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/features/consents/consent_list_screen.dart';
import 'package:v2mem_clinic/features/files/file_list_screen.dart';
import 'package:v2mem_clinic/features/inventory/inventory_list_screen.dart';
import 'package:v2mem_clinic/features/payments/payment_list_screen.dart';
import 'package:v2mem_clinic/features/pdf_outputs/pdf_output_list_screen.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';

void main() {
  tearDown(AuthSession.clear);

  final sensitive = [
    'storage_path',
    'signed_url',
    'tenant_id',
    'internalDoctorNote',
    'raw clinical_data',
  ];

  Future<void> pumpScreen(
    WidgetTester tester,
    Widget screen,
  ) async {
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
        GoRoute(path: '/', builder: (context, state) => screen),
      ],
    );

    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
  }

  for (final screen in [
    const PaymentListScreen(),
    const ConsentListScreen(),
    const InventoryListScreen(),
    const PdfOutputListScreen(),
    const FileListScreen(patientId: 'p1'),
  ]) {
    testWidgets('operational list hides sensitive fields: $screen', (tester) async {
      await pumpScreen(tester, screen);
      for (final token in sensitive) {
        expect(find.textContaining(token), findsNothing);
      }
    });
  }
}
