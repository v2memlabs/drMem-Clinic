import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/shared/widgets/clinical_state_message.dart';

const _forbiddenPattern = r'(Supabase|RLS|JWT|tenant_id|storage_path|signed_url|public_url)';

void main() {
  testWidgets('loading factory shows spinner', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ClinicalStateMessage.loading(message: 'Yükleniyor…'),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Yükleniyor…'), findsOneWidget);
  });

  testWidgets('empty factory renders title and description', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ClinicalStateMessage.empty(
            icon: Icons.inbox_outlined,
            title: 'Henüz kayıt bulunmuyor.',
            description: 'Filtreleri değiştirin.',
          ),
        ),
      ),
    );

    expect(find.text('Henüz kayıt bulunmuyor.'), findsOneWidget);
    expect(find.text('Filtreleri değiştirin.'), findsOneWidget);
  });

  testWidgets('notConfigured factory renders', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ClinicalStateMessage.notConfigured(
            icon: Icons.cloud_off_outlined,
            title: 'Bu alan henüz etkin değil.',
            description: 'Kayıtlar etkinleştirildiğinde görünecek.',
          ),
        ),
      ),
    );

    expect(find.text('Bu alan henüz etkin değil.'), findsOneWidget);
  });

  testWidgets('error factory shows retry action', (tester) async {
    var retried = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ClinicalStateMessage.error(
            icon: Icons.error_outline,
            title: 'Yüklenemedi',
            description: 'Lütfen tekrar deneyin.',
            onRetry: () => retried = true,
          ),
        ),
      ),
    );

    expect(find.text('Tekrar dene'), findsOneWidget);
    await tester.tap(find.text('Tekrar dene'));
    expect(retried, isTrue);
  });

  testWidgets('empty factory renders single compact action', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ClinicalStateMessage.empty(
            icon: Icons.inbox_outlined,
            title: 'Kayıt yok',
            action: OutlinedButton(
              onPressed: () {},
              child: const Text('Yeni kayıt'),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Yeni kayıt'), findsOneWidget);
    expect(find.byType(OutlinedButton), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
  });

  test('safeErrorDescription maps technical text to generic failure', () {
    expect(
      ClinicalStateMessage.safeErrorDescription('PostgREST Exception: jwt'),
      ClinicalStateMessage.genericLoadFailure,
    );
    expect(
      ClinicalStateMessage.safeErrorDescription('tenant_id missing'),
      ClinicalStateMessage.genericLoadFailure,
    );
    expect(
      ClinicalStateMessage.safeErrorDescription('Bağlantı kurulamadı.'),
      'Bağlantı kurulamadı.',
    );
    expect(
      ClinicalStateMessage.safeErrorDescription(null),
      ClinicalStateMessage.genericLoadFailure,
    );
  });

  testWidgets('sanitizes forbidden terms in description', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ClinicalStateMessage.error(
            icon: Icons.error_outline,
            title: 'Hata',
            description: 'JWT tenant_id storage_path',
          ),
        ),
      ),
    );

    expect(find.textContaining('JWT'), findsNothing);
    expect(find.textContaining('tenant_id'), findsNothing);
    final texts = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data ?? '')
        .join(' ');
    expect(
      texts,
      isNot(matches(RegExp(_forbiddenPattern, caseSensitive: false))),
    );
  });
}
