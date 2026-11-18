class Equipo {
  final String id;
  final String codigo;
  final String tipo;
  final String marca;
  final String modelo;
  final double horometroBase;
  double ultimoHorometro;
  final String mina;
  final String estado;

  Equipo({
    required this.id,
    required this.codigo,
    required this.tipo,
    required this.marca,
    required this.modelo,
    required this.horometroBase,
    required this.ultimoHorometro,
    required this.mina,
    this.estado = 'Operativo',
  });
}
