import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../state/mina_controller.dart';
import 'screens/dashboard_screen.dart';
import 'screens/registro_equipo_screen.dart';
import 'screens/registro_horometro_screen.dart';
import 'screens/reportes_screen.dart';

/// Paleta minera: grafito + ámbar de seguridad.
class _M {
  static const grafito = Color(0xFF14191E);
  static const fondo = Color(0xFFF3F5F7);
  static const superficie = Color(0xFFFFFFFF);
  static const borde = Color(0xFFDDE3E9);
  static const amber = Color(0xFFFFB300);
  static const amberOscuro = Color(0xFFB36B00);
  static const texto = Color(0xFF14191E);
  static const textoSec = Color(0xFF5F6C78);
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  final MinaController _controller = MinaController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _construirPantalla(int indice) {
    switch (indice) {
      case 0:
        return DashboardScreen(controller: _controller);
      case 1:
        return RegistroHorometroScreen(controller: _controller);
      case 2:
        return RegistroEquipoScreen(controller: _controller);
      case 3:
        return ReportesScreen(controller: _controller);
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: _M.fondo,
          appBar: AppBar(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            systemOverlayStyle: SystemUiOverlayStyle.dark,
            elevation: 0,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(2),
              child: Container(height: 2, color: _M.amber),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _M.amber,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const Text(
                    'MINA-OPS',
                    style: TextStyle(
                      color: _M.grafito,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Control de Horómetros',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _M.texto,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                onPressed: _controller.cargando
                    ? null
                    : _controller.cargarDesdeBanaHosting,
                icon: _controller.cargando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _M.amber,
                        ),
                      )
                    : const Icon(Icons.sync, color: _M.amberOscuro),
                tooltip: 'Sincronizar con BanaHosting',
              ),
            ],
          ),
          body: _controller.cargando
              ? const Center(child: CircularProgressIndicator(color: _M.amber))
              : _construirPantalla(_controller.indicePantalla),
          bottomNavigationBar: DecoratedBox(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: _M.borde)),
            ),
            child: NavigationBarTheme(
              data: NavigationBarThemeData(
                backgroundColor: _M.superficie,
                surfaceTintColor: Colors.transparent,
                indicatorColor: _M.amber.withOpacity(0.18),
                indicatorShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                labelTextStyle: WidgetStateProperty.resolveWith((states) {
                  final sel = states.contains(WidgetState.selected);
                  return TextStyle(
                    fontSize: 12,
                    fontWeight: sel ? FontWeight.w800 : FontWeight.w500,
                    color: sel ? _M.amberOscuro : _M.textoSec,
                  );
                }),
              ),
              child: NavigationBar(
                elevation: 0,
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                selectedIndex: _controller.indicePantalla,
                onDestinationSelected: _controller.cambiarPestana,
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.dashboard_outlined, color: _M.textoSec),
                    selectedIcon: Icon(Icons.dashboard, color: _M.amberOscuro),
                    label: 'Dashboard',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.add_circle_outline, color: _M.textoSec),
                    selectedIcon: Icon(Icons.add_circle, color: _M.amberOscuro),
                    label: '+ Horómetro',
                  ),
                  NavigationDestination(
                    icon: Icon(
                      Icons.precision_manufacturing_outlined,
                      color: _M.textoSec,
                    ),
                    selectedIcon: Icon(
                      Icons.precision_manufacturing,
                      color: _M.amberOscuro,
                    ),
                    label: 'Equipos',
                  ),
                  NavigationDestination(
                    icon: Icon(
                      Icons.file_download_outlined,
                      color: _M.textoSec,
                    ),
                    selectedIcon: Icon(
                      Icons.file_download,
                      color: _M.amberOscuro,
                    ),
                    label: 'Reportes',
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
