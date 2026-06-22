import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/shared/widgets/page_header.dart';

void main() {
  testWidgets('PageHeader renders flat title without gradient container', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PageHeader(
            title: 'Test Başlık',
            subtitle: 'Alt başlık',
            leadingBack: true,
            showShellDateTime: false,
          ),
        ),
      ),
    );

    expect(find.text('Test Başlık'), findsOneWidget);
    expect(find.text('Alt başlık'), findsOneWidget);
    expect(find.byType(LinearGradient), findsNothing);
    expect(find.byTooltip('Geri'), findsOneWidget);
    expect(find.text('Geri'), findsNothing);
  });

  testWidgets('PageHeader showDateTime uses DateTimeChip without gradient', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PageHeader(
            title: 'Randevu',
            showDateTime: true,
            showShellDateTime: false,
            dateTime: DateTime(2026, 5, 25, 10, 30),
          ),
        ),
      ),
    );

    await tester.pump();
    expect(find.byType(LinearGradient), findsNothing);
    expect(find.byIcon(Icons.calendar_month_outlined), findsOneWidget);
  });
}
