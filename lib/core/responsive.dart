import 'package:flutter/material.dart';

/// Ancho máximo del contenido. En celulares normales no tiene efecto;
/// en horizontal, tablets y plegables evita que todo se estire.
const double kAnchoMaximoContenido = 600;

/// Por debajo de este ancho (en dp) se usan diseños compactos.
const double kAnchoAngosto = 360;

bool esPantallaAngosta(BuildContext context) =>
    MediaQuery.sizeOf(context).width < kAnchoAngosto;

/// Centra el contenido y limita su ancho.
class ContenidoCentrado extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ContenidoCentrado({
    super.key,
    required this.child,
    this.maxWidth = kAnchoMaximoContenido,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
