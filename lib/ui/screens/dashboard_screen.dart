import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import '../../core/responsive.dart';
import '../../models/registro_horometro.dart';
import '../../state/mina_controller.dart';

/// Paleta minera clara: fondo blanco-niebla, ámbar de seguridad y hero grafito.
class _P {
  static const fondo = Color(0xFFF3F5F7);
  static const superficie = Color(0xFFFFFFFF);
  static const superficieAlta = Color(0xFFEEF1F4);
  static const superficieSeleccionada = Color(0xFFFFF3D6);
  static const borde = Color(0xFFDDE3E9);
  static const textoPrimario = Color(0xFF14191E);
  static const textoSecundario = Color(0xFF5F6C78);
  static const tinta = Color(0xFF14191E);

  static const amber = Color(0xFFFFB300);
  static const amberOscuro = Color(0xFFB36B00); // ámbar legible sobre blanco
  static const rojoError = Color(0xFFD7263D);
  static const verdeOperativo = Color(0xFF138A5B);

  static const acentoTi = Color(0xFFE8741A);
  static const acentoGe = Color(0xFF1E88E5);
  static const acentoMaq = Color(0xFF0E8A8A);

  // Tarjeta principal (se mantiene oscura)
  static const heroClaro = Color(0xFF2E3943);
  static const heroMedio = Color(0xFF1F272E);
  static const heroOscuro = Color(0xFF151A1F);
}

Color _acento(String codigo) {
  final c = codigo.toUpperCase();
  if (c.contains('TI')) return _P.acentoTi;
  if (c.contains('GE')) return _P.acentoGe;
  return _P.acentoMaq;
}

ThemeData _temaOscuro(BuildContext context) => ThemeData.light().copyWith(
  colorScheme: const ColorScheme.light(
    primary: _P.amber,
    onPrimary: _P.tinta,
    surface: _P.superficie,
    onSurface: _P.textoPrimario,
  ),
);

class DashboardScreen extends StatelessWidget {
  final MinaController controller;

  const DashboardScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final parsed =
        DateTime.tryParse(controller.fechaSeleccionadaISO) ?? DateTime.now();
    final fecha = DateTime(parsed.year, parsed.month, parsed.day);
    final esHoy = _mismoDia(fecha, DateTime.now());

    final registros = controller.registrosDiaSeleccionado;
    final totalHoras = registros.fold<double>(
      0.0,
      (sum, r) => sum + r.horasOperadas,
    );
    final promedio = registros.isEmpty ? 0.0 : totalHoras / registros.length;
    final equiposActivos = registros.map((r) => r.equipoId).toSet().length;

    final porEquipo = <String, double>{};
    for (final r in registros) {
      porEquipo[r.equipoId] = (porEquipo[r.equipoId] ?? 0) + r.horasOperadas;
    }
    final maxHoras = registros.fold<double>(
      0.0,
      (m, r) => r.horasOperadas > m ? r.horasOperadas : m,
    );

    final diasConDatos = controller.registros
        .map((r) => _clave(r.fecha))
        .toSet();

    final lista = registros.reversed.toList();

    return ColoredBox(
      color: _P.fondo,
      child: ContenidoCentrado(
        child: ListView(
          padding: EdgeInsets.only(
            bottom: 88 + MediaQuery.paddingOf(context).bottom,
          ),
          children: [
            if (controller.cargando)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: const LinearProgressIndicator(
                    minHeight: 3,
                    color: _P.amber,
                    backgroundColor: _P.superficieAlta,
                  ),
                ),
              ),

            _Cabecera(
              fecha: fecha,
              esHoy: esHoy,
              totalHoras: totalHoras,
              lecturas: registros.length,
              promedio: promedio,
              equipos: equiposActivos,
              porEquipo: porEquipo,
              diasConDatos: diasConDatos,
              onElegirDia: controller.seleccionarFecha,
              onSemana: (dir) => controller.cambiarDiaOffset(7 * dir),
              onHoy: controller.irAFechaHoy,
              onCalendario: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: fecha,
                  firstDate: DateTime(2025),
                  lastDate: DateTime(2030),
                  builder: (ctx, child) =>
                      Theme(data: _temaOscuro(ctx), child: child!),
                );
                if (picked != null) controller.seleccionarFecha(picked);
              },
            ),
            const SizedBox(height: 28),

            _EncabezadoSeccion(
              titulo: 'Lecturas del día',
              cantidad: registros.length,
            ),
            if (registros.isNotEmpty)
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 6, 4, 0),
                child: Row(
                  children: [
                    Icon(
                      Icons.touch_app_outlined,
                      size: 14,
                      color: _P.textoSecundario,
                    ),
                    SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        'Toca una lectura para editarla o eliminarla',
                        style: TextStyle(
                          fontSize: 12,
                          color: _P.textoSecundario,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 14),

            if (registros.isEmpty)
              const _EstadoVacio()
            else
              for (var i = 0; i < lista.length; i++) ...[
                _Aparece(
                  key: ValueKey(
                    '${lista[i].id}-${controller.fechaSeleccionadaISO}',
                  ),
                  indice: i,
                  child: _TarjetaLectura(
                    lectura: _Lectura(
                      equipo: lista[i].equipoId,
                      inicial: lista[i].horometroInicial,
                      finalH: lista[i].horometroFinal,
                      horas: lista[i].horasOperadas,
                      observaciones: lista[i].observaciones,
                    ),
                    fraccion: maxHoras > 0
                        ? (lista[i].horasOperadas / maxHoras).clamp(0.0, 1.0)
                        : 0.0,
                    onTap: () => _mostrarOpciones(context, lista[i]),
                  ),
                ),
                const SizedBox(height: 12),
              ],
          ],
        ),
      ),
    );
  }

  // ───────── Editar / eliminar ─────────

  List<double?> _vecinos(RegistroHorometro r) {
    final lista = controller.registros
        .where((x) => x.equipoId == r.equipoId)
        .toList();
    final i = lista.indexWhere((x) => x.id == r.id);
    final anterior = i > 0 ? lista[i - 1].horometroFinal : null;
    final siguiente = (i != -1 && i < lista.length - 1)
        ? lista[i + 1].horometroFinal
        : null;
    return [anterior, siguiente];
  }

  void _mostrarOpciones(BuildContext context, RegistroHorometro r) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      constraints: const BoxConstraints(maxWidth: kAnchoMaximoContenido),
      backgroundColor: _P.superficie,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
        side: BorderSide(color: _P.borde),
      ),
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _P.superficieAlta,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: _P.borde),
                  ),
                  child: Row(
                    children: [
                      _Avatar(codigo: r.equipoId, lado: 52),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.equipoId,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: _P.textoPrimario,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Horómetro final ${_num(r.horometroFinal)} h',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                color: _P.textoSecundario,
                                fontFeatures: _cifras,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _OpcionHoja(
                  icono: Icons.edit_outlined,
                  color: _P.amberOscuro,
                  titulo: 'Editar lectura',
                  detalle: 'Corrige el horómetro u observación',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _abrirEdicion(context, r);
                  },
                ),
                const SizedBox(height: 10),
                _OpcionHoja(
                  icono: Icons.delete_outline,
                  color: _P.rojoError,
                  titulo: 'Eliminar lectura',
                  detalle: 'Se recalculan las horas del siguiente registro',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _confirmarEliminar(context, r);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmarEliminar(
    BuildContext context,
    RegistroHorometro r,
  ) async {
    final messenger = ScaffoldMessenger.of(context);

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _P.superficie,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: _P.borde),
        ),
        icon: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: _P.rojoError.withOpacity(0.14),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Icon(Icons.delete_outline, color: _P.rojoError),
        ),
        title: const Text(
          '¿Eliminar esta lectura?',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: _P.textoPrimario,
          ),
        ),
        content: SingleChildScrollView(
          child: Text(
            'Se borrará la lectura de ${r.equipoId} '
            '(${_num(r.horometroFinal)} h). Las horas del registro siguiente '
            'de este equipo se recalcularán. Esta acción no se puede deshacer.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              height: 1.4,
              color: _P.textoSecundario,
            ),
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: _P.textoSecundario),
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _P.rojoError,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Eliminar',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await controller.eliminarRegistro(r.id);
      messenger.showSnackBar(
        const SnackBar(content: Text('Lectura eliminada')),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo eliminar. Revisa tu conexión e inténtalo de nuevo.',
          ),
        ),
      );
    }
  }

  Future<void> _abrirEdicion(BuildContext context, RegistroHorometro r) async {
    final messenger = ScaffoldMessenger.of(context);
    final vecinos = _vecinos(r);

    final guardado = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      constraints: const BoxConstraints(maxWidth: kAnchoMaximoContenido),
      backgroundColor: _P.superficie,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
        side: BorderSide(color: _P.borde),
      ),
      builder: (_) => _EditarLecturaSheet(
        equipo: r.equipoId,
        horometroActual: r.horometroFinal,
        observacionActual: r.observaciones == 'SIN OBSERVACIÓN'
            ? ''
            : r.observaciones,
        anterior: vecinos[0],
        siguiente: vecinos[1],
        onGuardar: (h, obs) => controller.actualizarRegistro(
          id: r.id,
          horometro: h,
          observacion: obs,
        ),
      ),
    );

    if (guardado == true) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Lectura actualizada')),
      );
    }
  }
}

// ═══════════════════════════════════════════════════════════
//  Utilidades
// ═══════════════════════════════════════════════════════════

const _dias = [
  'Lunes',
  'Martes',
  'Miércoles',
  'Jueves',
  'Viernes',
  'Sábado',
  'Domingo',
];
const _diasCortos = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
const _meses = [
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'septiembre',
  'octubre',
  'noviembre',
  'diciembre',
];

const _cifras = [FontFeature.tabularFigures()];

/// Colores del reparto de horas por equipo.
const _paleta = <Color>[
  Color(0xFFFFB300),
  Color(0xFFFF8A3D),
  Color(0xFF4FC3F7),
  Color(0xFF3DDC97),
  Color(0xFFB388FF),
];

bool _mismoDia(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _clave(DateTime d) => '${d.year}-${d.month}-${d.day}';

/// 12345.6 → "12,345.6"
String _num(double v, {int decimales = 1}) {
  final partes = v.toStringAsFixed(decimales).split('.');
  final entero = partes[0].replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  return decimales > 0 ? '$entero.${partes[1]}' : entero;
}

IconData _iconoEquipo(String codigo) {
  final c = codigo.toUpperCase();
  if (c.contains('TI')) return Icons.wb_incandescent_outlined;
  if (c.contains('GE')) return Icons.bolt_outlined;
  return Icons.precision_manufacturing_outlined;
}

/// Franja diagonal ámbar/negro de señalización de precaución.
class _FranjaPrecaucion extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = _P.amber);
    final negro = Paint()..color = _P.tinta;
    const ancho = 10.0;
    for (
      double x = -size.height;
      x < size.width + size.height;
      x += ancho * 2
    ) {
      final p = Path()
        ..moveTo(x, size.height)
        ..lineTo(x + ancho, size.height)
        ..lineTo(x + ancho + size.height, 0)
        ..lineTo(x + size.height, 0)
        ..close();
      canvas.drawPath(p, negro);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Entrada suave de cada tarjeta (fade + desplazamiento escalonado).
class _Aparece extends StatelessWidget {
  final int indice;
  final Widget child;

  const _Aparece({super.key, required this.indice, required this.child});

  @override
  Widget build(BuildContext context) {
    final retraso = (indice * 50).clamp(0, 400);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 350 + retraso),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, 16 * (1 - t)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  Cabecera
// ═══════════════════════════════════════════════════════════

class _Cabecera extends StatelessWidget {
  final DateTime fecha;
  final bool esHoy;
  final double totalHoras;
  final int lecturas;
  final double promedio;
  final int equipos;
  final Map<String, double> porEquipo;
  final Set<String> diasConDatos;
  final ValueChanged<DateTime> onElegirDia;
  final ValueChanged<int> onSemana;
  final VoidCallback onHoy;
  final VoidCallback onCalendario;

  const _Cabecera({
    required this.fecha,
    required this.esHoy,
    required this.totalHoras,
    required this.lecturas,
    required this.promedio,
    required this.equipos,
    required this.porEquipo,
    required this.diasConDatos,
    required this.onElegirDia,
    required this.onSemana,
    required this.onHoy,
    required this.onCalendario,
  });

  @override
  Widget build(BuildContext context) {
    final angosto = esPantallaAngosta(context);
    final pad = angosto ? 16.0 : 20.0;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _P.heroOscuro),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_P.heroClaro, _P.heroMedio, _P.heroOscuro],
          stops: [0.0, 0.5, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: _P.heroOscuro.withOpacity(0.28),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Resplandor ámbar
          Positioned(
            right: -70,
            top: -50,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _P.amber.withOpacity(0.20),
                    _P.amber.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          // Franja de precaución superior
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: 6,
            child: CustomPaint(painter: _FranjaPrecaucion()),
          ),

          Padding(
            padding: EdgeInsets.fromLTRB(pad, 24, pad, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _P.amber.withOpacity(0.16),
                              borderRadius: BorderRadius.circular(3),
                              border: Border.all(
                                color: _P.amber.withOpacity(0.45),
                              ),
                            ),
                            child: Text(
                              esHoy
                                  ? 'HOY · ${_dias[fecha.weekday - 1].toUpperCase()}'
                                  : _dias[fecha.weekday - 1].toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.3,
                                color: _P.amber,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '${fecha.day} de ${_meses[fecha.month - 1]} de ${fecha.year}',
                              maxLines: 1,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!esHoy)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor: _P.tinta,
                            backgroundColor: _P.amber,
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          onPressed: onHoy,
                          icon: const Icon(Icons.today, size: 15),
                          label: const Text(
                            'Hoy',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    IconButton(
                      tooltip: 'Elegir fecha',
                      onPressed: onCalendario,
                      style: IconButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                          side: const BorderSide(color: Colors.white24),
                        ),
                        backgroundColor: Colors.white.withOpacity(0.08),
                        foregroundColor: _P.amber,
                      ),
                      icon: const Icon(Icons.calendar_month_outlined, size: 22),
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      TweenAnimationBuilder<double>(
                        key: ValueKey(totalHoras),
                        tween: Tween(begin: 0, end: totalHoras),
                        duration: const Duration(milliseconds: 700),
                        curve: Curves.easeOutCubic,
                        builder: (_, v, __) => Text(
                          _num(v),
                          style: const TextStyle(
                            fontSize: 64,
                            height: 1.0,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -3,
                            color: Colors.white,
                            fontFeatures: _cifras,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'h',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: _P.amber,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'horas operadas en el día',
                  style: TextStyle(fontSize: 13, color: Colors.white60),
                ),

                if (porEquipo.isNotEmpty && totalHoras > 0) ...[
                  const SizedBox(height: 16),
                  _RepartoHoras(porEquipo: porEquipo),
                ],
                const SizedBox(height: 18),

                Row(
                  children: [
                    Expanded(
                      child: _Kpi(
                        icono: Icons.receipt_long_outlined,
                        valor: '$lecturas',
                        etiqueta: 'Lecturas',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _Kpi(
                        icono: Icons.precision_manufacturing_outlined,
                        valor: '$equipos',
                        etiqueta: 'Equipos',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _Kpi(
                        icono: Icons.timelapse,
                        valor: '${_num(promedio)} h',
                        etiqueta: 'Promedio',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                _FranjaSemana(
                  seleccionada: fecha,
                  diasConDatos: diasConDatos,
                  onElegir: onElegirDia,
                  onSemana: onSemana,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RepartoHoras extends StatelessWidget {
  final Map<String, double> porEquipo;

  const _RepartoHoras({required this.porEquipo});

  @override
  Widget build(BuildContext context) {
    final entradas = porEquipo.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (entradas.isEmpty) return const SizedBox.shrink();

    Color color(int i) => _paleta[i % _paleta.length];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: SizedBox(
            height: 8,
            child: Row(
              children: [
                for (var i = 0; i < entradas.length; i++) ...[
                  if (i > 0) const SizedBox(width: 2),
                  Expanded(
                    flex: (entradas[i].value * 100).round().clamp(1, 1000000),
                    child: Container(color: color(i)),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: [
            for (var i = 0; i < entradas.length && i < 4; i++)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(color: color(i)),
                  ),
                  const SizedBox(width: 5),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 110),
                    child: Text(
                      entradas[i].key,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ],
              ),
            if (entradas.length > 4)
              Text(
                '+${entradas.length - 4} más',
                style: const TextStyle(fontSize: 11, color: Colors.white54),
              ),
          ],
        ),
      ],
    );
  }
}

class _Kpi extends StatelessWidget {
  final IconData icono;
  final String valor;
  final String etiqueta;

  const _Kpi({
    required this.icono,
    required this.valor,
    required this.etiqueta,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.28),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 16, color: _P.amber),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              valor,
              maxLines: 1,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                fontFeatures: _cifras,
              ),
            ),
          ),
          const SizedBox(height: 1),
          Text(
            etiqueta,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: Colors.white60),
          ),
        ],
      ),
    );
  }
}

class _FranjaSemana extends StatelessWidget {
  final DateTime seleccionada;
  final Set<String> diasConDatos;
  final ValueChanged<DateTime> onElegir;
  final ValueChanged<int> onSemana;

  const _FranjaSemana({
    required this.seleccionada,
    required this.diasConDatos,
    required this.onElegir,
    required this.onSemana,
  });

  @override
  Widget build(BuildContext context) {
    final lunes = seleccionada.subtract(
      Duration(days: seleccionada.weekday - 1),
    );
    final semana = List.generate(
      7,
      (i) => DateTime(lunes.year, lunes.month, lunes.day + i),
    );
    final hoy = DateTime.now();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.32),
        borderRadius: BorderRadius.circular(4),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final anchoFlecha = constraints.maxWidth < 320 ? 22.0 : 28.0;
          final anchoCelda = (constraints.maxWidth - anchoFlecha * 2) / 7;
          final ancho = (anchoCelda - 4).clamp(28.0, 40.0);

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragEnd: (d) {
              final v = d.primaryVelocity ?? 0;
              if (v > 250) onSemana(-1);
              if (v < -250) onSemana(1);
            },
            child: Row(
              children: [
                _FlechaSemana(
                  ancho: anchoFlecha,
                  icono: Icons.chevron_left,
                  tooltip: 'Semana anterior',
                  onTap: () => onSemana(-1),
                ),
                for (final dia in semana)
                  Expanded(
                    child: _CeldaDia(
                      dia: dia,
                      ancho: ancho,
                      seleccionado: _mismoDia(dia, seleccionada),
                      esHoy: _mismoDia(dia, hoy),
                      tieneDatos: diasConDatos.contains(_clave(dia)),
                      onTap: () => onElegir(dia),
                    ),
                  ),
                _FlechaSemana(
                  ancho: anchoFlecha,
                  icono: Icons.chevron_right,
                  tooltip: 'Semana siguiente',
                  onTap: () => onSemana(1),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FlechaSemana extends StatelessWidget {
  final double ancho;
  final IconData icono;
  final String tooltip;
  final VoidCallback onTap;

  const _FlechaSemana({
    required this.ancho,
    required this.icono,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: ancho,
      child: IconButton(
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        onPressed: onTap,
        icon: Icon(icono, size: 22, color: Colors.white54),
      ),
    );
  }
}

class _CeldaDia extends StatelessWidget {
  final DateTime dia;
  final double ancho;
  final bool seleccionado;
  final bool esHoy;
  final bool tieneDatos;
  final VoidCallback onTap;

  const _CeldaDia({
    required this.dia,
    required this.ancho,
    required this.seleccionado,
    required this.esHoy,
    required this.tieneDatos,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(4),
      onTap: onTap,
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          width: ancho,
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: seleccionado ? _P.amber : Colors.transparent,
            border: !seleccionado && esHoy
                ? Border.all(color: _P.amber.withOpacity(0.55), width: 1.2)
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _diasCortos[dia.weekday - 1],
                maxLines: 1,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: seleccionado
                      ? _P.tinta.withOpacity(0.75)
                      : Colors.white54,
                ),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '${dia.day}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: seleccionado
                        ? FontWeight.w800
                        : FontWeight.w600,
                    color: seleccionado ? _P.tinta : Colors.white,
                    fontFeatures: _cifras,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: tieneDatos
                      ? (seleccionado ? _P.tinta : _P.amber)
                      : Colors.transparent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  Lecturas
// ═══════════════════════════════════════════════════════════

class _EncabezadoSeccion extends StatelessWidget {
  final String titulo;
  final int cantidad;

  const _EncabezadoSeccion({required this.titulo, required this.cantidad});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Container(
            width: 5,
            height: 22,
            decoration: BoxDecoration(
              color: _P.amber,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              titulo,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: _P.textoPrimario,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: _P.superficieSeleccionada,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: _P.borde),
            ),
            child: Text(
              '$cantidad ${cantidad == 1 ? 'registro' : 'registros'}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _P.amberOscuro,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Lectura {
  final String equipo;
  final double inicial;
  final double finalH;
  final double horas;
  final String observaciones;

  const _Lectura({
    required this.equipo,
    required this.inicial,
    required this.finalH,
    required this.horas,
    required this.observaciones,
  });

  bool get esAlta => observaciones.toUpperCase().contains('ALTA INICIAL');

  bool get tieneNota =>
      !esAlta && observaciones.isNotEmpty && observaciones != 'SIN OBSERVACIÓN';
}

class _Avatar extends StatelessWidget {
  final String codigo;
  final double lado;

  const _Avatar({required this.codigo, this.lado = 48});

  @override
  Widget build(BuildContext context) {
    final c = _acento(codigo);
    return Container(
      width: lado,
      height: lado,
      decoration: BoxDecoration(
        color: c.withOpacity(0.14),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: c.withOpacity(0.45)),
      ),
      child: Icon(_iconoEquipo(codigo), size: lado * 0.48, color: c),
    );
  }
}

class _TarjetaLectura extends StatelessWidget {
  final _Lectura lectura;
  final double fraccion;
  final VoidCallback onTap;

  const _TarjetaLectura({
    required this.lectura,
    required this.fraccion,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l = lectura;
    final acento = _acento(l.equipo);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF14191E).withOpacity(0.07),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: _P.superficie,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: _P.borde),
        ),
        child: InkWell(
          onTap: onTap,
          child: Stack(
            children: [
              // Barra lateral con el color del tipo de equipo
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 4,
                child: ColoredBox(color: acento),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _Avatar(codigo: l.equipo),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l.equipo,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: _P.textoPrimario,
                                ),
                              ),
                              const SizedBox(height: 5),
                              if (l.esAlta)
                                Text(
                                  'Horómetro inicial ${_num(l.finalH)} h',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: _P.textoSecundario,
                                    fontFeatures: _cifras,
                                  ),
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _P.superficieAlta,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.speed_outlined,
                                        size: 13,
                                        color: _P.textoSecundario,
                                      ),
                                      const SizedBox(width: 5),
                                      Flexible(
                                        child: Text.rich(
                                          TextSpan(
                                            children: [
                                              TextSpan(text: _num(l.inicial)),
                                              const TextSpan(text: '  →  '),
                                              TextSpan(
                                                text: _num(l.finalH),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  color: _P.textoPrimario,
                                                ),
                                              ),
                                            ],
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 12.5,
                                            color: _P.textoSecundario,
                                            fontFeatures: _cifras,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),

                        if (l.esAlta)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _P.amber.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: _P.amber.withOpacity(0.4),
                              ),
                            ),
                            child: const Text(
                              'Alta',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: _P.amberOscuro,
                              ),
                            ),
                          )
                        else
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 88),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: _P.verdeOperativo.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: _P.verdeOperativo.withOpacity(0.35),
                                ),
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Column(
                                  children: [
                                    Text(
                                      '+${_num(l.horas)}',
                                      maxLines: 1,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        height: 1.1,
                                        fontWeight: FontWeight.w800,
                                        color: _P.verdeOperativo,
                                        fontFeatures: _cifras,
                                      ),
                                    ),
                                    const Text(
                                      'horas',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w600,
                                        color: _P.verdeOperativo,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),

                    if (!l.esAlta) ...[
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: fraccion),
                          duration: const Duration(milliseconds: 700),
                          curve: Curves.easeOutCubic,
                          builder: (_, v, __) => LinearProgressIndicator(
                            value: v,
                            minHeight: 5,
                            backgroundColor: _P.superficieAlta,
                            valueColor: AlwaysStoppedAnimation(acento),
                          ),
                        ),
                      ),
                    ],

                    if (l.tieneNota) ...[
                      const SizedBox(height: 10),
                      // Nota: Border con un solo lado + borderRadius provoca
                      // error en Flutter, por eso se usa una barra aparte.
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(width: 3, color: _P.amber),
                              Expanded(
                                child: Container(
                                  color: _P.amber.withOpacity(0.09),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Padding(
                                        padding: EdgeInsets.only(top: 1),
                                        child: Icon(
                                          Icons.notes,
                                          size: 13,
                                          color: _P.amber,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          l.observaciones,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            height: 1.3,
                                            color: _P.textoSecundario,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OpcionHoja extends StatelessWidget {
  final IconData icono;
  final Color color;
  final String titulo;
  final String detalle;
  final VoidCallback onTap;

  const _OpcionHoja({
    required this.icono,
    required this.color,
    required this.titulo,
    required this.detalle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: BorderSide(color: color.withOpacity(0.3)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(icono, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      detalle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: _P.textoSecundario,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: color.withOpacity(0.7)),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  Estado vacío
// ═══════════════════════════════════════════════════════════

class _EstadoVacio extends StatelessWidget {
  const _EstadoVacio();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: _P.superficie,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _P.borde),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 108,
                height: 108,
                decoration: BoxDecoration(
                  color: _P.amber.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Container(
                width: 82,
                height: 82,
                decoration: BoxDecoration(
                  color: _P.superficieAlta,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: _P.borde, width: 1.5),
                ),
                child: const Icon(
                  Icons.event_busy_outlined,
                  size: 34,
                  color: _P.amberOscuro,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'Sin lecturas este día',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: _P.textoPrimario,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Ningún equipo registró horómetro en esta fecha.\n'
            'Elige otro día en la semana de arriba.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: _P.textoSecundario,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  Hoja para editar una lectura
// ═══════════════════════════════════════════════════════════

class _EditarLecturaSheet extends StatefulWidget {
  final String equipo;
  final double horometroActual;
  final String observacionActual;
  final double? anterior;
  final double? siguiente;
  final Future<void> Function(double horometro, String observacion) onGuardar;

  const _EditarLecturaSheet({
    required this.equipo,
    required this.horometroActual,
    required this.observacionActual,
    required this.anterior,
    required this.siguiente,
    required this.onGuardar,
  });

  @override
  State<_EditarLecturaSheet> createState() => _EditarLecturaSheetState();
}

class _EditarLecturaSheetState extends State<_EditarLecturaSheet> {
  late final TextEditingController _hController;
  late final TextEditingController _obsController;
  String? _error;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _hController = TextEditingController(
      text: widget.horometroActual.toStringAsFixed(1),
    );
    _obsController = TextEditingController(text: widget.observacionActual);
  }

  @override
  void dispose() {
    _hController.dispose();
    _obsController.dispose();
    super.dispose();
  }

  String? _validar(double? h) {
    if (h == null) return 'Ingresa un horómetro válido.';
    final ant = widget.anterior;
    final sig = widget.siguiente;
    if (ant != null && h <= ant) {
      return 'Debe ser mayor a ${ant.toStringAsFixed(1)}, la lectura anterior.';
    }
    if (sig != null && h >= sig) {
      return 'Debe ser menor a ${sig.toStringAsFixed(1)}, la lectura siguiente.';
    }
    return null;
  }

  Future<void> _guardar() async {
    if (_guardando) return;
    final h = double.tryParse(_hController.text.replaceAll(',', '.'));
    final error = _validar(h);
    if (error != null) {
      setState(() => _error = error);
      return;
    }

    setState(() {
      _error = null;
      _guardando = true;
    });

    try {
      await widget.onGuardar(h!, _obsController.text.trim());
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _guardando = false;
          _error =
              'No se pudo guardar. Revisa tu conexión e inténtalo de nuevo.';
        });
      }
    }
  }

  InputDecoration _decoracion({
    required String etiqueta,
    IconData? icono,
    String? sufijo,
    String? ayuda,
    String? error,
  }) {
    OutlineInputBorder borde(Color c, [double w = 1]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: BorderSide(color: c, width: w),
    );

    return InputDecoration(
      labelText: etiqueta,
      labelStyle: const TextStyle(color: _P.textoSecundario),
      floatingLabelStyle: const TextStyle(color: _P.amberOscuro),
      helperStyle: const TextStyle(color: _P.textoSecundario),
      suffixStyle: const TextStyle(
        color: _P.amberOscuro,
        fontWeight: FontWeight.w800,
      ),
      prefixIcon: icono != null
          ? Icon(icono, size: 20, color: _P.textoSecundario)
          : null,
      suffixText: sufijo,
      helperText: ayuda,
      errorText: error,
      errorMaxLines: 3,
      filled: true,
      fillColor: _P.superficieAlta,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      border: borde(_P.borde),
      enabledBorder: borde(_P.borde),
      focusedBorder: borde(_P.amber, 1.8),
      errorBorder: borde(_P.rojoError),
      focusedErrorBorder: borde(_P.rojoError, 1.8),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final abrirTeclado = mq.size.height >= 600;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        16 + mq.viewInsets.bottom + mq.padding.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _Avatar(codigo: widget.equipo, lado: 48),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Editar lectura',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: _P.textoPrimario,
                        ),
                      ),
                      Text(
                        widget.equipo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: _P.amberOscuro,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _hController,
              enabled: !_guardando,
              autofocus: abrirTeclado,
              cursorColor: _P.amber,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.next,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: _P.textoPrimario,
              ),
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
              decoration: _decoracion(
                etiqueta: 'Horómetro final',
                icono: Icons.speed_outlined,
                sufijo: 'h',
                ayuda: widget.anterior != null
                    ? 'Lectura anterior: ${_num(widget.anterior!)} h'
                    : null,
                error: _error,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _obsController,
              enabled: !_guardando,
              minLines: 2,
              maxLines: 3,
              cursorColor: _P.amber,
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(color: _P.textoPrimario),
              decoration: _decoracion(
                etiqueta: 'Observaciones (opcional)',
                icono: Icons.notes,
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _P.textoPrimario,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: _P.borde),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    onPressed: _guardando ? null : () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: _P.amber,
                      foregroundColor: _P.tinta,
                      disabledBackgroundColor: _P.amber.withOpacity(0.4),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    onPressed: _guardando ? null : _guardar,
                    child: _guardando
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: _P.tinta,
                            ),
                          )
                        : const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Guardar cambios',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
