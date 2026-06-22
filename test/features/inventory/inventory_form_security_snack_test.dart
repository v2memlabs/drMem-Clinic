import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/shared/widgets/clinical_snack_bar.dart';

const _technicalLeak =
    'StorageException public_url storage_bucket debug stackTrace exception';

Future<void> _pumpSnackProbe(
  WidgetTester tester,
  void Function(BuildContext context) showSnack,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: ElevatedButton(
            onPressed: () => showSnack(context),
            child: const Text('Show'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Show'));
  await tester.pump();
}

void main() {
  testWidgets('inventory form snack hides forbidden technical tokens', (tester) async {
    await _pumpSnackProbe(
      tester,
      (context) => showClinicalSnackBar(context, _technicalLeak, isError: true),
    );

    expect(find.textContaining('storage_bucket'), findsNothing);
    expect(find.textContaining('stackTrace'), findsNothing);
    expect(find.text(ClinicalSnackBar.genericErrorMessage), findsOneWidget);
  });

  testWidgets('inventory form snack preserves safe Turkish message', (tester) async {
    await _pumpSnackProbe(
      tester,
      (context) => showClinicalSnackBar(
        context,
        'Stok kartı kaydedilemedi.',
        isError: true,
      ),
    );

    expect(find.text('Stok kartı kaydedilemedi.'), findsOneWidget);
  });
}
