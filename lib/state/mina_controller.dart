import 'package:flutter/material.dart';
import '../core/date_utils_mina.dart';
import '../models/equipo.dart';
import '../models/registro_horometro.dart';

class MinaController extends ChangeNotifier {
  int indicePantalla = 0;
  int desfaseSemana = 0;
  String? equipoFiltroId;

  bool vieneDeHorometro = false;
  String? equipoPreseleccionadoId;
  String horometroFinalTemporal = '';

  final List<Equipo> equipos = [
    Equipo(
      id: 'eq-1',
      codigo: 'SCOOP-01',
      tipo: 'Scooptram',
      marca: 'Caterpillar',
      modelo: 'R1600H',
      horometroBase: 1200.0,
      ultimoHorometro: 1214.5,
      mina: 'Unidad Sur',
    ),
    Equipo(
      id: 'eq-2',
      codigo: 'VOL-04',
      tipo: 'Volquete / Dumper',
      marca: 'Volvo',
      modelo: 'FMX 8x4',
      horometroBase: 3400.0,
      ultimoHorometro: 3408.0,
      mina: 'Tajo Norte',
    ),
  ];

  late final List<RegistroHorometro> registros;

  MinaController() {
    final hoy = DateTime.now();
    registros = [
      RegistroHorometro(
        id: 'r-1',
        equipoId: 'eq-1',
        fecha: hoy,
        turno: 'Día',
        horometroInicial: 1200.0,
        horometroFinal: 1207.5,
        horasOperadas: 7.5,
        observaciones: 'Limpieza Nv 320',
      ),
      RegistroHorometro(
        id: 'r-2',
        equipoId: 'eq-1',
        fecha: hoy,
        turno: 'Noche',
        horometroInicial: 1207.5,
        horometroFinal: 1214.5,
        horasOperadas: 7.0,
        observaciones: 'Sin novedades',
      ),
      RegistroHorometro(
        id: 'r-3',
        equipoId: 'eq-2',
        fecha: hoy,
        turno: 'Día',
        horometroInicial: 3400.0,
        horometroFinal: 3408.0,
        horasOperadas: 8.0,
        observaciones: 'Acarreo desmonte',
      ),
    ];
  }

  List<RegistroHorometro> get registrosSemanaActual {
    final rango = DateUtilsMina.obtenerRangoSemana(desfaseSemana);
    return registros.where((r) {
      return !r.fecha.isBefore(rango.lunes) && !r.fecha.isAfter(rango.domingo);
    }).toList();
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

  void cambiarSemana(int delta) {
    desfaseSemana += delta;
    notifyListeners();
  }

  void irASemanaActual() {
    desfaseSemana = 0;
    notifyListeners();
  }

  void alternarFiltroEquipo(String? id) {
    equipoFiltroId = (equipoFiltroId == id) ? null : id;
    notifyListeners();
  }

  void guardarRegistroHorometro(RegistroHorometro nuevo) {
    registros.add(nuevo);
    final idx = equipos.indexWhere((e) => e.id == nuevo.equipoId);
    if (idx != -1) {
      equipos[idx].ultimoHorometro = nuevo.horometroFinal;
    }
    horometroFinalTemporal = '';
    indicePantalla = 0;
    notifyListeners();
  }

  bool codigoEquipoExiste(String codigo) {
    return equipos.any((e) => e.codigo.toUpperCase() == codigo.toUpperCase());
  }

  void guardarNuevoEquipo(Equipo nuevo) {
    equipos.add(nuevo);
    if (vieneDeHorometro) {
      equipoPreseleccionadoId = nuevo.id;
      indicePantalla = 1;
    } else {
      indicePantalla = 0;
    }
    notifyListeners();
  }
}
