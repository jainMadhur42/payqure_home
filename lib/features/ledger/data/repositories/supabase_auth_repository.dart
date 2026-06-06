import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/auth/auth_identifier.dart';
import '../../../../core/utils/id_generator.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository({required SupabaseClient? client}) : _client = client {
    _authSubscription = client?.auth.onAuthStateChange.listen(
      _handleAuthStateChange,
    );
  }

  final SupabaseClient? _client;
  final StreamController<UserProfile?> _profileController =
      StreamController.broadcast();
  StreamSubscription<AuthState>? _authSubscription;
  UserProfile? _currentProfile;
  final Map<String, _PendingRegistrationProfile> _pendingRegistrationProfiles =
      {};

  @override
  UserProfile? get currentProfile => _currentProfile;

  @override
  Stream<UserProfile?> watchProfile() => _profileController.stream;

  @override
  Future<UserProfile?> restoreSession() async {
    return refreshProfile();
  }

  @override
  Future<UserProfile?> refreshProfile() async {
    final client = _client;
    if (client == null) {
      return _currentProfile;
    }

    if (client.auth.currentSession == null) {
      _setProfile(null);
      return null;
    }

    User? user;
    try {
      user = (await client.auth.getUser().timeout(
        const Duration(seconds: 8),
      )).user;
    } catch (_) {
      user = client.auth.currentUser;
    }

    if (user == null) {
      _setProfile(null);
      return null;
    }
    final profile = await _profileFromUser(user);
    _setProfile(profile);
    return profile;
  }

  @override
  Future<void> signIn({
    required String identifier,
    required String password,
  }) async {
    final parsed = AuthIdentifier.parse(identifier);
    final client = _client;
    if (client == null) {
      _setProfile(
        UserProfile(
          id: 'local-user',
          name: 'Local User',
          email: parsed.type == AuthIdentifierType.email
              ? parsed.value
              : 'local@payqure.local',
          phone: parsed.type == AuthIdentifierType.phone ? parsed.value : '',
          emailVerified: true,
        ),
      );
      return;
    }

    final emailForPasswordLogin = parsed.type == AuthIdentifierType.phone
        ? await _emailForPhone(parsed.value)
        : parsed.value;
    final response = await client.auth.signInWithPassword(
      email: emailForPasswordLogin,
      password: password,
    );
    final user = response.user;
    if (user == null) {
      throw AuthException('Unable to sign in.');
    }
    _setProfile(await _profileFromUser(user));
  }

  @override
  Future<void> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final normalizedPhone = PhoneNormalizer.toE164(phone);
    final normalizedEmail = email.trim().toLowerCase();
    final client = _client;
    if (client == null) {
      _setProfile(
        UserProfile(
          id: IdGenerator.create('profile'),
          name: name,
          email: email,
          phone: normalizedPhone,
          emailVerified: false,
        ),
      );
      return;
    }

    final response = await client.auth.signUp(
      email: normalizedEmail,
      password: password,
      data: {'name': name, 'phone': normalizedPhone},
    );
    final user = response.user;
    if (user == null) {
      throw AuthException('Unable to register.');
    }
    _pendingRegistrationProfiles[normalizedEmail] = _PendingRegistrationProfile(
      name: name,
      phone: normalizedPhone,
    );
    try {
      await client.auth.updateUser(
        UserAttributes(data: {'name': name, 'phone': normalizedPhone}),
      );
    } catch (_) {
      // Email-confirmation signups may not have an active session yet.
    }
    await _upsertProfile(
      user: user,
      name: name,
      email: normalizedEmail,
      phone: normalizedPhone,
    );
    _setProfile(
      await _profileFromUser(user, name: name, phone: normalizedPhone),
    );
  }

  @override
  Future<void> resendEmailVerification(String email) async {
    final client = _client;
    if (client == null) {
      return;
    }
    await client.auth.resend(type: OtpType.signup, email: email);
  }

  @override
  Future<UserProfile> verifyEmailOtp({
    required String email,
    required String token,
  }) async {
    final client = _client;
    if (client == null) {
      final current = _currentProfile;
      if (current == null) {
        throw StateError('Register before verifying your email.');
      }
      final verified = current.copyWith(emailVerified: true);
      _setProfile(verified);
      return verified;
    }

    final response = await client.auth.verifyOTP(
      email: email.trim(),
      token: token.trim(),
      type: OtpType.signup,
    );
    final user = response.user ?? client.auth.currentUser;
    if (user == null) {
      throw AuthException('Unable to verify email OTP.');
    }
    final pending = _pendingRegistrationProfiles[email.trim().toLowerCase()];
    final profile = await _profileFromUser(
      user,
      name: pending?.name,
      phone: pending?.phone,
    );
    _pendingRegistrationProfiles.remove(email.trim().toLowerCase());
    _setProfile(profile);
    return profile;
  }

  @override
  Future<UserProfile> updateProfile({
    required String name,
    required String phone,
  }) async {
    final current = _currentProfile;
    if (current == null) {
      throw StateError('Sign in before editing your profile.');
    }
    final normalizedPhone = PhoneNormalizer.toE164(phone);
    final client = _client;
    if (client == null) {
      final updated = current.copyWith(name: name, phone: normalizedPhone);
      _setProfile(updated);
      return updated;
    }

    final user = client.auth.currentUser;
    if (user == null) {
      throw AuthException('Sign in before editing your profile.');
    }
    await client.auth.updateUser(
      UserAttributes(data: {'name': name, 'phone': normalizedPhone}),
    );
    await _upsertProfile(
      user: user,
      name: name,
      email: current.email,
      phone: normalizedPhone,
    );
    final updated = current.copyWith(name: name, phone: normalizedPhone);
    _setProfile(updated);
    return updated;
  }

  @override
  Future<void> requestPasswordReset(String email) async {
    final client = _client;
    if (client == null) {
      return;
    }
    await client.auth.resetPasswordForEmail(email);
  }

  @override
  Future<void> resetPasswordWithOtp({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    final client = _client;
    if (client == null) {
      return;
    }
    await client.auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.recovery,
    );
    await client.auth.updateUser(UserAttributes(password: newPassword));
  }

  @override
  Future<void> signOut() async {
    await _client?.auth.signOut();
    _setProfile(null);
  }

  void _handleAuthStateChange(AuthState state) {
    if (state.event == AuthChangeEvent.signedOut) {
      _setProfile(null);
      return;
    }
    final user = state.session?.user;
    if (user != null) {
      unawaited(_syncProfileFromAuthEvent(user));
    }
  }

  Future<void> _syncProfileFromAuthEvent(User user) async {
    try {
      _setProfile(await _profileFromUser(user));
    } catch (_) {
      // The explicit auth actions surface errors; passive auth events should not.
    }
  }

  Future<UserProfile> _profileFromUser(
    User user, {
    String? name,
    String? phone,
  }) async {
    final profileRow = await _profileRow(user.id);
    final metadata = user.userMetadata ?? {};
    final resolvedName =
        name ?? profileRow?['name']?.toString() ?? metadata['name']?.toString();
    final resolvedEmail =
        profileRow?['email']?.toString() ??
        user.email ??
        metadata['email']?.toString() ??
        '';
    final resolvedPhone =
        phone ??
        profileRow?['phone']?.toString() ??
        user.phone ??
        metadata['phone']?.toString() ??
        '';
    final emailVerified = user.emailConfirmedAt != null;

    await _upsertProfile(
      user: user,
      name: resolvedName ?? 'Payqure User',
      email: resolvedEmail,
      phone: resolvedPhone,
    );

    return UserProfile(
      id: user.id,
      name: resolvedName ?? 'Payqure User',
      email: resolvedEmail,
      phone: resolvedPhone,
      emailVerified: emailVerified,
    );
  }

  Future<Map<String, dynamic>?> _profileRow(String userId) async {
    final client = _client;
    if (client == null) {
      return null;
    }
    try {
      final row = await client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      return row;
    } catch (_) {
      return null;
    }
  }

  Future<String> _emailForPhone(String phone) async {
    final client = _client;
    if (client == null) {
      return phone;
    }
    try {
      final email = await client.rpc<String>(
        'email_for_phone_login',
        params: {'login_phone': phone},
      );
      if (email.isNotEmpty) {
        return email;
      }
    } catch (_) {
      // Fall through to a clearer auth error from signInWithPassword.
    }
    return phone;
  }

  Future<void> _upsertProfile({
    required User user,
    required String name,
    required String email,
    required String phone,
  }) async {
    final client = _client;
    if (client == null) {
      return;
    }
    try {
      await client.from('profiles').upsert({
        'id': user.id,
        'name': name,
        'email': email,
        'phone': phone,
        'email_verified': user.emailConfirmedAt != null,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (_) {
      // Auth should remain usable while the Supabase schema is being applied.
    }
  }

  void _setProfile(UserProfile? profile) {
    _currentProfile = profile;
    _profileController.add(profile);
  }

  Future<void> dispose() async {
    await _authSubscription?.cancel();
    await _profileController.close();
  }
}

class _PendingRegistrationProfile {
  const _PendingRegistrationProfile({required this.name, required this.phone});

  final String name;
  final String phone;
}
