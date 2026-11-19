import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static String apiUrl = 'tu direccion de api';

  static Future<List<dynamic>> obtenerFilasLuminarias() async {
    try {
      final response = await http
          .get(Uri.parse(apiUrl))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        if (response.body.trim().isEmpty) return [];
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['status'] == 'success') {
          return decoded['data'] as List<dynamic>? ?? [];
        }
        return [];
      } else {
        throw Exception('Error HTTP ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error al conectar con la API: $e');
      return [];
    }
  }

  static Future<void> insertarFilaLuminaria({
    required String codigo,
    required String areaZona,
    required String estado,
    required String fechaRegistro,
    required String observacion,
    required double horometro,
  }) async {
    final response = await http
        .post(
          Uri.parse(apiUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'codigo': codigo,
            'area_zona': areaZona,
            'estado': estado,
            'fecha_registro': fechaRegistro,
            'observacion': observacion,
            'horometro': horometro,
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Error al guardar (${response.statusCode})');
    }
    final decoded = jsonDecode(response.body);
    if (decoded['status'] != 'success') {
      throw Exception(decoded['message'] ?? 'No se pudo insertar el registro');
    }
  }

  static Future<void> actualizarFilaLuminaria({
    required String id,
    required double horometro,
    required String observacion,
  }) {
    return _enviarAccion({
      'accion': 'actualizar',
      'id': id,
      'horometro': horometro,
      'observacion': observacion,
    }, 'No se pudo actualizar el registro');
  }

  static Future<void> eliminarFilaLuminaria({required String id}) {
    return _enviarAccion({
      'accion': 'eliminar',
      'id': id,
    }, 'No se pudo eliminar el registro');
  }

  static Future<void> _enviarAccion(
    Map<String, dynamic> cuerpo,
    String mensajeError,
  ) async {
    final response = await http
        .post(
          Uri.parse(apiUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(cuerpo),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('$mensajeError (HTTP ${response.statusCode})');
    }
    final decoded = jsonDecode(response.body);
    if (decoded['status'] != 'success') {
      throw Exception(decoded['message'] ?? mensajeError);
    }
  }
}
