import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/auth/auth_identifier.dart';
import '../../../../core/utils/id_generator.dart';
import '../../../legal/domain/legal_content.dart';
import '../../domain/entities/otp_request_status.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/auth_repository.dart';

class SupabaseAuthRepository
    implements
        AuthRepository,
        OtpRequestStatusProvider,
        PreferredCurrencyRepository {
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
  final Map<OtpRequestPurpose, OtpRequestStatus> _otpRequestStatuses = {};

  @override
  UserProfile? get currentProfile => _currentProfile;

  @override
  OtpRequestStatus? statusFor(OtpRequestPurpose purpose) {
    return _otpRequestStatuses[purpose];
  }

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
          preferredCurrencyCode: 'USD',
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
          preferredCurrencyCode: 'USD',
        ),
      );
      return;
    }

    await _ensureRegistrationIdentityAvailable(
      email: normalizedEmail,
      phone: normalizedPhone,
    );
    await _claimOtpRequest(
      email: normalizedEmail,
      purpose: _OtpRequestPurpose.signup,
    );
    late final AuthResponse response;
    try {
      response = await client.auth.signUp(
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
    } catch (error) {
      await _throwRegistrationConflictIfPresent(
        email: normalizedEmail,
        phone: normalizedPhone,
      );
      rethrow;
    }
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
            'preferred_currency': 'USD',
          },
        ),
      );
    } catch (_) {
      // Email-confirmation signups may not have an active session yet.
    }
    // With email confirmation enabled, signUp may not return a session. The
    // database auth-user trigger persists metadata in that case. When a
    // session is available, verify the profile write synchronously.
    if (response.session != null || client.auth.currentSession != null) {
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
        preferredCurrencyCode: 'USD',
      );
    }
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
    await _upsertProfile(
      user: user,
      name: profile.name,
      email: profile.email,
      phone: profile.phone,
      privacyPolicyAccepted: profile.privacyPolicyAccepted,
      privacyPolicyAcceptedAt: profile.privacyPolicyAcceptedAt,
      privacyPolicyVersion: profile.privacyPolicyVersion,
      preferredCurrencyCode: profile.preferredCurrencyCode,
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
    await _ensureProfilePhoneAvailable(
      email: current.email,
      phone: normalizedPhone,
    );
    try {
      await _upsertProfile(
        user: user,
        name: name,
        email: current.email,
        phone: normalizedPhone,
        privacyPolicyAccepted: current.privacyPolicyAccepted,
        privacyPolicyAcceptedAt: current.privacyPolicyAcceptedAt,
        privacyPolicyVersion: current.privacyPolicyVersion,
        preferredCurrencyCode: current.preferredCurrencyCode,
      );
    } catch (error) {
      await _throwProfilePhoneConflictIfPresent(
        email: current.email,
        phone: normalizedPhone,
      );
      rethrow;
    }
    await client.auth.updateUser(
      UserAttributes(data: {'name': name, 'phone': normalizedPhone}),
    );
    final updated = current.copyWith(name: name, phone: normalizedPhone);
    _setProfile(updated);
    return updated;
  }

  @override
  Future<UserProfile> updatePreferredCurrency(String currencyCode) async {
    final current = _currentProfile;
    if (current == null) {
      throw StateError('Sign in before changing currency.');
    }
    final normalizedCode = currencyCode.trim().toUpperCase();
    final client = _client;
    if (client != null) {
      await client
          .from('profiles')
          .update({
            'preferred_currency': normalizedCode,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', current.id)
          .timeout(const Duration(seconds: 6));
      try {
        await client.auth.updateUser(
          UserAttributes(data: {'preferred_currency': normalizedCode}),
        );
      } catch (_) {
        // The profile table is authoritative; metadata is only a fallback.
      }
    }
    final updated = current.copyWith(preferredCurrencyCode: normalizedCode);
    _setProfile(updated);
    return updated;
  }

  @override
  Future<String> requestPasswordReset(String identifier) async {
    final parsed = AuthIdentifier.parse(identifier);
    final client = _client;
    if (client == null) {
      return parsed.type == AuthIdentifierType.email
          ? parsed.value
          : 'local@payqure.local';
    }
    // Recovery is email-based; resolve a phone identifier to its account email
    // so the OTP is sent to (and later verified against) that address.
    final normalizedEmail = parsed.type == AuthIdentifierType.phone
        ? (await _emailForPhone(parsed.value)).trim().toLowerCase()
        : parsed.value;
    await _claimOtpRequest(
      email: normalizedEmail,
      purpose: _OtpRequestPurpose.passwordReset,
    );
    await client.auth.resetPasswordForEmail(normalizedEmail);
    return normalizedEmail;
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

  Future<OtpRequestStatus> _claimOtpRequest({
    required String email,
    required _OtpRequestPurpose purpose,
  }) async {
    final client = _client;
    if (client == null) {
      final now = DateTime.now().toUtc();
      final previous = _otpRequestStatuses[purpose.domainValue];
      final activePrevious =
          previous != null && previous.remaining(now) > Duration.zero
          ? previous
          : null;
      final usedCount = ((activePrevious?.usedCount ?? 0) + 1).clamp(
        0,
        OtpRequestStatus.maximumRequests,
      );
      final status = OtpRequestStatus(
        usedCount: usedCount,
        windowResetsAt:
            activePrevious?.windowResetsAt ?? now.add(const Duration(hours: 1)),
        blocked: usedCount >= OtpRequestStatus.maximumRequests,
      );
      _otpRequestStatuses[purpose.domainValue] = status;
      return status;
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
    final status = OtpRequestStatus(
      usedCount: _asInt(row['request_count']),
      windowResetsAt: _asDateTime(row['window_resets_at']),
      blocked: row['blocked'] == true,
    );
    _otpRequestStatuses[purpose.domainValue] = status;
    if (row['allowed'] == true) {
      return status;
    }
    throw AuthException(
      'You have reached the maximum OTP request limit. '
      'Please try again after 60 minutes.',
    );
  }

  int _asInt(Object? value) {
    return switch (value) {
      final int number => number,
      final num number => number.toInt(),
      final String text => int.tryParse(text) ?? 0,
      _ => 0,
    };
  }

  DateTime? _asDateTime(Object? value) {
    if (value is DateTime) {
      return value.toUtc();
    }
    if (value is String) {
      return DateTime.tryParse(value)?.toUtc();
    }
    return null;
  }

  Future<void> _ensureRegistrationIdentityAvailable({
    required String email,
    required String phone,
  }) async {
    final conflicts = await _identityConflicts(email: email, phone: phone);
    if (conflicts.emailRegistered) {
      throw AuthException('Email ID is already registered.');
    }
    if (conflicts.phoneRegistered) {
      throw AuthException('Phone number is already registered.');
    }
  }

  Future<void> _throwRegistrationConflictIfPresent({
    required String email,
    required String phone,
  }) async {
    try {
      await _ensureRegistrationIdentityAvailable(email: email, phone: phone);
    } on AuthException {
      rethrow;
    } catch (_) {
      // Preserve the original signup error if the diagnostic RPC also fails.
    }
  }

  Future<void> _ensureProfilePhoneAvailable({
    required String email,
    required String phone,
  }) async {
    final conflicts = await _identityConflicts(email: email, phone: phone);
    if (conflicts.phoneRegistered) {
      throw AuthException(
        'Phone number is already registered with another email ID.',
      );
    }
  }

  Future<void> _throwProfilePhoneConflictIfPresent({
    required String email,
    required String phone,
  }) async {
    try {
      await _ensureProfilePhoneAvailable(email: email, phone: phone);
    } on AuthException {
      rethrow;
    } catch (_) {
      // Preserve the original profile write error if the recheck also fails.
    }
  }

  Future<_AuthIdentityConflicts> _identityConflicts({
    required String email,
    required String phone,
  }) async {
    final client = _client;
    if (client == null) {
      return const _AuthIdentityConflicts();
    }
    Object response;
    try {
      response = await client.rpc<Object>(
        'auth_identity_conflicts',
        params: {'request_email': email, 'request_phone': phone},
      );
    } on PostgrestException catch (error) {
      if (error.code != 'PGRST202') {
        throw AuthException(
          'We could not verify your account details. Please try again.',
        );
      }
      final registeredEmail = await _registeredEmailForPhone(phone);
      return _AuthIdentityConflicts(phoneRegistered: registeredEmail != null);
    }
    final row = switch (response) {
      final List<dynamic> rows when rows.isNotEmpty =>
        Map<String, dynamic>.from(rows.first as Map),
      final Map<dynamic, dynamic> value => Map<String, dynamic>.from(value),
      _ => const <String, dynamic>{},
    };
    return _AuthIdentityConflicts(
      emailRegistered: row['email_registered'] == true,
      phoneRegistered: row['phone_registered'] == true,
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
        _nonEmptyText(name) ??
        _nonEmptyText(profileRow?['name']) ??
        _nonEmptyText(metadata['name']);
    final resolvedEmail =
        _nonEmptyText(profileRow?['email']) ??
        _nonEmptyText(user.email) ??
        _nonEmptyText(metadata['email']) ??
        '';
    final resolvedPhone =
        _nonEmptyText(phone) ??
        _nonEmptyText(profileRow?['phone']) ??
        _nonEmptyText(user.phone) ??
        _nonEmptyText(metadata['phone']) ??
        _nonEmptyText(metadata['phone_number']) ??
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
    final preferredCurrencyCode =
        profileRow?['preferred_currency']?.toString() ??
        metadata['preferred_currency']?.toString() ??
        'USD';

    unawaited(
      _upsertProfile(
        user: user,
        name: resolvedName ?? 'Payqure User',
        email: resolvedEmail,
        phone: resolvedPhone,
        privacyPolicyAccepted: accepted,
        privacyPolicyAcceptedAt: acceptedAt,
        privacyPolicyVersion: policyVersion,
        preferredCurrencyCode: preferredCurrencyCode,
        suppressErrors: true,
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
      preferredCurrencyCode: preferredCurrencyCode,
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
    return await _registeredEmailForPhone(phone) ?? phone;
  }

  Future<String?> _registeredEmailForPhone(String phone) async {
    final client = _client;
    if (client == null) {
      return null;
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
      // Treat an unavailable compatibility lookup as no known phone match.
    }
    return null;
  }

  Future<void> _upsertProfile({
    required User user,
    required String name,
    required String email,
    required String phone,
    bool privacyPolicyAccepted = false,
    DateTime? privacyPolicyAcceptedAt,
    String privacyPolicyVersion = '',
    String preferredCurrencyCode = 'USD',
    bool suppressErrors = false,
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
            'preferred_currency': preferredCurrencyCode,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .timeout(const Duration(seconds: 6));
    } catch (_) {
      if (!suppressErrors) {
        rethrow;
      }
      // Passive session restoration must remain usable during transient
      // network failures. Explicit registration/profile updates are strict.
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

  String? _nonEmptyText(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
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

  OtpRequestPurpose get domainValue => switch (this) {
    _OtpRequestPurpose.signup => OtpRequestPurpose.signup,
    _OtpRequestPurpose.passwordReset => OtpRequestPurpose.passwordReset,
  };
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

class _AuthIdentityConflicts {
  const _AuthIdentityConflicts({
    this.emailRegistered = false,
    this.phoneRegistered = false,
  });

  final bool emailRegistered;
  final bool phoneRegistered;
}
