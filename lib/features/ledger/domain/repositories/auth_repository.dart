import '../entities/user_profile.dart';

abstract interface class PreferredCurrencyRepository {
  Future<UserProfile> updatePreferredCurrency(String currencyCode);
}

abstract interface class AuthRepository {
  Stream<UserProfile?> watchProfile();
  UserProfile? get currentProfile;
  Future<UserProfile?> restoreSession();
  Future<UserProfile?> refreshProfile();
  Future<void> signIn({required String identifier, required String password});
  Future<void> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required bool privacyPolicyAccepted,
  });
  Future<UserProfile> acceptPrivacyPolicy({required String version});
  Future<void> resendEmailVerification(String email);
  Future<UserProfile> verifyEmailOtp({
    required String email,
    required String token,
  });
  Future<UserProfile> updateProfile({
    required String name,
    required String phone,
  });

  /// Accepts an email or phone identifier (same as login) and returns the
  /// email address the recovery OTP was actually sent to.
  Future<String> requestPasswordReset(String identifier);
  Future<void> resetPasswordWithOtp({
    required String email,
    required String token,
    required String newPassword,
  });
  Future<void> signOut();
}
