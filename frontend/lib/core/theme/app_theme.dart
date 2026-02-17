import 'package:flutter/material.dart';

class AppTheme {
  // Colores principales de Forja Trabajo
  static const Color primaryIndigo = Color(0xFF4F46E5);
  static const Color successEmerald = Color(0xFF10B981);
  static const Color dangerRose = Color(0xFFF43F5E);
  static const Color backgroundDark = Color(0xFF0F172A);

  static ThemeData get theme {
    return ThemeData(
      primaryColor: primaryIndigo,
      scaffoldBackgroundColor: backgroundDark,
      // Aquí iremos agregando más estilos luego...
    );
  }
}