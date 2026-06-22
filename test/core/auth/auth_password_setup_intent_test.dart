import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/core/auth/auth_password_setup_intent.dart';

void main() {
  tearDown(AuthPasswordSetupIntent.clear);

  test('markRequired and clear toggle password setup intent', () {
    expect(AuthPasswordSetupIntent.isRequired, isFalse);
    AuthPasswordSetupIntent.markRequired();
    expect(AuthPasswordSetupIntent.isRequired, isTrue);
    AuthPasswordSetupIntent.clear();
    expect(AuthPasswordSetupIntent.isRequired, isFalse);
  });
}
