import 'package:flutter_test/flutter_test.dart';
import 'package:soundify/core/utils/validators.dart';

void main() {
  group('email validator', () {
    test('accepts valid addresses', () {
      expect(Validators.email('user@example.com'), isNull);
      expect(Validators.email('first.last+tag@sub.domain.co'), isNull);
    });

    test('rejects invalid addresses', () {
      expect(Validators.email(''), isNotNull);
      expect(Validators.email('not-an-email'), isNotNull);
      expect(Validators.email('user@'), isNotNull);
      expect(Validators.email('@example.com'), isNotNull);
    });
  });

  group('password validator', () {
    test('accepts a strong password', () {
      expect(Validators.password('Soundify123'), isNull);
    });

    test('rejects short or weak passwords', () {
      expect(Validators.password(''), isNotNull);
      expect(Validators.password('short1'), isNotNull);
      expect(Validators.password('onlyletters'), isNotNull);
      expect(Validators.password('12345678'), isNotNull);
    });

    test('measures strength', () {
      expect(Validators.passwordStrength(''), 0);
      expect(Validators.passwordStrength('abc12345'), 1);
      expect(Validators.passwordStrength('Abcdef123'), 2);
      expect(Validators.passwordStrength('Abcdef123!@#'), 3);
    });
  });

  group('username validator', () {
    test('accepts normalized usernames', () {
      expect(Validators.username('soundify_user1'), isNull);
    });

    test('rejects too short or invalid characters', () {
      expect(Validators.username('ab'), isNotNull);
      expect(Validators.username('bad name'), isNotNull);
      expect(Validators.username('نام'), isNotNull);
    });
  });

  test('confirms matching passwords', () {
    expect(Validators.confirmPassword('abc12345', 'abc12345'), isNull);
    expect(Validators.confirmPassword('abc12345', 'different'), isNotNull);
  });

  test('validates 6-digit OTP codes', () {
    expect(Validators.otpCode('123456'), isNull);
    expect(Validators.otpCode('12345'), isNotNull);
    expect(Validators.otpCode('abcdef'), isNotNull);
    expect(Validators.otpCode(''), isNotNull);
  });
}
