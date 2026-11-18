import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../models/equipo.dart';
import '../../models/registro_horometro.dart';
import '../../state/mina_controller.dart';

class RegistroHorometroScreen extends StatefulWidget {
  final MinaController controller;
  final void Function(String mensaje) onNotificar;

  const RegistroHorometroScreen({
    super.key,
    required this.controller,
    required this.onNotificar,
  });

  @override
  State<RegistroHorometroScreen> createState() => _RegistroHorometroScreenState();
}

class _RegistroHorometroScreenState extends State<RegistroHorometroScreen> {
  Equipo? _equipoSeleccionado;
  String _turno = 'Día';
  late final TextEditingController _hFinalCtrl;
  final TextEditingController _obsCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _hFinalCtrl = TextEditingController(text: widget.controller.horometroFinalTemporal);
    final equipos = widget.controller.equipos;
    if (equipos.isNotEmpty) {
      _equipoSeleccionado = equipos.firstWhere(
        (e) => e.id == widget.controller.equipoPreseleccionadoId,
        orElse: () => equipos.first,
      );
    }
  }

  @override
  void dispose() {
    _hFinalCtrl.dispose();
    _obsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hInicial = _equipoSeleccionado?.ultimoHorometro ?? 0.0;
    final hFinal = double.tryParse(_hFinalCtrl.text.replaceAll(',', '.'));
    final diferencia = hFinal != null ? hFinal - hInicial : 0.0;

    final errorMenor = hFinal != null && diferencia <= 0.0;
    final alertaExceso = hFinal != null && diferencia > 24.0;

    return ListView(
      children: [
        const Text(
          'Registrar Lectura de Horómetro',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.amberMinero,
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<Equipo>(
          value: _equipoSeleccionado,
          decoration: const InputDecoration(
            labelText: 'Equipo *',
            border: OutlineInputBorder(),
          ),
          items: widget.controller.equipos.map((eq) {
            return DropdownMenuItem(
              value: eq,
              child: Text('${eq.codigo} - ${eq.tipo} (${eq.mina})'),
            );
          }).toList(),
          onChanged: (nuevo) => setState(() => _equipoSeleccionado = nuevo),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => widget.controller.derivarANuevoEquipo(_hFinalCtrl.text),
            child: const Text(
              '+ ¿No está en la lista? Agregar nuevo equipo no registrado',
              style: TextStyle(color: AppTheme.amberMinero, fontSize: 13),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: ['Día', 'Noche'].map((opcion) {
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: ChoiceChip(
                label: Text('Turno $opcion'),
                selected: _turno == opcion,
                onSelected: (_) => setState(() => _turno = opcion),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                key: ValueKey(hInicial),
                initialValue: hInicial.toStringAsFixed(1),
                enabled: false,
                decoration: const InputDecoration(
                  labelText: 'H. Inicial (Anterior)',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _hFinalCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'H. Final (Actual) *',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Horas trabajadas en el turno:', style: TextStyle(fontSize: 14)),
                Text(
                  '${(hFinal != null ? diferencia : 0.0).toStringAsFixed(1)} h',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: errorMenor ? Colors.redAccent : AppTheme.amberMinero,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (errorMenor)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Error: El horómetro final debe ser mayor al inicial (${hInicial.toStringAsFixed(1)}).',
              style: const TextStyle(color: Colors.redAccent, fontSize: 12),
            ),
          )
        else if (alertaExceso)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Advertencia: Supera 24 horas continuas en un solo turno. Verifica posibles errores tipográficos.',
              style: TextStyle(color: Colors.amberAccent, fontSize: 12),
            ),
          ),
        const SizedBox(height: 14),
        TextField(
          controller: _obsCtrl,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Observaciones / Incidencias',
            hintText: 'Paradas mecánicas, frente de trabajo...',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed: (_equipoSeleccionado != null && hFinal != null && !errorMenor)
                    ? () {
                        widget.controller.guardarRegistroHorometro(
                          RegistroHorometro(
                            id: 'reg-${DateTime.now().millisecondsSinceEpoch}',
                            equipoId: _equipoSeleccionado!.id,
                            fecha: DateTime.now(),
                            turno: _turno,
                            horometroInicial: hInicial,
                            horometroFinal: hFinal,
                            horasOperadas: double.parse(diferencia.toStringAsFixed(1)),
                            observaciones: _obsCtrl.text.trim(),
                          ),
                        );
                        widget.onNotificar('Registro guardado correctamente');
                      }
                    : null,
                child: const Text(
                  'Guardar Registro',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 10),
            OutlinedButton(
              onPressed: widget.controller.cancelarCapturaHorometro,
              child: const Text('Cancelar'),
            ),
          ],
        ),
      ],
    );
  }
}
