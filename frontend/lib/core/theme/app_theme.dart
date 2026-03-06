import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // --- 🎨 COLORES DEL NUEVO DISEÑO (Stitch / Claro) ---
  static const Color primaryColor = Color(0xFF3B19E6);
  static const Color backgroundColor = Color(0xFFF6F6F8);
  static const Color textColor = Color(0xFF100E1B);
  static const Color subtitleColor = Color(0xFF5A4E97);

  // --- 🌙 COLORES DEL LOGIN ORIGINAL (Oscuro / Alertas) ---
  static const Color primaryIndigo = Color(0xFF4F46E5);
  static const Color backgroundDark = Color(0xFF0F172A);

  // --- 🚨 COLORES DE ESTADO (Para Snackbars) ---
  static const Color successEmerald = Color(0xFF10B981);
  static const Color dangerRose = Color(0xFFF43F5E);

  // Configuración global del tema claro
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      textTheme: GoogleFonts.interTextTheme(),
    );
  }

  // Configuración global del tema oscuro
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundDark,
      cardColor: const Color(0xFF1E293B), // Gris azulado oscuro para tarjetas
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundDark,
        foregroundColor: Colors.white,
      ),
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.dark().textTheme,
      ),
      iconTheme: const IconThemeData(color: Colors.white),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF1E293B),
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}
