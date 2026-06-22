import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/shared/widgets/date_time_chip.dart';

void main() {
  testWidgets('DateTimeChip has no gradient', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DateTimeChip(dateTime: DateTime(2026, 6, 1, 14, 0)),
        ),
      ),
    );

    await tester.pump();
    expect(find.byType(LinearGradient), findsNothing);
    expect(find.byIcon(Icons.schedule_outlined), findsOneWidget);
  });
}
