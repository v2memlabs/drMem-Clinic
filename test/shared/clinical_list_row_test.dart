import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/shared/widgets/clinical_list_row.dart';
import 'package:v2mem_clinic/shared/widgets/clinical_list_panel.dart';
import 'package:v2mem_clinic/shared/widgets/clinical_status_legend.dart';
import 'package:v2mem_clinic/shared/widgets/status_chip.dart';

void main() {
  testWidgets('ClinicalListRow renders title meta and chips', (tester) async {
  var tapped = false;
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ClinicalListRow(
          title: 'YALÇINOZAN, Mehmet',
          demographicLine: '45 yaş · E · Dosya: P-1024',
          subtitle: 'Kontrol',
          metaLines: const ['Sol diz ağrısı'],
          tags: const ['Sporcu', 'Post-op', 'Diz', 'Ekstra'],
          maxVisibleTags: 2,
          semanticChipLabel: 'Gelmedi',
          semanticChipTone: StatusChipTone.danger,
          showSemanticStatusChip: true,
          statusMarkerColor: const Color(0xFFE53935),
          trailing: '14:30',
          onTap: () => tapped = true,
        ),
      ),
    ),
  );

  expect(find.text('YALÇINOZAN, Mehmet'), findsOneWidget);
  expect(find.text('45 yaş · E · Dosya: P-1024'), findsOneWidget);
  expect(find.text('Gelmedi'), findsOneWidget);
  expect(find.text('Sporcu'), findsOneWidget);
  expect(find.text('+2 etiket'), findsOneWidget);
  expect(find.text('14:30'), findsOneWidget);

  await tester.tap(find.text('YALÇINOZAN, Mehmet'));
  expect(tapped, isTrue);
});

  testWidgets('ClinicalListPanel uses dividers not card gaps', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ClinicalListPanel(
            children: const [
              Text('Row A'),
              Text('Row B'),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(Divider), findsWidgets);
    expect(find.text('Row A'), findsOneWidget);
  });

  testWidgets('ClinicalStatusLegend renders entries', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ClinicalStatusLegend(
            items: [
              ClinicalStatusLegendItem(
                label: 'Planlandı',
                tone: StatusChipTone.warning,
              ),
              ClinicalStatusLegendItem(
                label: 'Geldi',
                tone: StatusChipTone.success,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Durum renkleri'), findsOneWidget);
    expect(find.text('Planlandı'), findsOneWidget);
    expect(find.text('Geldi'), findsOneWidget);
  });

  testWidgets('disabled row does not invoke onTap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ClinicalListRow(
            title: 'Test',
            enabled: false,
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Test'));
    expect(tapped, isFalse);
  });
}
