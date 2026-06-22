import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/core/auth/secure_session_startup_gate.dart';
import 'package:v2mem_clinic/features/system/secure_session_preparing_screen.dart';

void main() {
  testWidgets('shows secure preparing screen before app shell', (tester) async {
    await tester.pumpWidget(const SecureSessionStartupGate());

    expect(find.byType(SecureSessionPreparingScreen), findsOneWidget);
    expect(find.text('Güvenli oturum hazırlanıyor…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
