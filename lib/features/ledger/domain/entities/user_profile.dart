class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.emailVerified,
    this.privacyPolicyAccepted = false,
    this.privacyPolicyAcceptedAt,
    this.privacyPolicyVersion = '',
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final bool emailVerified;
  final bool privacyPolicyAccepted;
  final DateTime? privacyPolicyAcceptedAt;
  final String privacyPolicyVersion;

  UserProfile copyWith({
    String? name,
    String? email,
    String? phone,
    bool? emailVerified,
    bool? privacyPolicyAccepted,
    DateTime? privacyPolicyAcceptedAt,
    String? privacyPolicyVersion,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      emailVerified: emailVerified ?? this.emailVerified,
      privacyPolicyAccepted:
          privacyPolicyAccepted ?? this.privacyPolicyAccepted,
      privacyPolicyAcceptedAt:
          privacyPolicyAcceptedAt ?? this.privacyPolicyAcceptedAt,
      privacyPolicyVersion: privacyPolicyVersion ?? this.privacyPolicyVersion,
    );
  }
}
