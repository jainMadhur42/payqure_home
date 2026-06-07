import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/auth/auth_identifier.dart';
import '../../../../core/utils/id_generator.dart';
import '../../../legal/domain/legal_content.dart';
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
          privacyPolicyAccepted: true,
          privacyPolicyAcceptedAt: DateTime.now(),
          privacyPolicyVersion: LegalContent.policyVersion,
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
    required bool privacyPolicyAccepted,
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
          privacyPolicyAccepted: privacyPolicyAccepted,
          privacyPolicyAcceptedAt: privacyPolicyAccepted
              ? DateTime.now()
              : null,
          privacyPolicyVersion: privacyPolicyAccepted
              ? LegalContent.policyVersion
              : '',
        ),
      );
      return;
    }

    await _claimOtpRequest(
      email: normalizedEmail,
      purpose: _OtpRequestPurpose.signup,
    );
    final response = await client.auth.signUp(
      email: normalizedEmail,
      password: password,
      data: {
        'name': name,
        'phone': normalizedPhone,
        'privacy_policy_accepted': privacyPolicyAccepted,
        'privacy_policy_accepted_at': privacyPolicyAccepted
            ? DateTime.now().toUtc().toIso8601String()
            : null,
        'privacy_policy_version': privacyPolicyAccepted
            ? LegalContent.policyVersion
            : null,
      },
    );
    final user = response.user;
    if (user == null) {
      throw AuthException('Unable to register.');
    }
    _pendingRegistrationProfiles[normalizedEmail] = _PendingRegistrationProfile(
      name: name,
      phone: normalizedPhone,
      privacyPolicyAccepted: privacyPolicyAccepted,
    );
    try {
      await client.auth.updateUser(
        UserAttributes(
          data: {
            'name': name,
            'phone': normalizedPhone,
            'privacy_policy_accepted': privacyPolicyAccepted,
            'privacy_policy_accepted_at': privacyPolicyAccepted
                ? DateTime.now().toUtc().toIso8601String()
                : null,
            'privacy_policy_version': privacyPolicyAccepted
                ? LegalContent.policyVersion
                : null,
          },
        ),
      );
    } catch (_) {
      // Email-confirmation signups may not have an active session yet.
    }
    await _upsertProfile(
      user: user,
      name: name,
      email: normalizedEmail,
      phone: normalizedPhone,
      privacyPolicyAccepted: privacyPolicyAccepted,
      privacyPolicyAcceptedAt: privacyPolicyAccepted ? DateTime.now() : null,
      privacyPolicyVersion: privacyPolicyAccepted
          ? LegalContent.policyVersion
          : '',
    );
    _setProfile(
      await _profileFromUser(
        user,
        name: name,
        phone: normalizedPhone,
        privacyPolicyAccepted: privacyPolicyAccepted,
      ),
    );
  }

  @override
  Future<UserProfile> acceptPrivacyPolicy({required String version}) async {
    final current = _currentProfile;
    if (current == null) {
      throw StateError('Sign in before accepting the Privacy Policy.');
    }
    final acceptedAt = DateTime.now().toUtc();
    final client = _client;
    if (client != null) {
      final user = client.auth.currentUser;
      if (user == null) {
        throw AuthException('Sign in before accepting the Privacy Policy.');
      }
      await client.auth.updateUser(
        UserAttributes(
          data: {
            ...?user.userMetadata,
            'privacy_policy_accepted': true,
            'privacy_policy_accepted_at': acceptedAt.toIso8601String(),
            'privacy_policy_version': version,
          },
        ),
      );
      await client
          .from('profiles')
          .update({
            'privacy_policy_accepted': true,
            'privacy_policy_accepted_at': acceptedAt.toIso8601String(),
            'privacy_policy_version': version,
            'updated_at': acceptedAt.toIso8601String(),
          })
          .eq('id', current.id);
    }
    final updated = current.copyWith(
      privacyPolicyAccepted: true,
      privacyPolicyAcceptedAt: acceptedAt,
      privacyPolicyVersion: version,
    );
    _setProfile(updated);
    return updated;
  }

  @override
  Future<void> resendEmailVerification(String email) async {
    final client = _client;
    if (client == null) {
      return;
    }
    final normalizedEmail = email.trim().toLowerCase();
    await _claimOtpRequest(
      email: normalizedEmail,
      purpose: _OtpRequestPurpose.signup,
    );
    await client.auth.resend(type: OtpType.signup, email: normalizedEmail);
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
      privacyPolicyAccepted: pending?.privacyPolicyAccepted,
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
      privacyPolicyAccepted: current.privacyPolicyAccepted,
      privacyPolicyAcceptedAt: current.privacyPolicyAcceptedAt,
      privacyPolicyVersion: current.privacyPolicyVersion,
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
    final normalizedEmail = email.trim().toLowerCase();
    await _claimOtpRequest(
      email: normalizedEmail,
      purpose: _OtpRequestPurpose.passwordReset,
    );
    await client.auth.resetPasswordForEmail(normalizedEmail);
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

  Future<void> _claimOtpRequest({
    required String email,
    required _OtpRequestPurpose purpose,
  }) async {
    final client = _client;
    if (client == null) {
      return;
    }
    final response = await client.rpc<Object>(
      'claim_auth_otp_request',
      params: {
        'request_identifier': email,
        'request_purpose': purpose.databaseValue,
      },
    );
    final row = switch (response) {
      final List<dynamic> rows when rows.isNotEmpty =>
        Map<String, dynamic>.from(rows.first as Map),
      final Map<dynamic, dynamic> value => Map<String, dynamic>.from(value),
      _ => const <String, dynamic>{},
    };
    if (row['allowed'] == true) {
      return;
    }
    throw AuthException(
      'OTP requests are blocked after 3 attempts. Contact ${LegalContent.supportEmail} for review.',
    );
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
    bool? privacyPolicyAccepted,
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
    final accepted =
        privacyPolicyAccepted ??
        _boolValue(profileRow?['privacy_policy_accepted']) ??
        _boolValue(metadata['privacy_policy_accepted']) ??
        false;
    final acceptedAt = _dateValue(
      profileRow?['privacy_policy_accepted_at'] ??
          metadata['privacy_policy_accepted_at'],
    );
    final policyVersion =
        profileRow?['privacy_policy_version']?.toString() ??
        metadata['privacy_policy_version']?.toString() ??
        '';

    unawaited(
      _upsertProfile(
        user: user,
        name: resolvedName ?? 'Payqure User',
        email: resolvedEmail,
        phone: resolvedPhone,
        privacyPolicyAccepted: accepted,
        privacyPolicyAcceptedAt: acceptedAt,
        privacyPolicyVersion: policyVersion,
      ),
    );

    return UserProfile(
      id: user.id,
      name: resolvedName ?? 'Payqure User',
      email: resolvedEmail,
      phone: resolvedPhone,
      emailVerified: emailVerified,
      privacyPolicyAccepted: accepted,
      privacyPolicyAcceptedAt: acceptedAt,
      privacyPolicyVersion: policyVersion,
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
          .maybeSingle()
          .timeout(const Duration(seconds: 6));
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
    bool privacyPolicyAccepted = false,
    DateTime? privacyPolicyAcceptedAt,
    String privacyPolicyVersion = '',
  }) async {
    final client = _client;
    if (client == null) {
      return;
    }
    try {
      await client
          .from('profiles')
          .upsert({
            'id': user.id,
            'name': name,
            'email': email,
            'phone': phone,
            'email_verified': user.emailConfirmedAt != null,
            'privacy_policy_accepted': privacyPolicyAccepted,
            'privacy_policy_accepted_at': privacyPolicyAcceptedAt
                ?.toUtc()
                .toIso8601String(),
            'privacy_policy_version': privacyPolicyVersion.isEmpty
                ? null
                : privacyPolicyVersion,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .timeout(const Duration(seconds: 6));
    } catch (_) {
      // Auth should remain usable while the Supabase schema is being applied.
    }
  }

  bool? _boolValue(dynamic value) {
    return switch (value) {
      bool boolean => boolean,
      String text when text.toLowerCase() == 'true' => true,
      String text when text.toLowerCase() == 'false' => false,
      _ => null,
    };
  }

  DateTime? _dateValue(dynamic value) {
    if (value == null) {
      return null;
    }
    return DateTime.tryParse(value.toString());
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

enum _OtpRequestPurpose {
  signup('signup'),
  passwordReset('password_reset');

  const _OtpRequestPurpose(this.databaseValue);

  final String databaseValue;
}

class _PendingRegistrationProfile {
  const _PendingRegistrationProfile({
    required this.name,
    required this.phone,
    required this.privacyPolicyAccepted,
  });

  final String name;
  final String phone;
  final bool privacyPolicyAccepted;
}
