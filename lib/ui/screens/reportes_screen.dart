import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/app_theme.dart';
import '../../core/responsive.dart';
import '../../models/registro_horometro.dart';
import '../../state/mina_controller.dart';

/// Paleta clara fija para esta pantalla (no depende del tema de la app,
/// así los textos siempre se leen bien).
class _Paleta {
  static const Color tarjeta = Color(0xFFFFFFFF);
  static const Color campo = Color(0xFFF1F5F9);
  static const Color borde = Color(0xFFCBD5E1);
  static const Color texto = Color(0xFF0F172A);
  static const Color textoSuave = Color(0xFF475569);
  static const Color azul = Color(0xFF1E3A8A);
  static const Color fichaFondo = Color(0xFFE6F0FF);
  static const Color fichaBorde = Color(0xFFB6CCF0);
  static const Color ambar = Color(0xFFB45309);
}

class ReportesScreen extends StatefulWidget {
  final MinaController controller;

  const ReportesScreen({super.key, required this.controller});

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {
  late DateTime _fechaFiltro;
  bool _generando = false;

  @override
  void initState() {
    super.initState();
    final parsed =
        DateTime.tryParse(widget.controller.fechaSeleccionadaISO) ??
        DateTime.now();
    _fechaFiltro = DateTime(parsed.year, parsed.month, parsed.day);
  }

  // ───────── Utilidades ─────────

  String _iso(DateTime f) =>
      '${f.year}-${f.month.toString().padLeft(2, '0')}-${f.day.toString().padLeft(2, '0')}';

  String _visible(DateTime f) =>
      '${f.day.toString().padLeft(2, '0')}/${f.month.toString().padLeft(2, '0')}/${f.year}';

  bool _mismoDia(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _aviso(String mensaje, {Color? color}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensaje), backgroundColor: color));
  }

  // ───────── Exportación ─────────

  Future<void> _exportarExcel({required bool soloFechaIndicada}) async {
    if (_generando) return;
    setState(() => _generando = true);

    try {
      final fechaStr = _iso(_fechaFiltro);

      final List<RegistroHorometro> lista = soloFechaIndicada
          ? widget.controller.registros
                .where((r) => _mismoDia(r.fecha, _fechaFiltro))
                .toList()
          : List.of(widget.controller.registros);

      if (lista.isEmpty) {
        _aviso(
          soloFechaIndicada
              ? 'No hay registros el ${_visible(_fechaFiltro)}.'
              : 'No existen registros para exportar.',
          color: Colors.orange.shade800,
        );
        return;
      }

      // Orden: fecha y luego equipo
      lista.sort((a, b) {
        final c = a.fecha.compareTo(b.fecha);
        return c != 0 ? c : a.equipoId.compareTo(b.equipoId);
      });

      final areaPorEquipo = {
        for (final e in widget.controller.equipos) e.id: e.mina,
      };

      final excel = Excel.createExcel();
      final nombreHoja = soloFechaIndicada
          ? 'Reporte_$fechaStr'
          : 'Historico_Completo';
      excel.rename('Sheet1', nombreHoja);
      final sheet = excel[nombreHoja];

      final estiloCabecera = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#0F172A'),
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      );

      void cabecera(Sheet s, List<String> titulos) {
        s.appendRow(titulos.map((h) => TextCellValue(h)).toList());
        for (var col = 0; col < titulos.length; col++) {
          s
                  .cell(
                    CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0),
                  )
                  .cellStyle =
              estiloCabecera;
        }
      }

      // ── Hoja de detalle ──
      cabecera(sheet, [
        'Fecha',
        'Código Equipo',
        'Área / Zona',
        'H. Inicial',
        'H. Final',
        'Horas Operadas',
        'Observaciones',
      ]);

      const anchos = [12.0, 16.0, 18.0, 12.0, 12.0, 16.0, 40.0];
      for (var i = 0; i < anchos.length; i++) {
        sheet.setColumnWidth(i, anchos[i]);
      }

      double totalHoras = 0;
      for (final reg in lista) {
        totalHoras += reg.horasOperadas;
        sheet.appendRow([
          TextCellValue(_iso(reg.fecha)),
          TextCellValue(reg.equipoId),
          TextCellValue(areaPorEquipo[reg.equipoId] ?? '—'),
          DoubleCellValue(reg.horometroInicial),
          DoubleCellValue(reg.horometroFinal),
          DoubleCellValue(reg.horasOperadas),
          TextCellValue(reg.observaciones),
        ]);
      }

      // ── Hoja de resumen por equipo ──
      final resumen = excel['Resumen'];
      cabecera(resumen, ['Código Equipo', 'Lecturas', 'Horas Operadas']);
      resumen.setColumnWidth(0, 18);
      resumen.setColumnWidth(1, 12);
      resumen.setColumnWidth(2, 18);

      final porEquipo = <String, List<RegistroHorometro>>{};
      for (final r in lista) {
        porEquipo.putIfAbsent(r.equipoId, () => []).add(r);
      }
      final codigos = porEquipo.keys.toList()..sort();
      for (final cod in codigos) {
        final regs = porEquipo[cod]!;
        final horas = regs.fold<double>(0, (s, r) => s + r.horasOperadas);
        resumen.appendRow([
          TextCellValue(cod),
          IntCellValue(regs.length),
          DoubleCellValue(double.parse(horas.toStringAsFixed(1))),
        ]);
      }
      resumen.appendRow([
        TextCellValue('TOTAL'),
        IntCellValue(lista.length),
        DoubleCellValue(double.parse(totalHoras.toStringAsFixed(1))),
      ]);

      final bytes = excel.save();
      if (bytes == null) {
        _aviso('No se pudo generar el archivo.', color: Colors.redAccent);
        return;
      }

      final nombreArchivo = soloFechaIndicada
          ? 'Horometros_$fechaStr.xlsx'
          : 'Horometros_Historico_${_iso(DateTime.now())}.xlsx';

      // ── Manejo seguro adaptable para Web y Móvil (Android) ──
      if (kIsWeb) {
        // Descarga directa optimizada para Navegador Web
        await Share.shareXFiles([
          XFile.fromData(
            Uint8List.fromList(bytes),
            name: nombreArchivo,
            mimeType:
                'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          ),
        ], text: 'Reporte de Horómetros Mineros');
      } else {
        final ruta = await _guardarArchivoMovil(nombreArchivo, bytes);

        if (!mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              backgroundColor: AppTheme.verdeOperativo,
              duration: const Duration(seconds: 6),
              content: Text(
                ruta.enDescargas
                    ? 'Guardado en Descargas:\n$nombreArchivo'
                    : 'Archivo generado:\n$nombreArchivo',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              action: SnackBarAction(
                label: 'Compartir',
                textColor: Colors.white,
                onPressed: () =>
                    Share.shareXFiles([XFile(ruta.path)], text: nombreArchivo),
              ),
            ),
          );
      }
    } catch (e) {
      _aviso('Error al generar el Excel: $e', color: Colors.redAccent);
    } finally {
      if (mounted) setState(() => _generando = false);
    }
  }

  Future<({String path, bool enDescargas})> _guardarArchivoMovil(
    String nombre,
    List<int> bytes,
  ) async {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        final descargas = Directory('/storage/emulated/0/Download');
        if (await descargas.exists()) {
          final f = File('${descargas.path}/$nombre');
          await f.writeAsBytes(bytes, flush: true);
          return (path: f.path, enDescargas: true);
        }
      } catch (_) {}
    }

    final dir = (!kIsWeb && Platform.isAndroid)
        ? (await getExternalStorageDirectory() ??
              await getApplicationDocumentsDirectory())
        : await getApplicationDocumentsDirectory();
    final f = File('${dir.path}/$nombre');
    await f.writeAsBytes(bytes, flush: true);
    return (path: f.path, enDescargas: false);
  }

  Future<void> _elegirFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaFiltro,
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
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
    if (picked != null) {
      setState(
        () => _fechaFiltro = DateTime(picked.year, picked.month, picked.day),
      );
    }
  }

  // ───────── Interfaz ─────────

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
      onSelected: (_) => onTap(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final angosto = esPantallaAngosta(context);
    final registrosDia = widget.controller.registros
        .where((r) => _mismoDia(r.fecha, _fechaFiltro))
        .length;
    final totalRegistros = widget.controller.registros.length;

    final hoy = DateTime.now();
    final ayer = hoy.subtract(const Duration(days: 1));

    return ContenidoCentrado(
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          60 + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          // ───────── Cabecera ─────────
          Container(
            padding: EdgeInsets.all(angosto ? 14 : 18),
            decoration: BoxDecoration(
              color: _Paleta.fichaFondo,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: _Paleta.fichaBorde),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _Paleta.fichaBorde),
                  ),
                  child: const Icon(
                    Icons.table_view_outlined,
                    color: _Paleta.azul,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Exportar reportes Excel',
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: _Paleta.texto,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Hojas de cálculo (.xlsx) con detalle y resumen',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: _Paleta.ambar,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ───────── Opción 1: por fecha ─────────
          _TarjetaOpcion(
            icono: Icons.event,
            titulo: 'Descargar por fecha',
            descripcion:
                'Genera un Excel solo con los horómetros del día elegido.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _chipFecha(
                      'Hoy',
                      _mismoDia(_fechaFiltro, hoy),
                      () => setState(
                        () => _fechaFiltro = DateTime(
                          hoy.year,
                          hoy.month,
                          hoy.day,
                        ),
                      ),
                    ),
                    _chipFecha(
                      'Ayer',
                      _mismoDia(_fechaFiltro, ayer),
                      () => setState(
                        () => _fechaFiltro = DateTime(
                          ayer.year,
                          ayer.month,
                          ayer.day,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _generando ? null : _elegirFecha,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: _Paleta.campo,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _Paleta.borde),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_month,
                          color: _Paleta.azul,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _visible(_fechaFiltro),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: _Paleta.texto,
                          ),
                        ),
                        const Spacer(),
                        Flexible(
                          child: Text(
                            '$registrosDia ${registrosDia == 1 ? 'registro' : 'registros'}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: _Paleta.textoSuave,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: _Paleta.azul,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFFCBD5E1),
                      disabledForegroundColor: const Color(0xFF64748B),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: (_generando || registrosDia == 0)
                        ? null
                        : () => _exportarExcel(soloFechaIndicada: true),
                    icon: _generando
                        ? const _Cargando()
                        : const Icon(Icons.download, size: 20),
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        registrosDia == 0
                            ? 'Sin registros en esta fecha'
                            : 'Descargar fecha seleccionada',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // ───────── Opción 2: histórico ─────────
          _TarjetaOpcion(
            icono: Icons.auto_awesome_motion,
            titulo: 'Descarga histórica',
            descripcion:
                'Exporta todas las lecturas registradas ($totalRegistros en total).',
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: _Paleta.azul,
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: _Paleta.azul),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: (_generando || totalRegistros == 0)
                    ? null
                    : () => _exportarExcel(soloFechaIndicada: false),
                icon: const Icon(Icons.folder_zip_outlined, size: 20),
                label: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Descargar histórico completo',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  Widgets privados
// ═══════════════════════════════════════════════════════════

class _TarjetaOpcion extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String descripcion;
  final Widget child;

  const _TarjetaOpcion({
    required this.icono,
    required this.titulo,
    required this.descripcion,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _Paleta.tarjeta,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _Paleta.borde),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icono, color: _Paleta.azul, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  titulo,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _Paleta.texto,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            descripcion,
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.35,
              color: _Paleta.textoSuave,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _Cargando extends StatelessWidget {
  const _Cargando();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 16,
      height: 16,
      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
    );
  }
}
