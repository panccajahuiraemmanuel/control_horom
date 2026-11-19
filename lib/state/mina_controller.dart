import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../models/equipo.dart';
import '../models/registro_horometro.dart';

class MinaController extends ChangeNotifier {
  int indicePantalla = 0;
  String? equipoFiltroId;

  String fechaSeleccionadaISO = DateTime.now().toIso8601String().split('T')[0];

  bool cargando = false;
  String? errorConexion;

  bool vieneDeHorometro = false;
  String? equipoPreseleccionadoId;
  String horometroFinalTemporal = '';

  final List<Equipo> equipos = [];
  final List<RegistroHorometro> registros = [];

  MinaController() {
    cargarDesdeBanaHosting();
  }

  String _inferirTipo(String codigo) {
    final c = codigo.toUpperCase();
    if (c.contains('TI')) return 'Torre Iluminación';
    if (c.contains('GE')) return 'Grupo Electrógeno';
    return 'Maquinaria / Equipo';
  }

  String _formatearFechaISO(DateTime f) {
    final y = f.year.toString();
    final m = f.month.toString().padLeft(2, '0');
    final d = f.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<void> cargarDesdeBanaHosting() async {
    cargando = true;
    errorConexion = null;
    notifyListeners();

    try {
      final filas = await ApiService.obtenerFilasLuminarias();

      final Map<String, List<dynamic>> porCodigo = {};
      for (final f in filas) {
        final cod = (f['codigo'] ?? '').toString().trim().toUpperCase();
        if (cod.isEmpty) continue;
        porCodigo.putIfAbsent(cod, () => []).add(f);
      }

      equipos.clear();
      registros.clear();

      for (final entry in porCodigo.entries) {
        final cod = entry.key;
        final lista = entry.value;

        // Ordenar cronológicamente
        lista.sort((a, b) {
          final cmpFecha = (a['fecha_registro'] ?? '').toString().compareTo(
            (b['fecha_registro'] ?? '').toString(),
          );
          if (cmpFecha != 0) return cmpFecha;
          final hA = double.tryParse(a['horometro']?.toString() ?? '0') ?? 0.0;
          final hB = double.tryParse(b['horometro']?.toString() ?? '0') ?? 0.0;
          return hA.compareTo(hB);
        });

        final primero = lista.first;
        final ultimo = lista.last;
        final hBase =
            double.tryParse(primero['horometro']?.toString() ?? '0') ?? 0.0;
        final hUltimo =
            double.tryParse(ultimo['horometro']?.toString() ?? '0') ?? hBase;

        equipos.add(
          Equipo(
            id: cod,
            codigo: cod,
            tipo: _inferirTipo(cod),
            marca: 'Área',
            modelo: (ultimo['area_zona'] ?? 'SIN ÁREA').toString(),
            horometroBase: hBase,
            ultimoHorometro: hUltimo,
            mina: (ultimo['area_zona'] ?? 'SIN ÁREA').toString(),
            estado: (ultimo['estado'] ?? 'OPERATIVO').toString(),
          ),
        );

        double? horometroAnterior;
        for (final fila in lista) {
          final hActual =
              double.tryParse(fila['horometro']?.toString() ?? '0') ?? 0.0;
          final hIni = horometroAnterior ?? hActual;
          final diff = (hActual - hIni) > 0 ? (hActual - hIni) : 0.0;
          final fecha =
              DateTime.tryParse(fila['fecha_registro']?.toString() ?? '') ??
              DateTime.now();

          registros.add(
            RegistroHorometro(
              id:
                  fila['id']?.toString() ??
                  DateTime.now().millisecondsSinceEpoch.toString(),
              equipoId: cod,
              fecha: fecha,
              turno: (fila['area_zona'] ?? 'General').toString(),
              horometroInicial: hIni,
              horometroFinal: hActual,
              horasOperadas: double.parse(diff.toStringAsFixed(1)),
              observaciones: (fila['observacion'] ?? '').toString(),
            ),
          );
          horometroAnterior = hActual;
        }
      }

      equipos.sort((a, b) => a.codigo.compareTo(b.codigo));

      // POSICIONAR AUTOMÁTICAMENTE EN LA FECHA DEL REGISTRO MÁS RECIENTE
      if (registros.isNotEmpty) {
        registros.sort((a, b) => b.fecha.compareTo(a.fecha));
        fechaSeleccionadaISO = _formatearFechaISO(registros.first.fecha);
      }
    } catch (e) {
      errorConexion = e.toString();
    } finally {
      cargando = false;
      notifyListeners();
    }
  }

  // FILTRO ESTRICTO Y CORRECTO POR DÍA (Sin mezclar historiales)
  List<RegistroHorometro> get registrosDiaSeleccionado {
    return registros.where((r) {
      return _formatearFechaISO(r.fecha) == fechaSeleccionadaISO;
    }).toList();
  }

  void seleccionarFecha(DateTime fecha) {
    fechaSeleccionadaISO = _formatearFechaISO(fecha);
    notifyListeners();
  }

  void cambiarPestana(int nuevoIndice) {
    if (nuevoIndice == 1) {
      equipoPreseleccionadoId = equipos.isNotEmpty ? equipos.first.id : null;
    } else if (nuevoIndice == 2) {
      vieneDeHorometro = false;
    }
    indicePantalla = nuevoIndice;
    notifyListeners();
  }

  void abrirCapturaHorometro() {
    equipoPreseleccionadoId = equipos.isNotEmpty ? equipos.first.id : null;
    indicePantalla = 1;
    notifyListeners();
  }

  void derivarANuevoEquipo(String lecturaEnMemoria) {
    horometroFinalTemporal = lecturaEnMemoria;
    vieneDeHorometro = true;
    indicePantalla = 2;
    notifyListeners();
  }

  void volverDesdeAltaEquipo() {
    indicePantalla = vieneDeHorometro ? 1 : 0;
    notifyListeners();
  }

  void cancelarCapturaHorometro() {
    horometroFinalTemporal = '';
    indicePantalla = 0;
    notifyListeners();
  }

  void cambiarDiaOffset(int dias) {
    final actual = DateTime.tryParse(fechaSeleccionadaISO) ?? DateTime.now();
    final nueva = actual.add(Duration(days: dias));
    fechaSeleccionadaISO = _formatearFechaISO(nueva);
    notifyListeners();
  }

  void irAFechaHoy() {
    fechaSeleccionadaISO = DateTime.now().toIso8601String().split('T')[0];
    notifyListeners();
  }

  void alternarFiltroEquipo(String? id) {
    equipoFiltroId = (equipoFiltroId == id) ? null : id;
    notifyListeners();
  }

  Future<void> guardarRegistroHorometro(RegistroHorometro nuevo) async {
    final eqIndex = equipos.indexWhere((e) => e.id == nuevo.equipoId);
    final areaActual = eqIndex != -1 ? equipos[eqIndex].mina : nuevo.turno;
    final estadoActual = eqIndex != -1 ? equipos[eqIndex].estado : 'OPERATIVO';
    final fechaISO = _formatearFechaISO(nuevo.fecha);

    await ApiService.insertarFilaLuminaria(
      codigo: nuevo.equipoId,
      areaZona: areaActual,
      estado: estadoActual,
      fechaRegistro: fechaISO,
      observacion: nuevo.observaciones.isEmpty
          ? 'SIN OBSERVACIÓN'
          : nuevo.observaciones,
      horometro: nuevo.horometroFinal,
    );

    horometroFinalTemporal = '';
    indicePantalla = 0;
    await cargarDesdeBanaHosting();
  }

  Future<void> eliminarRegistro(String id) async {
    await ApiService.eliminarFilaLuminaria(id: id);
    await cargarDesdeBanaHosting();
  }

  Future<void> actualizarRegistro({
    required String id,
    required double horometro,
    required String observacion,
  }) async {
    await ApiService.actualizarFilaLuminaria(
      id: id,
      horometro: horometro,
      observacion: observacion.isEmpty ? 'SIN OBSERVACIÓN' : observacion,
    );
    await cargarDesdeBanaHosting();
  }

  bool codigoEquipoExiste(String codigo) {
    return equipos.any((e) => e.codigo.toUpperCase() == codigo.toUpperCase());
  }

  Future<void> guardarNuevoEquipo(Equipo nuevo) async {
    final fechaISO = _formatearFechaISO(DateTime.now());

    await ApiService.insertarFilaLuminaria(
      codigo: nuevo.codigo,
      areaZona: nuevo.mina,
      estado: nuevo.estado,
      fechaRegistro: fechaISO,
      observacion: 'ALTA INICIAL DE EQUIPO',
      horometro: nuevo.horometroBase,
    );

    await cargarDesdeBanaHosting();

    if (vieneDeHorometro) {
      equipoPreseleccionadoId = nuevo.codigo;
      indicePantalla = 1;
    } else {
      indicePantalla = 0;
    }
    notifyListeners();
  }
}
