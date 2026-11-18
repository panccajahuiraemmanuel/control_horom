import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // CAMBIA ESTA URL POR LA RUTA REAL DE TU api.php EN BANAHOSTING
  static const String apiUrl = 'https://minelysiss.com/api_finanzas.php';

  static Future<List<dynamic>> obtenerFilasLuminarias() async {
    final response = await http
        .get(Uri.parse(apiUrl))
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded['status'] == 'success') {
        return decoded['data'] as List<dynamic>;
      }
      throw Exception(decoded['message'] ?? 'Error al consultar la API');
    } else {
      throw Exception('Error HTTP ${response.statusCode}');
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
      throw Exception(
        'Error al guardar en BanaHosting (${response.statusCode})',
      );
    }
    final decoded = jsonDecode(response.body);
    if (decoded['status'] != 'success') {
      throw Exception(decoded['message'] ?? 'No se pudo insertar el registro');
    }
  }
}
