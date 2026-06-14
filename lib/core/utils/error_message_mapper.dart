import 'package:supabase_flutter/supabase_flutter.dart';

abstract final class ErrorMessageMapper {
  static String userFacing(Object error) {
    if (error is AuthException) {
      return _authMessage(error.message);
    }
    if (error is PostgrestException) {
      if (error.code == 'PGRST202') {
        return 'We could not verify this email or phone. Check the details or '
            'use another number and try again.';
      }
      if (error.code == '23505' ||
          error.message.toLowerCase().contains('profiles_phone_key')) {
        return 'Phone number is already registered. Please use another number.';
      }
      return 'We could not save your account details. Please try again.';
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
    if (lower.contains('phone number') && lower.contains('another email id')) {
      return 'Phone number is already registered with another email ID. '
          'Please use another number.';
    }
    if (lower.contains('phone number') &&
        lower.contains('already registered')) {
      return 'Phone number is already registered. Please use another number.';
    }
    if (lower.contains('email id') && lower.contains('already registered')) {
      return 'Email ID is already registered. Please use another email.';
    }
    if (lower.contains('already registered')) {
      return 'Email ID is already registered. Please use another email.';
    }
    if (lower.contains('database error saving new user')) {
      return 'We could not create your account. The email or phone may already '
          'be registered. Please check them and try again.';
    }
    if (lower.contains('could not find the function') ||
        lower.contains('pgrst202')) {
      return 'We could not verify this email or phone. Check the details or '
          'use another number and try again.';
    }
    if (lower.contains('rate limit')) {
      return 'Please wait a moment before trying again.';
    }
    return message;
  }
}
