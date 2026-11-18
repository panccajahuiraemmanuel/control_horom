class DateUtilsMina {
  static const List<String> _meses = [
    'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
    'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
  ];

  static String formatearCorto(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')} ${_meses[fecha.month - 1]}';
  }

  static ({DateTime lunes, DateTime domingo}) obtenerRangoSemana(int desfaseSemana) {
    final ref = DateTime.now().add(Duration(days: desfaseSemana * 7));
    final lunes = DateTime(ref.year, ref.month, ref.day)
        .subtract(Duration(days: ref.weekday - 1));
    final domingo = lunes.add(
      const Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
    );
    return (lunes: lunes, domingo: domingo);
  }
}
