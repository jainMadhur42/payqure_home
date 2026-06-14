import 'package:flutter_test/flutter_test.dart';
import 'package:payqure_home/core/utils/error_message_mapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('ErrorMessageMapper identity conflicts', () {
    test('preserves duplicate signup email guidance', () {
      expect(
        ErrorMessageMapper.userFacing(
          const AuthException('Email ID is already registered.'),
        ),
        'Email ID is already registered. Please use another email.',
      );
    });

    test('preserves duplicate signup phone guidance', () {
      expect(
        ErrorMessageMapper.userFacing(
          const AuthException('Phone number is already registered.'),
        ),
        'Phone number is already registered. Please use another number.',
      );
    });

    test('preserves profile phone ownership guidance', () {
      expect(
        ErrorMessageMapper.userFacing(
          const AuthException(
            'Phone number is already registered with another email ID.',
          ),
        ),
        'Phone number is already registered with another email ID. '
        'Please use another number.',
      );
    });

    test('hides a missing RPC implementation detail', () {
      expect(
        ErrorMessageMapper.userFacing(
          const PostgrestException(
            message: 'Could not find the function',
            code: 'PGRST202',
          ),
        ),
        'We could not verify this email or phone. Check the details or '
        'use another number and try again.',
      );
    });

    test('turns a phone uniqueness violation into corrective guidance', () {
      expect(
        ErrorMessageMapper.userFacing(
          const PostgrestException(
            message:
                'duplicate key value violates unique constraint profiles_phone_key',
            code: '23505',
          ),
        ),
        'Phone number is already registered. Please use another number.',
      );
    });

    test('hides database signup failures behind corrective guidance', () {
      expect(
        ErrorMessageMapper.userFacing(
          const AuthException('Database error saving new user'),
        ),
        'We could not create your account. The email or phone may already '
        'be registered. Please check them and try again.',
      );
    });
  });
}
