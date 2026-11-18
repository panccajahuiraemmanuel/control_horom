import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../models/equipo.dart';
import '../../state/mina_controller.dart';

class RegistroEquipoScreen extends StatefulWidget {
  final MinaController controller;
  final void Function(String mensaje) onNotificar;

  const RegistroEquipoScreen({
    super.key,
    required this.controller,
    required this.onNotificar,
  });

  @override
  State<RegistroEquipoScreen> createState() => _RegistroEquipoScreenState();
}

class _RegistroEquipoScreenState extends State<RegistroEquipoScreen> {
  final _codigoCtrl = TextEditingController();
  String _tipo = 'Scooptram';
  final _marcaCtrl = TextEditingController();
  final _modeloCtrl = TextEditingController();
  final _horometroBaseCtrl = TextEditingController();
  final _minaCtrl = TextEditingController();
  String? _mensajeError;

  static const List<String> _tiposMaquinaria = [
    'Scooptram',
    'Jumbo',
    'Volquete / Dumper',
    'Excavadora',
    'Compresora',
    'Generador',
    'Camioneta',
  ];

  @override
  void dispose() {
    _codigoCtrl.dispose();
    _marcaCtrl.dispose();
    _modeloCtrl.dispose();
    _horometroBaseCtrl.dispose();
    _minaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Alta de Nuevo Equipo',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.amberMinero,
              ),
            ),
            if (widget.controller.vieneDeHorometro)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.amberMinero.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Vía Horómetro',
                  style: TextStyle(fontSize: 11, color: AppTheme.amberMinero),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _codigoCtrl,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'Código Interno (ej. SCOOP-02) *',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _tipo,
          decoration: const InputDecoration(
            labelText: 'Tipo de Maquinaria *',
            border: OutlineInputBorder(),
          ),
          items: _tiposMaquinaria
              .map((t) => DropdownMenuItem(value: t, child: Text(t)))
              .toList(),
          onChanged: (val) {
            if (val != null) setState(() => _tipo = val);
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _marcaCtrl,
                decoration: const InputDecoration(
                  labelText: 'Marca',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _modeloCtrl,
                decoration: const InputDecoration(
                  labelText: 'Modelo',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _horometroBaseCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Horómetro Base *',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _minaCtrl,
                decoration: const InputDecoration(
                  labelText: 'Mina / Proyecto *',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        if (_mensajeError != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              _mensajeError!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 12),
            ),
          ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed: _validarYGuardar,
                child: const Text(
                  'Registrar y Continuar',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 10),
            OutlinedButton.icon(
              onPressed: widget.controller.volverDesdeAltaEquipo,
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('Volver'),
            ),
          ],
        ),
      ],
    );
  }

  void _validarYGuardar() {
    final codigo = _codigoCtrl.text.trim().toUpperCase();
    final hBase = double.tryParse(_horometroBaseCtrl.text.replaceAll(',', '.'));
    final mina = _minaCtrl.text.trim();

    if (codigo.isEmpty || hBase == null || mina.isEmpty) {
      setState(() => _mensajeError = 'Completa el código, el horómetro base y la unidad minera.');
      return;
    }

    if (widget.controller.codigoEquipoExiste(codigo)) {
      setState(() => _mensajeError = 'El código $codigo ya existe en la base de datos.');
      return;
    }

    final nuevo = Equipo(
      id: 'eq-${DateTime.now().millisecondsSinceEpoch}',
      codigo: codigo,
      tipo: _tipo,
      marca: _marcaCtrl.text.trim(),
      modelo: _modeloCtrl.text.trim(),
      horometroBase: hBase,
      ultimoHorometro: hBase,
      mina: mina,
    );

    widget.controller.guardarNuevoEquipo(nuevo);
    widget.onNotificar('Equipo $codigo registrado');
  }
}
