import 'package:flutter/material.dart';

class AppTheme {
  static const Color amberMinero = Color(0xFFF59E0B);
  static const Color fondoOscuro = Color(0xFF0F172A);
  static const Color superficie = Color(0xFF1E293B);
  static const Color superficieSeleccionada = Color(0xFF334155);
  static const Color verdeOperativo = Color(0xFF34D399);
  static const Color azulKpi = Color(0xFF38BDF8);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: fondoOscuro,
      colorScheme: const ColorScheme.dark(
        primary: amberMinero,
        onPrimary: fondoOscuro,
        surface: superficie,
        onSurface: Color(0xFFF8FAFC),
      ),
      cardTheme: CardThemeData(
        color: superficie,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
