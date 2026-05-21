class User {
  final String id;
  final String email;
  final String fullName;
  final String role;
  final String? phone;
  final String? profilePictureUrl;
  final String? city;
  final double? latitude;
  final double? longitude;
  final bool isEmailVerified;
  final bool isIdentityVerified;
  
  // 🛡️ Ayudantes de verificación de rol
  bool get isWorker => role.toLowerCase().contains('worker') || role.toLowerCase().contains('trabajador');
  bool get isClient => role.toLowerCase().contains('client') || role.toLowerCase().contains('cliente');


  User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.isEmailVerified,
    this.isIdentityVerified = false,
    this.phone,
    this.profilePictureUrl,
    this.city,
    this.latitude,
    this.longitude,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? 'Usuario',
      role: json['role'] ?? 'cliente',
      isEmailVerified: json['is_email_verified'] ?? false,
      isIdentityVerified: json['is_identity_verified'] ?? false,
      phone: json['phone'],
      profilePictureUrl: json['profile_picture_url'],
      city: json['city'],
      latitude: json['latitude'],
      longitude: json['longitude'],
    );
  }

  User copyWith({
    String? id,
    String? email,
    String? fullName,
    String? role,
    bool? isEmailVerified,
    bool? isIdentityVerified,
    String? phone,
    String? profilePictureUrl,
    String? city,
    double? latitude,
    double? longitude,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isIdentityVerified: isIdentityVerified ?? this.isIdentityVerified,
      phone: phone ?? this.phone,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      city: city ?? this.city,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}
