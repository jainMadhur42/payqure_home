import '../../../legal/domain/legal_content.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/auth_repository.dart';

class SessionController {
  const SessionController(this._repository);

  final AuthRepository _repository;

  Stream<UserProfile?> watchProfile() => _repository.watchProfile();

  UserProfile? get currentProfile => _repository.currentProfile;

  Future<UserProfile?> restore({Duration? timeout}) {
    final restoration = _repository.restoreSession();
    return timeout == null ? restoration : restoration.timeout(timeout);
  }

  Future<UserProfile?> refresh() => _repository.refreshProfile();

  Future<UserProfile> signIn({
    required String identifier,
    required String password,
  }) async {
    await _repository.signIn(identifier: identifier, password: password);
    return _requireCurrentProfile('Sign in did not return a user profile.');
  }

  Future<UserProfile> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required bool privacyPolicyAccepted,
  }) async {
    await _repository.register(
      name: name,
      email: email,
      phone: phone,
      password: password,
      privacyPolicyAccepted: privacyPolicyAccepted,
    );
    return _requireCurrentProfile('Profile not set after registration.');
  }

  Future<void> resendEmailVerification(String email) {
    return _repository.resendEmailVerification(email);
  }

  Future<UserProfile> verifyEmailOtp({
    required String email,
    required String token,
  }) {
    return _repository.verifyEmailOtp(email: email, token: token);
  }

  Future<UserProfile> acceptPrivacyPolicy() {
    return _repository.acceptPrivacyPolicy(version: LegalContent.policyVersion);
  }

  Future<UserProfile> updateProfile({
    required String name,
    required String phone,
  }) {
    return _repository.updateProfile(name: name, phone: phone);
  }

  Future<String> requestPasswordReset(String identifier) {
    return _repository.requestPasswordReset(identifier);
  }

  Future<void> resetPassword({
    required String email,
    required String token,
    required String newPassword,
  }) {
    return _repository.resetPasswordWithOtp(
      email: email,
      token: token,
      newPassword: newPassword,
    );
  }

  Future<void> signOut() => _repository.signOut();

  bool isLocalDevelopmentProfile(UserProfile profile) {
    return profile.id == 'local-user' || profile.id.startsWith('profile_');
  }

  bool requiresPrivacyAcceptance(UserProfile profile) {
    if (isLocalDevelopmentProfile(profile)) {
      return false;
    }
    return !profile.privacyPolicyAccepted ||
        profile.privacyPolicyVersion != LegalContent.policyVersion;
  }

  UserProfile _requireCurrentProfile(String message) {
    final profile = _repository.currentProfile;
    if (profile == null) {
      throw StateError(message);
    }
    return profile;
  }
}
