import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/features/consents/consent_form_screen.dart';
import 'package:v2mem_clinic/features/consents/models/consent_record.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';

void main() {
  tearDown(AuthSession.clear);

  testWidgets('consent form shows user-friendly labels without placeholder', (tester) async {
    AuthSession.setUser(
      AppUser(
        id: 'u1',
        username: 'asst',
        displayName: 'Asistan',
        role: AppRoles.assistant,
      ),
    );

    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (context, state) => const ConsentFormScreen()),
      ],
    );

    await tester.binding.setSurfaceSize(const Size(900, 900));
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.textContaining('(placeholder)'), findsNothing);
    expect(find.text('Onam Evrakı Hazırla'), findsWidgets);
    expect(find.text('Evrak Oluştur'), findsOneWidget);
    expect(
      find.textContaining('antetli PDF evrakı oluşturulur'),
      findsOneWidget,
    );
    expect(find.text(consentStatusLabel(ConsentStatus.bekliyor)), findsOneWidget);

    expect(find.text('kvkkAydinlatma'), findsNothing);
    expect(find.text('bekliyor'), findsNothing);

    await tester.tap(find.byType(DropdownButtonFormField<ConsentType>));
    await tester.pumpAndSettle();

    expect(find.text(consentTypeLabel(ConsentType.kvkkAydinlatma)), findsWidgets);
    expect(find.text('acikRiza'), findsNothing);
  });
}
