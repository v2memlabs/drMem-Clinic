import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/shared/widgets/clinical_snack_bar.dart';
import 'package:v2mem_clinic/shared/widgets/clinical_ui_text_sanitizer.dart';

void main() {
  test('forbidden technical message returns generic Turkish error', () {
    expect(
      ClinicalSnackBar.safeMessage(
        'PostgREST AuthException tenant_id storage_bucket',
        isError: true,
      ),
      ClinicalSnackBar.genericErrorMessage,
    );
  });

  test('safe Turkish message is preserved', () {
    expect(
      ClinicalSnackBar.safeMessage('Kayıt kaydedilemedi.', isError: true),
      'Kayıt kaydedilemedi.',
    );
  });

  test('empty message uses fallback', () {
    expect(
      ClinicalSnackBar.safeMessage('', isError: true),
      ClinicalSnackBar.genericErrorMessage,
    );
    expect(
      ClinicalSnackBar.safeMessage(null, isError: false),
      ClinicalSnackBar.genericSuccessMessage,
    );
  });

  test('sanitized-empty message uses fallback', () {
    expect(
      ClinicalSnackBar.safeMessage('JWT secret token', isError: false),
      ClinicalSnackBar.genericSuccessMessage,
    );
  });

  test('forbidden tokens align with sanitizer list', () {
    for (final token in ClinicalUiTextSanitizer.forbiddenUiTokens) {
      expect(
        ClinicalUiTextSanitizer.containsForbiddenToken('leak $token here'),
        isTrue,
        reason: token,
      );
    }
  });
}
