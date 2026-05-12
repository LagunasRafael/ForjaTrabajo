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

  User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.isEmailVerified,
    this.phone,
    this.profilePictureUrl,
    this.city,
    this.latitude,
    this.longitude,
  });

  // Esta fábrica convierte el JSON de FastAPI a un objeto de Dart
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      fullName:
          json['full_name'] ?? 'Usuario', // Cuidado: FastAPI manda "full_name"
      role: json['role'] ?? 'cliente',
      isEmailVerified: json['is_email_verified'] ?? false,
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
      phone: phone ?? this.phone,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      city: city ?? this.city,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}
