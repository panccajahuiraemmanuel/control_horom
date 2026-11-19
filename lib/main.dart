import 'package:flutter/material.dart';
import 'ui/home_shell.dart';

void main() {
  runApp(const MinaHorometrosApp());
}

class MinaHorometrosApp extends StatelessWidget {
  const MinaHorometrosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Control de Horómetros',
      debugShowCheckedModeBanner: false,
      // Limita la escala de fuente del sistema y agrega la marca de agua global
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(
            textScaler: mq.textScaler.clamp(
              minScaleFactor: 0.9,
              maxScaleFactor: 1.2,
            ),
          ),
          // La marca de agua va en una franja propia debajo de la app,
          // así nunca se superpone con el contenido.
          child: Column(
            children: [
              Expanded(
                // La app ya no necesita el margen inferior del sistema,
                // porque lo absorbe la franja de abajo.
                child: MediaQuery.removePadding(
                  context: context,
                  removeBottom: true,
                  child: child ?? const SizedBox.shrink(),
                ),
              ),
              const _MarcaDeAgua(),
            ],
          ),
        );
      },
      home: const HomeShell(),
    );
  }
}

/// Franja fina al pie de la pantalla con el crédito del desarrollador.
class _MarcaDeAgua extends StatelessWidget {
  const _MarcaDeAgua();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: SizedBox(
            width: double.infinity,
            child: Text(
              'Desarrollado por David · Ing. de Sistemas',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.6,
                color: Colors.blueGrey.shade400,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
