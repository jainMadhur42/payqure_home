import 'package:supabase_flutter/supabase_flutter.dart';

abstract final class ErrorMessageMapper {
  static String userFacing(Object error) {
    if (error is AuthException) {
      return _authMessage(error.message);
    }
    final text = error.toString().replaceFirst('Exception: ', '');
    return text.startsWith('Bad state: ') ? text.substring(11) : text;
  }

  static String _authMessage(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('invalid login') ||
        lower.contains('invalid credentials')) {
      return 'Email or phone and password do not match.';
    }
    if (lower.contains('email not confirmed')) {
      return 'Please verify your email before logging in.';
    }
    if (lower.contains('already registered')) {
      return 'An account already exists for this email.';
    }
    if (lower.contains('rate limit')) {
      return 'Please wait a moment before trying again.';
    }
    return message;
  }
}
