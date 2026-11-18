import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../core/date_utils_mina.dart';
import '../../state/mina_controller.dart';
import '../widgets/kpi_card.dart';

class DashboardScreen extends StatelessWidget {
  final MinaController controller;

  const DashboardScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final rango = DateUtilsMina.obtenerRangoSemana(controller.desfaseSemana);
    final registrosSemana = controller.registrosSemanaActual;

    final totalHoras = registrosSemana.fold<double>(
      0.0,
      (sum, r) => sum + r.horasOperadas,
    );
    final equiposActivosCount = registrosSemana.map((r) => r.equipoId).toSet().length;
    final promedioDiario = totalHoras / 7.0;

    final listaHistorial = controller.equipoFiltroId != null
        ? registrosSemana.where((r) => r.equipoId == controller.equipoFiltroId).toList()
        : registrosSemana;

    return ListView(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PERIODO OPERATIVO',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
                const SizedBox(height: 2),
                Text(
                  '${DateUtilsMina.formatearCorto(rango.lunes)} - ${DateUtilsMina.formatearCorto(rango.domingo)} (${rango.lunes.year})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.amberMinero,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => controller.cambiarSemana(-1),
                        child: const Text('← Anterior', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: controller.irASemanaActual,
                        child: const Text('Hoy', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => controller.cambiarSemana(1),
                        child: const Text('Siguiente →', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: KpiCard(
                titulo: 'Horas Semana',
                valor: '${totalHoras.toStringAsFixed(1)} h',
                colorValor: AppTheme.amberMinero,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: KpiCard(
                titulo: 'Activos / Total',
                valor: '$equiposActivosCount / ${controller.equipos.length}',
                colorValor: AppTheme.verdeOperativo,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: KpiCard(
                titulo: 'Prom. Diario',
                valor: '${promedioDiario.toStringAsFixed(1)} h',
                colorValor: AppTheme.azulKpi,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Resumen por Equipo',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (controller.equipoFiltroId != null)
              TextButton(
                onPressed: () => controller.alternarFiltroEquipo(null),
                child: const Text(
                  'Ver todos',
                  style: TextStyle(color: AppTheme.amberMinero, fontSize: 13),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        ...controller.equipos.map((eq) {
          final horasEq = registrosSemana
              .where((r) => r.equipoId == eq.id)
              .fold<double>(0.0, (sum, r) => sum + r.horasOperadas);
          final seleccionado = controller.equipoFiltroId == eq.id;

          return Card(
            color: seleccionado ? AppTheme.superficieSeleccionada : AppTheme.superficie,
            margin: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => controller.alternarFiltroEquipo(eq.id),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          eq.tipo,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.amberMinero,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          eq.codigo,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${eq.marca} ${eq.modelo} • ${eq.mina}',
                          style: const TextStyle(fontSize: 12, color: Colors.white70),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Último Horómetro: ${eq.ultimoHorometro.toStringAsFixed(1)} h',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Esta semana',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        Text(
                          '${horasEq.toStringAsFixed(1)} h',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.amberMinero,
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
        const Text(
          'Historial de Lecturas (Semana)',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (listaHistorial.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text(
                'Sin lecturas registradas en esta semana.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          ...listaHistorial.reversed.map((reg) {
            final eq = controller.equipos.firstWhere(
              (e) => e.id == reg.equipoId,
              orElse: () => controller.equipos.first,
            );
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${eq.codigo} • ${DateUtilsMina.formatearCorto(reg.fecha)} (${reg.turno})',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          Text(
                            'H. Inicial: ${reg.horometroInicial.toStringAsFixed(1)} → H. Final: ${reg.horometroFinal.toStringAsFixed(1)}',
                            style: const TextStyle(fontSize: 12, color: Colors.white70),
                          ),
                          if (reg.observaciones.isNotEmpty)
                            Text(
                              'Obs: ${reg.observaciones}',
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      '+${reg.horasOperadas.toStringAsFixed(1)} h',
                      style: const TextStyle(
                        color: AppTheme.verdeOperativo,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        const SizedBox(height: 80),
      ],
    );
  }
}
