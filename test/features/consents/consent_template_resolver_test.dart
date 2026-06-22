import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/consents/data/consent_template_resolver.dart';
import 'package:v2mem_clinic/features/consents/models/consent_record.dart';
import 'package:v2mem_clinic/features/consents/models/consent_template.dart';

void main() {
  test('kvkk type resolves active kvkk template', () {
    final template = ConsentTemplateResolver.resolveActiveTemplate(
      ConsentType.kvkkAydinlatma,
    );

    expect(template, isNotNull);
    expect(template!.category, ConsentTemplateCategories.kvkkAydinlatma);
    expect(template.isActive, isTrue);
  });

  test('sms and whatsapp share communication template category', () {
    final smsCategory = ConsentTemplateResolver.categoryForConsentType(
      ConsentType.smsIzin,
    );
    final whatsappCategory = ConsentTemplateResolver.categoryForConsentType(
      ConsentType.whatsappIzin,
    );

    expect(smsCategory, ConsentTemplateCategories.whatsappSms);
    expect(whatsappCategory, ConsentTemplateCategories.whatsappSms);
  });
}
