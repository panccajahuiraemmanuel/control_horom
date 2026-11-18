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
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppTheme.verdeOperativo,
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
            backgroundColor: AppTheme.azulCorporativo,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.amberMinero,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'MINA-OPS',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Control de Horómetros',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                onPressed: _controller.cargando ? null : _controller.cargarDesdeBanaHosting,
                icon: _controller.cargando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.sync, color: Colors.white),
                tooltip: 'Sincronizar con BanaHosting',
              ),
            ],
          ),
          body: Column(
            children: [
              if (_controller.errorConexion != null)
                Container(
                  width: double.infinity,
                  color: const Color(0xFFFEE2E2),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.cloud_off, size: 18, color: Colors.redAccent),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Verifica tu URL/credenciales en api_service.dart: ${_controller.errorConexion}',
                          style: const TextStyle(fontSize: 11, color: Colors.redAccent, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: _construirPantalla(_controller.indicePantalla),
                ),
              ),
            ],
          ),
          floatingActionButton: _controller.indicePantalla == 0
              ? FloatingActionButton.extended(
                  onPressed: _controller.abrirCapturaHorometro,
                  backgroundColor: AppTheme.amberMinero,
                  foregroundColor: Colors.white,
                  elevation: 3,
                  icon: const Icon(Icons.add),
                  label: const Text(
                    'Registrar Horómetro',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                )
              : null,
          bottomNavigationBar: NavigationBar(
            backgroundColor: Colors.white,
            elevation: 8,
            indicatorColor: const Color(0xFFDBEAFE),
            selectedIndex: _controller.indicePantalla,
            onDestinationSelected: _controller.cambiarPestana,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard, color: AppTheme.azulCorporativo),
                label: 'Dashboard',
              ),
              NavigationDestination(
                icon: Icon(Icons.add_circle_outline),
                selectedIcon: Icon(Icons.add_circle, color: AppTheme.azulCorporativo),
                label: '+ Horómetro',
              ),
              NavigationDestination(
                icon: Icon(Icons.precision_manufacturing_outlined),
                selectedIcon: Icon(Icons.precision_manufacturing, color: AppTheme.azulCorporativo),
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
