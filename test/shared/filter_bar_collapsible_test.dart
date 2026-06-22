import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/shared/widgets/filter_bar.dart';

void main() {
  test('filtersToggleLabel without active filters', () {
    expect(FilterBar.filtersToggleLabel(0), 'Filtreler');
  });

  test('filtersToggleLabel with active count', () {
    expect(FilterBar.filtersToggleLabel(1), 'Filtreler · 1 aktif');
    expect(FilterBar.filtersToggleLabel(2), 'Filtreler · 2 aktif');
  });

  testWidgets('collapsible filters hidden by default', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FilterBar(
            collapsible: true,
            activeFilterCount: 0,
            filters: const [
              Text('Filter chip'),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Filtreler'), findsOneWidget);
    expect(find.text('Filter chip'), findsNothing);
  });

  testWidgets('collapsible toggle shows and hides filter panel', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FilterBar(
            collapsible: true,
            activeFilterCount: 1,
            filters: const [
              Text('Filter chip'),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Filtreler · 1 aktif'), findsOneWidget);
    expect(find.text('Filter chip'), findsNothing);

    await tester.tap(find.text('Filtreler · 1 aktif'));
    await tester.pumpAndSettle();
    expect(find.text('Filter chip'), findsOneWidget);

    await tester.tap(find.text('Filtreler · 1 aktif'));
    await tester.pumpAndSettle();
    expect(find.text('Filter chip'), findsNothing);
  });

  testWidgets('clear filters button when active', (tester) async {
    var cleared = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FilterBar(
            collapsible: true,
            activeFilterCount: 2,
            onClearFilters: () => cleared = true,
            filters: const [
              Text('Filter chip'),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Filtreleri temizle'), findsOneWidget);
    await tester.tap(find.text('Filtreleri temizle'));
    expect(cleared, isTrue);
  });

  testWidgets('non-collapsible always shows filters', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FilterBar(
            filters: const [
              Text('Always visible'),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Always visible'), findsOneWidget);
    expect(find.text('Filtreler'), findsNothing);
  });

  testWidgets('toolbar controls share exact height', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FilterBar(
            collapsible: true,
            activeFilterCount: 0,
            onSearchChanged: (_) {},
            trailing: FilterBar.primaryTrailing(
              onPressed: () {},
              label: 'Yeni Kayıt',
            ),
            filters: const [
              Text('Status filter'),
            ],
          ),
        ),
      ),
    );

    final searchHeight =
        tester.getSize(find.byKey(const Key('filter_bar_search_shell'))).height;
    final filterHeight =
        tester.getSize(find.widgetWithText(OutlinedButton, 'Filtreler')).height;
    final ctaHeight =
        tester.getSize(find.widgetWithText(FilledButton, 'Yeni Kayıt')).height;

    expect(searchHeight, FilterBar.controlHeight);
    expect(filterHeight, FilterBar.controlHeight);
    expect(ctaHeight, FilterBar.controlHeight);
    expect(searchHeight, filterHeight);
    expect(searchHeight, ctaHeight);
  });

  testWidgets('tablet width search and CTA on same row', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FilterBar(
            collapsible: true,
            activeFilterCount: 0,
            onSearchChanged: (_) {},
            trailing: FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add_rounded),
              label: const Text('Yeni Kayıt'),
            ),
            filters: const [
              Text('Status filter'),
            ],
          ),
        ),
      ),
    );

    final searchRow = find.ancestor(
      of: find.byType(TextField),
      matching: find.byType(Row),
    );
    expect(searchRow, findsWidgets);
    expect(
      find.descendant(of: searchRow.first, matching: find.text('Yeni Kayıt')),
      findsOneWidget,
    );
    expect(find.text('Status filter'), findsNothing);
  });
}
