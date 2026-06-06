class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.emailVerified,
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final bool emailVerified;

  UserProfile copyWith({
    String? name,
    String? email,
    String? phone,
    bool? emailVerified,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      emailVerified: emailVerified ?? this.emailVerified,
    );
  }
}
