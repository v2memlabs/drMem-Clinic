import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/shared/widgets/clinical_snack_bar.dart';

const _technicalLeak =
    'Supabase RLS PostgrestException signed_url service_role stack trace';

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
  testWidgets('consent form snack hides forbidden technical tokens', (tester) async {
    await _pumpSnackProbe(
      tester,
      (context) => showClinicalSnackBar(context, _technicalLeak, isError: true),
    );

    expect(find.textContaining('Supabase'), findsNothing);
    expect(find.textContaining('signed_url'), findsNothing);
    expect(find.textContaining('service_role'), findsNothing);
    expect(find.text(ClinicalSnackBar.genericErrorMessage), findsOneWidget);
  });

  testWidgets('consent form snack preserves safe Turkish message', (tester) async {
    await _pumpSnackProbe(
      tester,
      (context) => showClinicalSnackBar(
        context,
        'Onam kaydı kaydedilemedi.',
        isError: true,
      ),
    );

    expect(find.text('Onam kaydı kaydedilemedi.'), findsOneWidget);
  });
}
