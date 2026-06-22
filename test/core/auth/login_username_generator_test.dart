import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/core/auth/login_username_generator.dart';

void main() {
  test('suggestFromDisplayName transliterates Turkish and combines initials', () {
    expect(
      LoginUsernameGenerator.suggestFromDisplayName('Mehmet Öztürk'),
      'mozturk',
    );
    expect(
      LoginUsernameGenerator.suggestFromDisplayName('Ayşe'),
      'ayse',
    );
  });

  test('normalize strips invalid characters', () {
    expect(LoginUsernameGenerator.normalize('  Dr.Ali-123  '), 'dr.ali123');
    expect(LoginUsernameGenerator.normalize('Çağrı'), 'cagri');
  });

  test('isValid enforces length and charset', () {
    expect(LoginUsernameGenerator.isValid('ab'), isFalse);
    expect(LoginUsernameGenerator.isValid('abc'), isTrue);
    expect(LoginUsernameGenerator.isValid('a' * 33), isFalse);
    expect(LoginUsernameGenerator.isValid('user.name_1'), isTrue);
  });
}
