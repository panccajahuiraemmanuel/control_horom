import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../core/responsive.dart';
import '../../models/equipo.dart';
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
  static const Color fichaFondo = Color(0xFFE6F0FF); // cabecera superior
  static const Color fichaBorde = Color(0xFFB6CCF0);
  static const Color ambar = Color(0xFFB45309);
}

class RegistroEquipoScreen extends StatefulWidget {
  final MinaController controller;

  const RegistroEquipoScreen({super.key, required this.controller});

  @override
  State<RegistroEquipoScreen> createState() => _RegistroEquipoScreenState();
}

class _RegistroEquipoScreenState extends State<RegistroEquipoScreen> {
  final TextEditingController _codigoController = TextEditingController();
  final TextEditingController _horometroBaseController =
      TextEditingController();
  final TextEditingController _minaController = TextEditingController();

  bool _guardando = false;
  String? _mensajeError;

  @override
  void dispose() {
    _codigoController.dispose();
    _horometroBaseController.dispose();
    _minaController.dispose();
    super.dispose();
  }

  InputDecoration _decoracion({
    required String etiqueta,
    IconData? icono,
    String? hint,
    String? sufijo,
  }) {
    OutlineInputBorder borde(Color color, [double ancho = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: color, width: ancho),
        );

    return InputDecoration(
      labelText: etiqueta,
      hintText: hint,
      suffixText: sufijo,
      labelStyle: const TextStyle(color: _Paleta.textoSuave),
      floatingLabelStyle: const TextStyle(
        color: _Paleta.azul,
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
      filled: true,
      fillColor: _Paleta.campo,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      border: borde(_Paleta.borde),
      enabledBorder: borde(_Paleta.borde),
      disabledBorder: borde(_Paleta.borde),
      focusedBorder: borde(_Paleta.azul, 1.8),
    );
  }

  Future<void> _guardar() async {
    if (_guardando) return;

    final codigo = _codigoController.text.trim().toUpperCase();
    final hBase = double.tryParse(
      _horometroBaseController.text.replaceAll(',', '.'),
    );
    final mina = _minaController.text.trim().toUpperCase();

    if (codigo.isEmpty || hBase == null) {
      setState(() {
        _mensajeError = 'Ingresa el código del equipo y su horómetro inicial.';
      });
      return;
    }

    if (widget.controller.codigoEquipoExiste(codigo)) {
      setState(() {
        _mensajeError = 'El código $codigo ya está registrado.';
      });
      return;
    }

    setState(() {
      _mensajeError = null;
      _guardando = true;
    });

    try {
      await widget.controller.guardarNuevoEquipo(
        Equipo(
          id: codigo,
          codigo: codigo,
          tipo: 'Equipo',
          marca: '',
          modelo: '',
          horometroBase: hBase,
          ultimoHorometro: hBase,
          mina: mina.isEmpty ? 'GENERAL' : mina,
          estado: 'OPERATIVO',
        ),
      );
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final angosto = esPantallaAngosta(context);
    final codigoVista = _codigoController.text.trim().toUpperCase();

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
          // Cabecera clara estilo ficha
          Container(
            padding: EdgeInsets.all(angosto ? 16 : 20),
            decoration: BoxDecoration(
              color: _Paleta.fichaFondo,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: _Paleta.fichaBorde),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _Paleta.fichaBorde),
                  ),
                  child: const Icon(
                    Icons.precision_manufacturing_outlined,
                    color: _Paleta.azul,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        codigoVista.isEmpty ? 'Nuevo Equipo' : codigoVista,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: _Paleta.texto,
                        ),
                      ),
                      const Text(
                        'Alta en catálogo de maquinaria',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: _Paleta.ambar,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Formulario
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
                  'Datos del equipo',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _Paleta.texto,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _codigoController,
                  enabled: !_guardando,
                  cursorColor: _Paleta.azul,
                  textCapitalization: TextCapitalization.characters,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: _Paleta.texto,
                  ),
                  decoration: _decoracion(
                    etiqueta: 'Código (ej. CO-TI-05) *',
                    icono: Icons.qr_code_2_outlined,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _horometroBaseController,
                  enabled: !_guardando,
                  cursorColor: _Paleta.azul,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: _Paleta.texto,
                  ),
                  decoration: _decoracion(
                    etiqueta: 'Horómetro inicial *',
                    icono: Icons.timer_outlined,
                    sufijo: 'h',
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _minaController,
                  enabled: !_guardando,
                  cursorColor: _Paleta.azul,
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(color: _Paleta.texto),
                  decoration: _decoracion(
                    etiqueta: 'Área / Zona (opcional)',
                    icono: Icons.place_outlined,
                  ),
                ),
                if (_mensajeError != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.rojoError.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.rojoError.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      _mensajeError!,
                      style: const TextStyle(
                        color: AppTheme.rojoError,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Botones
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
                      : () => widget.controller.volverDesdeAltaEquipo(),
                  child: const Text(
                    'Volver',
                    style: TextStyle(fontWeight: FontWeight.w600),
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
                  onPressed: _guardando ? null : _guardar,
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
                  label: Text(
                    _guardando ? 'Guardando…' : 'Registrar equipo',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
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
