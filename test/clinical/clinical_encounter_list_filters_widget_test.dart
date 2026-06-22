import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/clinical_encounter/widgets/clinical_encounter_list_filters_row.dart';

void main() {
  testWidgets('filters row renders without overflow on narrow width', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
            child: ClinicalEncounterListFiltersRow(
              visitFilter: null,
              statusFilter: null,
              regionFilter: null,
              onVisitChanged: (_) {},
              onStatusChanged: (_) {},
              onRegionChanged: (_) {},
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Başvuru tipi'), findsWidgets);
    expect(find.text('Durum'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('filters row shows short status label in menu', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ClinicalEncounterListFiltersRow(
            visitFilter: null,
            statusFilter: null,
            regionFilter: null,
            onVisitChanged: (_) {},
            onStatusChanged: (_) {},
            onRegionChanged: (_) {},
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Durum'));
    await tester.pumpAndSettle();

    expect(find.text('FTR Yönlendirildi'), findsOneWidget);
  });
}
