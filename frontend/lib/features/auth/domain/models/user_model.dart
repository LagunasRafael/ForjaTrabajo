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

  User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
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
      fullName: json['full_name'] ?? 'Usuario', // Cuidado: FastAPI manda "full_name"
      role: json['role'] ?? 'cliente',
      phone: json['phone'],
      profilePictureUrl: json['profile_picture_url'],
      city: json['city'],
      latitude: json['latitude'],
      longitude: json['longitude'],
    );
  }
}