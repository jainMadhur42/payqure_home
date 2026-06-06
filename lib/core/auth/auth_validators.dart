abstract final class AuthValidators {
  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? requiredText(String? value, String label) {
    return (value ?? '').trim().isEmpty ? '$label is required' : null;
  }

  static String? email(String? value) {
    final trimmed = (value ?? '').trim();
    if (trimmed.isEmpty) {
      return 'Email is required';
    }
    return _emailPattern.hasMatch(trimmed) ? null : 'Enter a valid email';
  }

  static String? emailOrPhone(String? value) {
    final trimmed = (value ?? '').trim();
    if (trimmed.isEmpty) {
      return 'Email or phone is required';
    }
    if (trimmed.contains('@')) {
      return email(trimmed);
    }
    final digits = trimmed.replaceAll(RegExp('[^0-9]'), '');
    return digits.length >= 10 ? null : 'Enter a valid phone number';
  }

  static String? phone(String? value) {
    final digits = (value ?? '').replaceAll(RegExp('[^0-9]'), '');
    if (digits.isEmpty) {
      return 'Phone is required';
    }
    return digits.length >= 10 ? null : 'Enter a valid phone number';
  }

  static String? password(String? value) {
    final text = value ?? '';
    if (text.isEmpty) {
      return 'Password is required';
    }
    if (text.length < 8) {
      return 'Use at least 8 characters';
    }
    return null;
  }

  static String? otp(String? value) {
    final digits = (value ?? '').replaceAll(RegExp('[^0-9]'), '');
    if (digits.isEmpty) {
      return 'OTP is required';
    }
    return digits.length >= 6 ? null : 'Enter the 6 digit OTP';
  }
}
