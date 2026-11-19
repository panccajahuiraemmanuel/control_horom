import 'package:flutter/material.dart';

class AppTheme {
  static const Color azulCorporativo = Color(0xFF0F172A);
  static const Color superficie = Color(0xFF1E293B);
  static const Color superficieSeleccionada = Color(0xFF334155);
  static const Color fondoClaro = Color(0xFF0B1120);
  static const Color amberMinero = Color(0xFFF59E0B);
  static const Color verdeOperativo = Color(0xFF34D399);
  static const Color rojoError = Color(0xFFF87171);
  static const Color textoPrimario = Color(0xFFF8FAFC);
  static const Color textoSecundario = Color(0xFF94A3B8);
  static const Color borde = Color(0xFF334155);

  static ThemeData get temaOscuro {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: azulCorporativo,
      colorScheme: const ColorScheme.dark(
        primary: amberMinero,
        surface: superficie,
        onSurface: textoPrimario,
      ),
    );
  }
}
