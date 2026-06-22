import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/shared/widgets/clinical_state_message.dart';

void main() {
  testWidgets('error UI does not render raw exception text', (tester) async {
    const raw = 'SocketException: Failed host lookup';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ClinicalStateMessage.error(
            icon: Icons.error_outline,
            title: 'Liste yüklenemedi',
            description: ClinicalStateMessage.safeErrorDescription(raw),
            onRetry: () {},
          ),
        ),
      ),
    );

    expect(find.textContaining('SocketException'), findsNothing);
    expect(find.textContaining('Failed host'), findsNothing);
    expect(find.text(ClinicalStateMessage.genericLoadFailure), findsOneWidget);
  });
}
