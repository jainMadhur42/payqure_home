import 'package:flutter_test/flutter_test.dart';
import 'package:payqure_home/core/auth/auth_validators.dart';

void main() {
  group('AuthValidators', () {
    test('accepts email or phone identifiers', () {
      expect(AuthValidators.emailOrPhone('user@example.com'), isNull);
      expect(AuthValidators.emailOrPhone('+91 98765 43210'), isNull);
    });

    test('rejects invalid identifiers', () {
      expect(AuthValidators.emailOrPhone(''), isNotNull);
      expect(AuthValidators.emailOrPhone('not-an-email'), isNotNull);
      expect(AuthValidators.emailOrPhone('12345'), isNotNull);
    });

    test('requires strong enough password length', () {
      expect(AuthValidators.password('password123'), isNull);
      expect(AuthValidators.password('short'), isNotNull);
    });

    test('requires six digit OTP', () {
      expect(AuthValidators.otp('123456'), isNull);
      expect(AuthValidators.otp('123'), isNotNull);
    });
  });
}
