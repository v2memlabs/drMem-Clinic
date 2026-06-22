import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/shared/widgets/form_section_card.dart';

void main() {
  testWidgets('FormSectionCard has no gradient decoration', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FormSectionCard(
            title: 'Bölüm',
            subtitle: 'Açıklama',
            children: [
              TextField(decoration: InputDecoration(labelText: 'Alan')),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Bölüm'), findsOneWidget);
    expect(find.byType(LinearGradient), findsNothing);
  });
}
