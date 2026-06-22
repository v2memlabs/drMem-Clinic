import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/features/pdf_outputs/pdf_output_list_screen.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';
import 'package:v2mem_clinic/shared/widgets/clinical_state_message.dart';
import 'package:v2mem_clinic/shared/widgets/empty_state.dart';

void main() {
  tearDown(AuthSession.clear);

  const sensitive = ['storage_path', 'signed_url', 'public_url'];

  testWidgets('empty list shows ClinicalStateMessage with Yeni PDF CTA', (tester) async {
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
        GoRoute(path: '/', builder: (context, state) => const PdfOutputListScreen()),
        GoRoute(
          path: '/pdf-outputs/new',
          builder: (context, state) => const Scaffold(body: Text('new pdf')),
        ),
      ],
    );

    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    final search = find.byType(TextField);
    expect(search, findsWidgets);
    await tester.enterText(search.first, '___no_pdf___');
    await tester.pumpAndSettle();

    expect(find.byType(ClinicalStateMessage), findsWidgets);
    expect(
      find.descendant(
        of: find.byType(ClinicalStateMessage),
        matching: find.text('Yeni PDF Çıktı'),
      ),
      findsOneWidget,
    );
    expect(find.byType(OutlinedButton), findsWidgets);
    expect(find.byType(EmptyState), findsNothing);

    for (final token in sensitive) {
      expect(find.textContaining(token), findsNothing);
    }
  });
}
