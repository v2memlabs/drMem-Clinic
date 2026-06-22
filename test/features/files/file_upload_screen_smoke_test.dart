import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/features/files/file_upload_screen.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';

void main() {
  tearDown(AuthSession.clear);

  testWidgets('file upload screen renders without technical error strings', (
    tester,
  ) async {
    AuthSession.setUser(
      AppUser(
        id: 'u1',
        username: 'doc',
        displayName: 'Dr.',
        role: AppRoles.doctor,
      ),
    );

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const FileUploadScreen(),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.text('Dosya Yükle'), findsWidgets);
    expect(find.textContaining('storage_path'), findsNothing);
    expect(find.textContaining('signed_url'), findsNothing);
    expect(find.textContaining('public_url'), findsNothing);
    expect(find.textContaining('Supabase'), findsNothing);
  });
}
