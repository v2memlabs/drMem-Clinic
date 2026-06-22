import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/shared/widgets/clinical_snack_bar.dart';

const _technicalLeak =
    'PostgREST internalDoctorNote clinical_data raw clinical_data profile_id leak';

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
  testWidgets('inventory movement snack hides forbidden technical tokens', (tester) async {
    await _pumpSnackProbe(
      tester,
      (context) => showClinicalSnackBar(context, _technicalLeak, isError: true),
    );

    expect(find.textContaining('clinical_data'), findsNothing);
    expect(find.textContaining('internalDoctorNote'), findsNothing);
    expect(find.text(ClinicalSnackBar.genericErrorMessage), findsOneWidget);
  });

  testWidgets('inventory movement snack preserves safe Turkish message', (tester) async {
    await _pumpSnackProbe(
      tester,
      (context) => showClinicalSnackBar(
        context,
        'Stok hareketi kaydedilemedi.',
        isError: true,
      ),
    );

    expect(find.text('Stok hareketi kaydedilemedi.'), findsOneWidget);
  });
}
