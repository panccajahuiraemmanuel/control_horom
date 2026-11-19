import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../core/responsive.dart';
import '../../models/equipo.dart';
import '../../models/registro_horometro.dart';
import '../../state/mina_controller.dart';

/// Paleta clara fija para esta pantalla (no depende del tema de la app,
/// así los textos siempre se leen bien).
class _Paleta {
  static const Color tarjeta = Color(0xFFFFFFFF); // fondo del formulario
  static const Color campo = Color(0xFFF1F5F9); // fondo de los campos
  static const Color borde = Color(0xFFCBD5E1);
  static const Color texto = Color(0xFF0F172A); // texto principal
  static const Color textoSuave = Color(0xFF475569); // texto secundario
  static const Color azul = Color(0xFF1E3A8A); // acento azul
  static const Color fichaFondo = Color(0xFFE6F0FF); // ficha superior
  static const Color fichaBorde = Color(0xFFB6CCF0);
  static const Color ambar = Color(0xFFB45309);
}

class RegistroHorometroScreen extends StatefulWidget {
  final MinaController controller;

  const RegistroHorometroScreen({super.key, required this.controller});

  @override
  State<RegistroHorometroScreen> createState() =>
      _RegistroHorometroScreenState();
}

class _RegistroHorometroScreenState extends State<RegistroHorometroScreen> {
  String? equipoIdSeleccionado;
  String turno = 'Día';
  bool _guardando = false;

  /// Fecha con la que se guardará el registro (por defecto, la del controlador).
  late DateTime _fechaRegistro;

  final TextEditingController _hInicialController = TextEditingController();
  final TextEditingController _hFinalController = TextEditingController();
  final TextEditingController _obsController = TextEditingController();

  @override
  void initState() {
    super.initState();

    final parsed =
        DateTime.tryParse(widget.controller.fechaSeleccionadaISO) ??
        DateTime.now();
    _fechaRegistro = DateTime(parsed.year, parsed.month, parsed.day);

    final equipos = widget.controller.equipos;
    if (widget.controller.equipoPreseleccionadoId != null &&
        equipos.any((e) => e.id == widget.controller.equipoPreseleccionadoId)) {
      equipoIdSeleccionado = widget.controller.equipoPreseleccionadoId;
    } else if (equipos.isNotEmpty) {
      equipoIdSeleccionado = equipos.first.id;
    }

    _actualizarHorometroInicial();

    if (widget.controller.horometroFinalTemporal.isNotEmpty) {
      _hFinalController.text = widget.controller.horometroFinalTemporal;
    }
  }

  void _actualizarHorometroInicial() {
    final equipos = widget.controller.equipos;
    if (equipos.isEmpty || equipoIdSeleccionado == null) {
      _hInicialController.text = '0.0';
      return;
    }
    final eq = equipos.firstWhere(
      (e) => e.id == equipoIdSeleccionado,
      orElse: () => equipos.first,
    );
    _hInicialController.text = eq.ultimoHorometro.toStringAsFixed(1);
  }

  @override
  void dispose() {
    _hInicialController.dispose();
    _hFinalController.dispose();
    _obsController.dispose();
    super.dispose();
  }

  // ───────── Fecha ─────────

  bool _mismoDia(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _fijarFecha(DateTime f) {
    setState(() => _fechaRegistro = DateTime(f.year, f.month, f.day));
  }

  Future<void> _elegirFecha() async {
    final hoy = DateTime.now();
    final hoySinHora = DateTime(hoy.year, hoy.month, hoy.day);
    // El límite superior nunca queda por debajo de la fecha actual elegida
    final ultima = _fechaRegistro.isAfter(hoySinHora)
        ? _fechaRegistro
        : hoySinHora;

    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaRegistro,
      firstDate: DateTime(2020),
      lastDate: ultima,
      helpText: 'Fecha del registro',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _Paleta.azul,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: _Paleta.texto,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) _fijarFecha(picked);
  }

  InputDecoration _decoracion({
    required String etiqueta,
    IconData? icono,
    String? hint,
    String? sufijo,
    bool bloqueado = false,
    bool conError = false,
  }) {
    OutlineInputBorder borde(Color color, [double ancho = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: color, width: ancho),
        );

    final colorBorde = conError ? AppTheme.rojoError : _Paleta.borde;

    return InputDecoration(
      labelText: etiqueta,
      hintText: hint,
      suffixText: sufijo,
      labelStyle: const TextStyle(color: _Paleta.textoSuave),
      floatingLabelStyle: TextStyle(
        color: conError ? AppTheme.rojoError : _Paleta.azul,
        fontWeight: FontWeight.w600,
      ),
      hintStyle: const TextStyle(color: _Paleta.textoSuave),
      suffixStyle: const TextStyle(
        color: _Paleta.textoSuave,
        fontWeight: FontWeight.w600,
      ),
      prefixIcon: icono != null
          ? Icon(icono, size: 20, color: _Paleta.textoSuave)
          : null,
      suffixIcon: bloqueado
          ? const Icon(Icons.lock_outline, size: 16, color: _Paleta.textoSuave)
          : null,
      filled: true,
      fillColor: _Paleta.campo,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      border: borde(colorBorde),
      enabledBorder: borde(colorBorde),
      disabledBorder: borde(_Paleta.borde),
      focusedBorder: borde(conError ? AppTheme.rojoError : _Paleta.azul, 1.8),
    );
  }

  Future<void> _guardar({
    required Equipo equipo,
    required double horometroInicial,
    required double horometroFinal,
    required double diferencia,
  }) async {
    if (_guardando) return;
    setState(() => _guardando = true);

    try {
      await widget.controller.guardarRegistroHorometro(
        RegistroHorometro(
          id: 'reg-${DateTime.now().millisecondsSinceEpoch}',
          equipoId: equipo.id,
          fecha: _fechaRegistro, // ← fecha elegida por el usuario
          turno: turno,
          horometroInicial: horometroInicial,
          horometroFinal: horometroFinal,
          horasOperadas: double.parse(diferencia.toStringAsFixed(1)),
          observaciones: _obsController.text.trim(),
        ),
      );
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Widget _chipFecha(String texto, bool seleccionado, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(texto),
      selected: seleccionado,
      showCheckmark: false,
      backgroundColor: _Paleta.campo,
      selectedColor: _Paleta.azul,
      side: BorderSide(color: seleccionado ? _Paleta.azul : _Paleta.borde),
      labelStyle: TextStyle(
        fontWeight: FontWeight.w700,
        color: seleccionado ? Colors.white : _Paleta.texto,
      ),
      onSelected: _guardando ? null : (_) => onTap(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final angosto = esPantallaAngosta(context);
    final equipos = widget.controller.equipos;

    if (equipoIdSeleccionado == null && equipos.isNotEmpty) {
      equipoIdSeleccionado = equipos.first.id;
      _actualizarHorometroInicial();
    }

    final equipoActual = equipos.isNotEmpty
        ? equipos.firstWhere(
            (e) => e.id == equipoIdSeleccionado,
            orElse: () => equipos.first,
          )
        : null;

    final horometroInicial = equipoActual?.ultimoHorometro ?? 0.0;
    final horometroFinal = double.tryParse(
      _hFinalController.text.replaceAll(',', '.'),
    );
    final diferencia =
        (horometroFinal != null && horometroFinal >= horometroInicial)
        ? horometroFinal - horometroInicial
        : 0.0;

    final errorMenor =
        horometroFinal != null && horometroFinal <= horometroInicial;

    final puedeGuardar =
        equipoActual != null &&
        horometroFinal != null &&
        horometroFinal > horometroInicial &&
        !_guardando;

    final hoy = DateTime.now();
    final ayer = hoy.subtract(const Duration(days: 1));

    // Campos de horómetro (se reutilizan en fila o en columna)
    final campoInicial = TextFormField(
      controller: _hInicialController,
      readOnly: true,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        color: _Paleta.textoSuave,
      ),
      decoration: _decoracion(
        etiqueta: 'Horómetro inicial',
        sufijo: 'h',
        bloqueado: true,
      ),
    );

    final campoFinal = TextFormField(
      controller: _hFinalController,
      enabled: !_guardando,
      cursorColor: _Paleta.azul,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 16,
        color: _Paleta.texto,
      ),
      decoration: _decoracion(
        etiqueta: 'Horómetro final',
        sufijo: 'h',
        conError: errorMenor,
      ),
      onChanged: (_) => setState(() {}),
    );

    return ContenidoCentrado(
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          8,
          16,
          32 + MediaQuery.paddingOf(context).bottom,
        ),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          // ───────── Ficha en vivo ─────────
          _FichaLectura(
            codigo: equipoActual?.codigo,
            tipo: equipoActual?.tipo,
            fecha: _fechaCorta(_fechaRegistro),
            horas: diferencia,
            valida: horometroFinal != null && !errorMenor,
            inicial: horometroInicial,
            finalH: horometroFinal,
            compacto: angosto,
          ),
          const SizedBox(height: 16),

          // ───────── Formulario ─────────
          Container(
            padding: EdgeInsets.all(angosto ? 14 : 18),
            decoration: BoxDecoration(
              color: _Paleta.tarjeta,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: _Paleta.borde),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Datos de la lectura',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _Paleta.texto,
                  ),
                ),
                const SizedBox(height: 16),

                // ── Fecha del registro ──
                const Text(
                  'Fecha del registro',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: _Paleta.textoSuave,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _chipFecha(
                      'Hoy',
                      _mismoDia(_fechaRegistro, hoy),
                      () => _fijarFecha(hoy),
                    ),
                    _chipFecha(
                      'Ayer',
                      _mismoDia(_fechaRegistro, ayer),
                      () => _fijarFecha(ayer),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: _guardando ? null : _elegirFecha,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: _Paleta.campo,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _Paleta.borde),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_month,
                          size: 20,
                          color: _Paleta.azul,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _fechaLarga(_fechaRegistro),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: _Paleta.texto,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.edit_calendar_outlined,
                          size: 18,
                          color: _Paleta.textoSuave,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                DropdownButtonFormField<String>(
                  value: equipoActual?.id,
                  isExpanded: true,
                  dropdownColor: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  icon: const Icon(
                    Icons.expand_more,
                    color: _Paleta.textoSuave,
                  ),
                  decoration: _decoracion(
                    etiqueta: 'Equipo',
                    icono: Icons.precision_manufacturing_outlined,
                  ),
                  items: equipos.map((Equipo eq) {
                    return DropdownMenuItem<String>(
                      value: eq.id,
                      child: Text(
                        eq.codigo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: _Paleta.azul,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: _guardando
                      ? null
                      : (String? nuevoId) {
                          if (nuevoId != null) {
                            setState(() {
                              equipoIdSeleccionado = nuevoId;
                              _actualizarHorometroInicial();
                            });
                          }
                        },
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: _Paleta.azul,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                    onPressed: _guardando
                        ? null
                        : () => widget.controller.derivarANuevoEquipo(
                            _hFinalController.text,
                          ),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(
                      angosto
                          ? '¿No está? Agregar equipo'
                          : '¿No está en la lista? Agregar equipo',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<String>(
                    showSelectedIcon: false,
                    style: SegmentedButton.styleFrom(
                      visualDensity: VisualDensity.comfortable,
                      backgroundColor: _Paleta.campo,
                      selectedBackgroundColor: _Paleta.azul,
                      selectedForegroundColor: Colors.white,
                      foregroundColor: _Paleta.textoSuave,
                      side: const BorderSide(color: _Paleta.borde),
                    ),
                    segments: [
                      ButtonSegment(
                        value: 'Día',
                        icon: const Icon(Icons.wb_sunny_outlined, size: 18),
                        label: Text(
                          angosto ? 'Día' : 'Turno día',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      ButtonSegment(
                        value: 'Noche',
                        icon: const Icon(Icons.nightlight_outlined, size: 18),
                        label: Text(
                          angosto ? 'Noche' : 'Turno noche',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    selected: {turno},
                    onSelectionChanged: _guardando
                        ? null
                        : (s) => setState(() => turno = s.first),
                  ),
                ),
                const SizedBox(height: 18),

                // En pantallas angostas los campos se apilan para que
                // el valor no quede cortado.
                if (angosto) ...[
                  campoInicial,
                  const SizedBox(height: 12),
                  campoFinal,
                ] else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: campoInicial),
                      const Padding(
                        padding: EdgeInsets.fromLTRB(8, 16, 8, 0),
                        child: Icon(
                          Icons.arrow_forward,
                          size: 18,
                          color: _Paleta.textoSuave,
                        ),
                      ),
                      Expanded(child: campoFinal),
                    ],
                  ),

                if (errorMenor) ...[
                  const SizedBox(height: 12),
                  _AvisoError(
                    mensaje:
                        'El horómetro final debe ser mayor a ${horometroInicial.toStringAsFixed(1)}.',
                  ),
                ],
                const SizedBox(height: 18),

                TextField(
                  controller: _obsController,
                  enabled: !_guardando,
                  cursorColor: _Paleta.azul,
                  maxLines: 3,
                  minLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                  style: const TextStyle(color: _Paleta.texto),
                  decoration: _decoracion(
                    etiqueta: angosto
                        ? 'Observaciones (opcional)'
                        : 'Observaciones o incidencias (opcional)',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ───────── Acciones ─────────
          Row(
            children: [
              Expanded(
                flex: 1,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _Paleta.texto,
                    side: const BorderSide(color: _Paleta.borde),
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _guardando
                      ? null
                      : () => widget.controller.cancelarCapturaHorometro(),
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Cancelar',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: _Paleta.azul,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFCBD5E1),
                    disabledForegroundColor: const Color(0xFF64748B),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: puedeGuardar
                      ? () => _guardar(
                          equipo: equipoActual,
                          horometroInicial: horometroInicial,
                          horometroFinal: horometroFinal,
                          diferencia: diferencia,
                        )
                      : null,
                  icon: _guardando
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check, size: 20),
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _guardando ? 'Guardando…' : 'Guardar lectura',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  Utilidades
// ═══════════════════════════════════════════════════════════

const _mesesCortos = [
  'ene',
  'feb',
  'mar',
  'abr',
  'may',
  'jun',
  'jul',
  'ago',
  'sep',
  'oct',
  'nov',
  'dic',
];

const _diasSemana = [
  'Lunes',
  'Martes',
  'Miércoles',
  'Jueves',
  'Viernes',
  'Sábado',
  'Domingo',
];

/// 5 mar 2026
String _fechaCorta(DateTime f) =>
    '${f.day} ${_mesesCortos[f.month - 1]} ${f.year}';

/// Jueves, 05/03/2026
String _fechaLarga(DateTime f) =>
    '${_diasSemana[f.weekday - 1]}, '
    '${f.day.toString().padLeft(2, '0')}/'
    '${f.month.toString().padLeft(2, '0')}/${f.year}';

/// 12345.6 → "12,345.6"
String _num(double v) {
  final partes = v.toStringAsFixed(1).split('.');
  final entero = partes[0].replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  return '$entero.${partes[1]}';
}

/// Mismo criterio que usa el controlador para inferir el tipo de equipo.
IconData _iconoPorCodigo(String? codigo) {
  final c = (codigo ?? '').toUpperCase();
  if (c.contains('TI')) return Icons.wb_incandescent_outlined;
  if (c.contains('GE')) return Icons.bolt_outlined;
  return Icons.precision_manufacturing_outlined;
}

// ═══════════════════════════════════════════════════════════
//  Widgets privados
// ═══════════════════════════════════════════════════════════

/// Tarjeta clara que se actualiza mientras escribes el horómetro final.
class _FichaLectura extends StatelessWidget {
  final String? codigo;
  final String? tipo;
  final String fecha;
  final double horas;
  final bool valida;
  final double inicial;
  final double? finalH;
  final bool compacto;

  const _FichaLectura({
    required this.codigo,
    required this.tipo,
    required this.fecha,
    required this.horas,
    required this.valida,
    required this.inicial,
    required this.finalH,
    this.compacto = false,
  });

  @override
  Widget build(BuildContext context) {
    const cifras = [FontFeature.tabularFigures()];
    const apagado = Color(0xFF94A3B8);

    return Container(
      padding: EdgeInsets.fromLTRB(
        compacto ? 16 : 20,
        18,
        compacto ? 16 : 20,
        16,
      ),
      decoration: BoxDecoration(
        color: _Paleta.fichaFondo,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: _Paleta.fichaBorde),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Equipo y fecha
          Row(
            children: [
              Container(
                width: compacto ? 42 : 48,
                height: compacto ? 42 : 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _Paleta.fichaBorde),
                ),
                child: Icon(
                  _iconoPorCodigo(codigo),
                  size: 24,
                  color: _Paleta.azul,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      codigo ?? 'Sin equipos',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: _Paleta.texto,
                      ),
                    ),
                    Text(
                      tipo ?? 'Registra un equipo para empezar',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: _Paleta.ambar,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _Paleta.fichaBorde),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // En pantallas angostas se omite el icono para ganar espacio
                    if (!compacto) ...[
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 13,
                        color: _Paleta.textoSuave,
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      fecha,
                      maxLines: 1,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _Paleta.texto,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Horas del turno (la cifra se reduce sola si no cabe)
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  _num(horas),
                  style: TextStyle(
                    fontSize: 50,
                    height: 1.0,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.5,
                    color: valida ? _Paleta.azul : apagado,
                    fontFeatures: cifras,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'h',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: valida ? _Paleta.ambar : apagado,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'trabajadas en el turno',
            style: TextStyle(fontSize: 13, color: _Paleta.textoSuave),
          ),
          const SizedBox(height: 14),
          Container(height: 1, color: _Paleta.fichaBorde),
          const SizedBox(height: 12),

          // Recorrido del horómetro
          Row(
            children: [
              Expanded(
                child: _Dato(
                  etiqueta: 'Horómetro inicial',
                  valor: _num(inicial),
                ),
              ),
              Container(width: 1, height: 32, color: _Paleta.fichaBorde),
              const SizedBox(width: 16),
              Expanded(
                child: _Dato(
                  etiqueta: 'Horómetro final',
                  valor: finalH != null ? _num(finalH!) : '—',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  final String etiqueta;
  final String valor;

  const _Dato({required this.etiqueta, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          etiqueta,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, color: _Paleta.textoSuave),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            valor,
            maxLines: 1,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: _Paleta.texto,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
}

class _AvisoError extends StatelessWidget {
  final String mensaje;

  const _AvisoError({required this.mensaje});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.rojoError.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.rojoError.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, size: 18, color: AppTheme.rojoError),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              mensaje,
              style: const TextStyle(
                color: AppTheme.rojoError,
                fontSize: 13,
                height: 1.3,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
