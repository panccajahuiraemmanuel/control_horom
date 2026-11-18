class RegistroHorometro {
  final String id;
  final String equipoId;
  final DateTime fecha;
  final String turno;
  final double horometroInicial;
  final double horometroFinal;
  final double horasOperadas;
  final String observaciones;

  RegistroHorometro({
    required this.id,
    required this.equipoId,
    required this.fecha,
    required this.turno,
    required this.horometroInicial,
    required this.horometroFinal,
    required this.horasOperadas,
    required this.observaciones,
  });
}
