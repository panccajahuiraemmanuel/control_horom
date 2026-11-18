import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../state/mina_controller.dart';
import 'screens/dashboard_screen.dart';
import 'screens/registro_equipo_screen.dart';
import 'screens/registro_horometro_screen.dart';

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

  void _mostrarSnack(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          mensaje,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.teal.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: AppTheme.superficie,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.amberMinero,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'MINA-OPS',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Control de Horómetros',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _construirPantalla(_controller.indicePantalla),
          ),
          floatingActionButton: _controller.indicePantalla == 0
              ? FloatingActionButton.extended(
                  onPressed: _controller.abrirCapturaHorometro,
                  backgroundColor: AppTheme.amberMinero,
                  icon: const Icon(Icons.add),
                  label: const Text(
                    'Registrar Horómetro',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                )
              : null,
          bottomNavigationBar: NavigationBar(
            backgroundColor: AppTheme.superficie,
            selectedIndex: _controller.indicePantalla,
            onDestinationSelected: _controller.cambiarPestana,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: 'Dashboard',
              ),
              NavigationDestination(
                icon: Icon(Icons.add_circle_outline),
                selectedIcon: Icon(Icons.add_circle),
                label: '+ Horómetro',
              ),
              NavigationDestination(
                icon: Icon(Icons.precision_manufacturing_outlined),
                selectedIcon: Icon(Icons.precision_manufacturing),
                label: 'Equipos',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _construirPantalla(int indice) {
    switch (indice) {
      case 0:
        return DashboardScreen(controller: _controller);
      case 1:
        return RegistroHorometroScreen(
          controller: _controller,
          onNotificar: _mostrarSnack,
        );
      case 2:
        return RegistroEquipoScreen(
          controller: _controller,
          onNotificar: _mostrarSnack,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
