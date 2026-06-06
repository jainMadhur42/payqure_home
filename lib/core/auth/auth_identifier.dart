enum AuthIdentifierType { email, phone }

class AuthIdentifier {
  const AuthIdentifier._(this.value, this.type);

  final String value;
  final AuthIdentifierType type;

  static AuthIdentifier parse(String input) {
    final trimmed = input.trim();
    if (trimmed.contains('@')) {
      return AuthIdentifier._(trimmed.toLowerCase(), AuthIdentifierType.email);
    }
    return AuthIdentifier._(
      PhoneNormalizer.toE164(trimmed),
      AuthIdentifierType.phone,
    );
  }
}

abstract final class PhoneNormalizer {
  static String toE164(String input, {String defaultCountryCode = '+91'}) {
    final compact = input.replaceAll(RegExp(r'[\s\-()]+'), '');
    if (compact.startsWith('+')) {
      return compact;
    }
    final digits = compact.replaceAll(RegExp('[^0-9]'), '');
    if (digits.startsWith('91') && digits.length == 12) {
      return '+$digits';
    }
    return '$defaultCountryCode$digits';
  }
}
