import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/shared/widgets/clinical_snack_bar.dart';

const _technicalLeak =
    'PostgREST AuthException tenant_id=abc storage_path secret JWT token';

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
  testWidgets('payment form snack hides forbidden technical tokens', (tester) async {
    await _pumpSnackProbe(
      tester,
      (context) => showClinicalSnackBar(context, _technicalLeak, isError: true),
    );

    expect(find.textContaining('tenant_id'), findsNothing);
    expect(find.textContaining('PostgREST'), findsNothing);
    expect(find.textContaining('JWT'), findsNothing);
    expect(find.text(ClinicalSnackBar.genericErrorMessage), findsOneWidget);
  });

  testWidgets('payment form snack preserves safe Turkish message', (tester) async {
    await _pumpSnackProbe(
      tester,
      (context) => showClinicalSnackBar(
        context,
        'Ödeme kaydı kaydedilemedi.',
        isError: true,
      ),
    );

    expect(find.text('Ödeme kaydı kaydedilemedi.'), findsOneWidget);
  });
}
