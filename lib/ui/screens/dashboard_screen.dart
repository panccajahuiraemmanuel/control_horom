import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../core/date_utils_mina.dart';
import '../../state/mina_controller.dart';
import '../widgets/kpi_card.dart';

class DashboardScreen extends StatelessWidget {
  final MinaController controller;

  const DashboardScreen({super.key, required this.controller});

  static const List<String> _nombresDias = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

  bool _mismoDia(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final rango = DateUtilsMina.obtenerRangoSemana(controller.desfaseSemana);
    final registrosSemana = controller.registrosSemanaActual;

    final totalHoras = registrosSemana.fold<double>(0.0, (sum, r) => sum + r.horasOperadas);
    final equiposActivosCount = registrosSemana.map((r) => r.equipoId).toSet().length;
    final promedioDiario = totalHoras / 7.0;

    final listaHistorial = controller.equipoFiltroId != null
        ? registrosSemana.where((r) => r.equipoId == controller.equipoFiltroId).toList()
        : registrosSemana;

    final hoy = DateTime.now();

    return ListView(
      children: [
        // 1. TARJETA DE PERIODO OPERATIVO + CALENDARIO DE FECHAS REGISTRADAS
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 13, color: AppTheme.textoSecundario),
                            const SizedBox(width: 5),
                            Text(
                              controller.desfaseSemana == 0 ? 'SEMANA EN CURSO' : 'PERIODO OPERATIVO',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                                color: AppTheme.textoSecundario,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${DateUtilsMina.formatearCorto(rango.lunes)} - ${DateUtilsMina.formatearCorto(rango.domingo)} (${rango.lunes.year})',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.azulCorporativo,
                          ),
                        ),
                      ],
                    ),
                    // Controles compactos de navegación de semana (sin partir texto)
                    Row(
                      children: [
                        IconButton.outlined(
                          visualDensity: VisualDensity.compact,
                          onPressed: () => controller.cambiarSemana(-1),
                          icon: const Icon(Icons.chevron_left, size: 20),
                          tooltip: 'Semana anterior',
                        ),
                        const SizedBox(width: 4),
                        FilledButton.tonal(
                          style: FilledButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          onPressed: controller.irASemanaActual,
                          child: const Text('Hoy', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 4),
                        IconButton.outlined(
                          visualDensity: VisualDensity.compact,
                          onPressed: () => controller.cambiarSemana(1),
                          icon: const Icon(Icons.chevron_right, size: 20),
                          tooltip: 'Semana siguiente',
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(height: 1, color: AppTheme.borde),
                const SizedBox(height: 12),

                // Barra de los 7 días con indicador de fechas registradas
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(7, (index) {
                    final diaFecha = rango.lunes.add(Duration(days: index));
                    final registrosDelDia = registrosSemana.where((r) => _mismoDia(r.fecha, diaFecha)).toList();
                    final horasDelDia = registrosDelDia.fold<double>(0.0, (s, r) => s + r.horasOperadas);
                    final tieneRegistro = registrosDelDia.isNotEmpty;
                    final esHoy = _mismoDia(diaFecha, hoy);

                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2.5),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: tieneRegistro
                              ? AppTheme.azulCorporativo
                              : (esHoy ? AppTheme.amberSuave : AppTheme.fondoClaro),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: esHoy
                                ? AppTheme.amberMinero
                                : (tieneRegistro ? AppTheme.azulCorporativo : AppTheme.borde),
                            width: esHoy ? 1.5 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              _nombresDias[index],
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: tieneRegistro ? Colors.white70 : AppTheme.textoSecundario,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${diaFecha.day}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: tieneRegistro ? Colors.white : AppTheme.textoPrimario,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: tieneRegistro
                                    ? AppTheme.amberMinero
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                tieneRegistro ? '${horasDelDia.toStringAsFixed(1)}h' : '—',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: tieneRegistro ? Colors.white : AppTheme.textoSecundario,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // 2. KPIs SEMANALES
        Row(
          children: [
            Expanded(
              child: KpiCard(
                titulo: 'Horas Semana',
                valor: '${totalHoras.toStringAsFixed(1)} h',
                colorValor: AppTheme.amberMinero,
                icono: Icons.timer_outlined,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: KpiCard(
                titulo: 'Activos / Flota',
                valor: '$equiposActivosCount / ${controller.equipos.length}',
                colorValor: AppTheme.verdeOperativo,
                icono: Icons.check_circle_outline,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: KpiCard(
                titulo: 'Prom. Diario',
                valor: '${promedioDiario.toStringAsFixed(1)} h',
                colorValor: AppTheme.azulKpi,
                icono: Icons.trending_up,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // 3. RESUMEN POR EQUIPO
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Resumen por Equipo',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppTheme.textoPrimario,
              ),
            ),
            if (controller.equipoFiltroId != null)
              TextButton.icon(
                onPressed: () => controller.alternarFiltroEquipo(null),
                icon: const Icon(Icons.filter_alt_off, size: 15),
                label: const Text('Ver todos', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
        const SizedBox(height: 8),

        ...controller.equipos.map((eq) {
          final regsEq = registrosSemana.where((r) => r.equipoId == eq.id).toList();
          final horasEq = regsEq.fold<double>(0.0, (sum, r) => sum + r.horasOperadas);
          final seleccionado = controller.equipoFiltroId == eq.id;

          // Obtener fechas únicas registradas para este equipo en la semana
          final fechasRegistradasEq = regsEq
              .map((r) => DateUtilsMina.formatearCorto(r.fecha))
              .toSet()
              .toList();

          return Card(
            color: seleccionado ? AppTheme.superficieSeleccionada : AppTheme.superficie,
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: seleccionado ? AppTheme.azulCorporativo : AppTheme.borde,
                width: seleccionado ? 1.8 : 1,
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => controller.alternarFiltroEquipo(eq.id),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppTheme.amberSuave,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      eq.tipo,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.amberMinero,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFD1FAE5),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      eq.estado,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: AppTheme.verdeOperativo,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                eq.codigo,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textoPrimario,
                                ),
                              ),
                              Text(
                                '${eq.marca} ${eq.modelo} •${eq.mina}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textoSecundario,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Uso semanal',
                              style: TextStyle(fontSize: 11, color: AppTheme.textoSecundario),
                            ),
                            Text(
                              '${horasEq.toStringAsFixed(1)} h',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.azulCorporativo,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Divider(height: 1, color: AppTheme.borde),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Último Horómetro: ${eq.ultimoHorometro.toStringAsFixed(1)} h',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textoPrimario,
                          ),
                        ),
                        Text(
                          fechasRegistradasEq.isEmpty
                              ? 'Sin fechas registradas'
                              : 'Fechas: ${fechasRegistradasEq.join(', ')}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: fechasRegistradasEq.isEmpty
                                ? AppTheme.textoSecundario
                                : AppTheme.verdeOperativo,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }),

        const SizedBox(height: 12),

        // 4. HISTORIAL DETALLADO CON FECHAS REGISTRADAS
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Fechas y Lecturas Registradas',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppTheme.textoPrimario,
              ),
            ),
            Text(
              '${listaHistorial.length} registros',
              style: const TextStyle(fontSize: 12, color: AppTheme.textoSecundario),
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (listaHistorial.isEmpty)
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
              child: Column(
                children: [
                  const Icon(Icons.event_busy, size: 36, color: AppTheme.textoSecundario),
                  const SizedBox(height: 8),
                  const Text(
                    'Sin lecturas en esta semana operativa',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textoPrimario,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Pulsa "Hoy" para volver a la semana actual o registra un nuevo horómetro.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: AppTheme.textoSecundario),
                  ),
                ],
              ),
            ),
          )
        else
          ...listaHistorial.reversed.map((reg) {
            final eq = controller.equipos.firstWhere(
              (e) => e.id == reg.equipoId,
              orElse: () => controller.equipos.first,
            );
            final esDia = reg.turno == 'Día';

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    // Insignia de Fecha Registrada
                    Container(
                      width: 54,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.fondoClaro,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.borde),
                      ),
                      child: Column(
                        children: [
                          Text(
                            DateUtilsMina.formatearCorto(reg.fecha).split(' ')[0],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.azulCorporativo,
                            ),
                          ),
                          Text(
                            DateUtilsMina.formatearCorto(reg.fecha).split(' ')[1].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textoSecundario,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Detalle de Equipo, Turno y Horómetros
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                eq.codigo,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  color: AppTheme.textoPrimario,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: esDia ? AppTheme.amberSuave : const Color(0xFFE0E7FF),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Turno ${reg.turno}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: esDia ? AppTheme.amberMinero : AppTheme.azulCorporativo,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'H. Inicial: ${reg.horometroInicial.toStringAsFixed(1)}  →  H. Final: ${reg.horometroFinal.toStringAsFixed(1)}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textoSecundario,
                            ),
                          ),
                          if (reg.observaciones.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                'Nota: ${reg.observaciones}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textoSecundario,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Horas Efectivas
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD1FAE5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '+${reg.horasOperadas.toStringAsFixed(1)} h',
                        style: const TextStyle(
                          color: AppTheme.verdeOperativo,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        const SizedBox(height: 85),
      ],
    );
  }
}
