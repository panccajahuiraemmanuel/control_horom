import 'package:flutter/material.dart';

class AppTheme {
  // Paleta Corporativa Clara Industrial
  static const Color amberMinero = Color(0xFFD97706);
  static const Color amberSuave = Color(0xFFFEF3C7);
  static const Color azulCorporativo = Color(0xFF1E3A8A);
  static const Color fondoClaro = Color(0xFFF1F5F9);
  static const Color superficie = Color(0xFFFFFFFF);
  static const Color superficieSeleccionada = Color(0xFFEFF6FF);
  static const Color borde = Color(0xFFE2E8F0);
  static const Color textoPrimario = Color(0xFF0F172A);
  static const Color textoSecundario = Color(0xFF64748B);
  static const Color verdeOperativo = Color(0xFF059669);
  static const Color azulKpi = Color(0xFF0284C7);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: fondoClaro,
      colorScheme: const ColorScheme.light(
        primary: azulCorporativo,
        onPrimary: Colors.white,
        secondary: amberMinero,
        onSecondary: Colors.white,
        surface: superficie,
        onSurface: textoPrimario,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: azulCorporativo,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: superficie,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: borde, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: borde),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: borde),
        ),
      ),
    );
  }
}
