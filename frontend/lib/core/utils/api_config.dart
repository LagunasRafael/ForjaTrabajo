import 'package:flutter/foundation.dart';

class ApiConfig {
  static String get baseUrl {
    if (kReleaseMode) {
      return 'https://forja-api-rw0r.onrender.com';
    }
    return 'http://localhost:8000';
  }
}