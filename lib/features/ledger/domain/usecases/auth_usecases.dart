import '../repositories/auth_repository.dart';

class SignIn {
  const SignIn(this._repository);

  final AuthRepository _repository;

  Future<void> call({required String identifier, required String password}) {
    return _repository.signIn(identifier: identifier, password: password);
  }
}

class RegisterUser {
  const RegisterUser(this._repository);

  final AuthRepository _repository;

  Future<void> call({
    required String name,
    required String email,
    required String phone,
    required String password,
    required bool privacyPolicyAccepted,
  }) {
    return _repository.register(
      name: name,
      email: email,
      phone: phone,
      password: password,
      privacyPolicyAccepted: privacyPolicyAccepted,
    );
  }
}

class RequestPasswordReset {
  const RequestPasswordReset(this._repository);

  final AuthRepository _repository;

  Future<void> call(String email) => _repository.requestPasswordReset(email);
}

class ResetPasswordWithOtp {
  const ResetPasswordWithOtp(this._repository);

  final AuthRepository _repository;

  Future<void> call({
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
}
