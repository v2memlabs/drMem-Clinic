import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/auth/invite_accept_screen.dart';

void main() {
  testWidgets('invalid deep link shows safe error', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: InviteAcceptScreen(membershipId: 'not-valid'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Davet bağlantısı geçersiz.'), findsOneWidget);
    expect(find.textContaining('mem-'), findsNothing);
  });
}
