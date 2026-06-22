import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/shared/widgets/clinical_notice.dart';
import 'package:v2mem_clinic/shared/widgets/clinical_notice_tone.dart';

const _forbiddenPattern =
    r'(Supabase|RLS|JWT|tenant_id|profile_id|storage_path|signed_url|public_url|internalDoctorNote|internal_doctor_note|clinical_data|raw clinical_data)';

void main() {
  testWidgets('renders all tones', (tester) async {
    for (final tone in ClinicalNoticeTone.values) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClinicalNotice(
              tone: tone,
              title: 'Başlık',
              message: 'Mesaj metni',
            ),
          ),
        ),
      );
      expect(find.byKey(const Key('clinical_notice_root')), findsOneWidget);
      expect(find.text('Mesaj metni'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets('title optional and actions max two', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ClinicalNotice(
            tone: ClinicalNoticeTone.info,
            message: 'Sadece mesaj',
            actions: [
              ClinicalNoticeAction(
                label: 'İlk',
                onPressed: () => tapped = true,
              ),
              const ClinicalNoticeAction(
                label: 'İkinci',
                onPressed: _noop,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Sadece mesaj'), findsOneWidget);
    expect(find.text('İlk'), findsOneWidget);
    expect(find.text('İkinci'), findsOneWidget);

    await tester.tap(find.text('İlk'));
    expect(tapped, isTrue);
  });

  testWidgets('uses panel surface without Card elevation', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ClinicalNotice(
            tone: ClinicalNoticeTone.warning,
            message: 'Uyarı',
          ),
        ),
      ),
    );

    expect(find.byType(Card), findsNothing);
    expect(find.byKey(const Key('clinical_notice_root')), findsOneWidget);
  });

  testWidgets('sanitizes forbidden technical terms from rendered text', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ClinicalNotice(
            tone: ClinicalNoticeTone.danger,
            message: 'Hata: Supabase tenant_id storage_path signed_url',
          ),
        ),
      ),
    );

    final text = tester.widget<Text>(find.byType(Text).last).data ?? '';
    expect(text, isNot(matches(RegExp(_forbiddenPattern, caseSensitive: false))));
    expect(find.textContaining('Supabase'), findsNothing);
  });

  testWidgets('sanitizes internal_doctor_note and clinical_data tokens', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ClinicalNotice(
            tone: ClinicalNoticeTone.danger,
            message: 'internal_doctor_note clinical_data storage_path',
          ),
        ),
      ),
    );

    final text = tester.widgetList<Text>(find.byType(Text)).map((t) => t.data ?? '').join(' ');
    expect(
      text,
      isNot(matches(RegExp(_forbiddenPattern, caseSensitive: false))),
    );
  });
}

void _noop() {}
