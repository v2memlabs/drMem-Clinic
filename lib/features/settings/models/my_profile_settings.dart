/// Oturum açmış kullanıcının düzenlenebilir profil alanları.
class MyProfileSettings {
  final String displayName;
  final String firstName;
  final String lastName;
  final String title;
  final String phone;
  final String email;
  final String avatarStoragePath;

  const MyProfileSettings({
    this.displayName = '',
    this.firstName = '',
    this.lastName = '',
    this.title = '',
    this.phone = '',
    this.email = '',
    this.avatarStoragePath = '',
  });

  MyProfileSettings copyWith({
    String? displayName,
    String? firstName,
    String? lastName,
    String? title,
    String? phone,
    String? email,
    String? avatarStoragePath,
  }) {
    return MyProfileSettings(
      displayName: displayName ?? this.displayName,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      title: title ?? this.title,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      avatarStoragePath: avatarStoragePath ?? this.avatarStoragePath,
    );
  }
}
