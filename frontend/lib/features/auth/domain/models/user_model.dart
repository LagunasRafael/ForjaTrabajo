import 'package:flutter/foundation.dart';
import '../../../services/data/models/category_model.dart';

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
  final String? bio;
  final List<CategoryModel>? categories;
  
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
    this.bio,
    this.categories,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final parsedId = json['id'] ?? '';
    final parsedEmail = json['email'] ?? '';
    final parsedFullName = json['full_name'] ?? 'Usuario';
    final parsedRole = (json['role'] ?? 'cliente').toString();
    final parsedIsEmailVerified = json['is_email_verified'] ?? false;
    final parsedIsIdentityVerified = json['is_identity_verified'] ?? false;
    final parsedPhone = json['phone'];
    final parsedProfilePictureUrl = json['profile_picture_url'];
    final parsedCity = json['city'];
    final parsedLatitude = json['latitude'];
    final parsedLongitude = json['longitude'];
    final parsedBio = json['bio'];
    
    List<CategoryModel>? parsedCategories;
    if (json['categories'] != null) {
      try {
        parsedCategories = (json['categories'] as List<dynamic>)
            .map((c) => CategoryModel.fromJson(c as Map<String, dynamic>))
            .toList();
      } catch (e) {
        debugPrint('🚨 [DEBUG PROD] Error parsing categories list: $e');
      }
    }

    final user = User(
      id: parsedId,
      email: parsedEmail,
      fullName: parsedFullName,
      role: parsedRole,
      isEmailVerified: parsedIsEmailVerified,
      isIdentityVerified: parsedIsIdentityVerified,
      phone: parsedPhone,
      profilePictureUrl: parsedProfilePictureUrl,
      city: parsedCity,
      latitude: parsedLatitude,
      longitude: parsedLongitude,
      bio: parsedBio,
      categories: parsedCategories,
    );

    debugPrint('==================================================');
    debugPrint('🚨 [DEBUG PROD] PARSED USER OBJECT:');
    debugPrint('   - ID: ${user.id}');
    debugPrint('   - Email: ${user.email}');
    debugPrint('   - Full Name: ${user.fullName}');
    debugPrint('   - Role (Raw in JSON): ${json['role']}');
    debugPrint('   - Role (Parsed String): ${user.role}');
    debugPrint('   - isWorker evaluated to: ${user.isWorker}');
    debugPrint('   - isClient evaluated to: ${user.isClient}');
    debugPrint('   - Bio: ${user.bio}');
    debugPrint('   - Categories: ${user.categories?.map((c) => c.name).toList()}');
    debugPrint('==================================================');

    return user;
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
    String? bio,
    List<CategoryModel>? categories,
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
      bio: bio ?? this.bio,
      categories: categories ?? this.categories,
    );
  }
}
