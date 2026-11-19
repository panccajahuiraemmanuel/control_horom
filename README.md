⚙️ MINA-OPS — Control de HorómetrosAplicación multiplataforma para el registro, monitoreo y reporte de horómetros de equipos en operaciones mineras.📋 DescripciónMINA-OPS es una solución móvil y web diseñada para digitalizar el control diario de horómetros de equipos en campo (como torres de iluminación, generadores y maquinaria auxiliar). Permite a los operadores y supervisores registrar lecturas en tiempo real, calcular horas operadas automáticamente, administrar el inventario de equipos por zona y exportar reportes consolidados en formato Excel (.xlsx).✨ Características Principales📊 Dashboard Operativo: Visualización diaria del total de horas operadas, cantidad de lecturas registradas, promedio de horas por lectura y selector rápido por semana o calendario.⏱️ Registro de Horómetros: Ingreso ágil de nuevas lecturas asociadas a cada equipo, con cálculo de diferencias, edición y eliminación controlada de registros.🚜 Gestión de Equipos: Alta y administración de equipos identificados por código (ej. CO-TI-01, CO-GE-08), área/zona de operación, estado operativo y observaciones.📑 Exportación a Excel: Generación de reportes descargables y compartibles directamente desde el dispositivo en formato .xlsx.🌐 Multiplataforma y Responsivo: Interfaz adaptada para dispositivos móviles (Android) y navegadores web con diseño adaptable y control de escala tipográfica.☁️ Sincronización en la Nube: Comunicación mediante API REST (PHP + PDO) conectada a una base de datos relacional MySQL.📸 Capturas de PantallaAgrega tus capturas en una carpeta docs/screenshots/ y reemplaza las rutas a continuación.DashboardRegistro de HorómetroEquiposReportes🏗️ Arquitectura del Proyectocontrol_horom/
├── assets/
│   └── log.jpg                         # Ícono oficial de la aplicación
├── lib/
│   ├── core/
│   │   ├── api_service.dart            # Cliente HTTP para consumo de la API REST
│   │   ├── app_theme.dart              # Paleta corporativa y estilos globales
│   │   ├── date_utils_mina.dart        # Utilidades de formato y cálculo de fechas
│   │   └── responsive.dart             # Breakpoints y adaptación móvil/web
│   ├── models/
│   │   ├── equipo.dart                 # Modelo de entidad Equipo
│   │   └── registro_horometro.dart     # Modelo de entidad Lectura de Horómetro
│   ├── state/
│   │   └── mina_controller.dart        # Gestión de estado y lógica de negocio
│   ├── ui/
│   │   ├── screens/
│   │   │   ├── dashboard_screen.dart           # Resumen diario y calendario
│   │   │   ├── registro_horometro_screen.dart  # Formulario de lecturas
│   │   │   ├── registro_equipo_screen.dart     # Catálogo y alta de equipos
│   │   │   └── reportes_screen.dart            # Generación y exportación Excel
│   │   └── widgets/
│   │       └── home_shell.dart         # Navegación principal (BottomNavigationBar)
│   └── main.dart                       # Punto de entrada de la aplicación
└── pubspec.yaml                        # Dependencias y configuración de íconos
🛠️ Tecnologías y DependenciasFrontend (Flutter)Flutter & Dart (^3.11.1)http — Peticiones REST compatibles con Android y Web.excel — Construcción de hojas de cálculo .xlsx.path_provider — Almacenamiento temporal de archivos en el dispositivo.share_plus — Compartición nativa de reportes generados.flutter_launcher_icons — Generación automatizada de íconos para Android, iOS y Web.BackendPHP 8+ (PDO) — API REST con soporte CORS y consultas preparadas contra inyección SQL.MySQL / MariaDB — Persistencia de registros y equipos.🚀 Instalación y Puesta en MarchaPrerrequisitosFlutter SDK (Dart ^3.11.1)Android Studio / VS Code con soporte para FlutterServidor con PHP y MySQL (para el backend)1. Clonar el repositorio e instalar dependenciasgit clone https://github.com/tu-usuario/control_horom.git
cd control_horom
flutter pub get
2. Configurar la URL de la APIActualiza la URL base de tu servidor en lib/core/api_service.dart:static const String baseUrl = 'https://tu-dominio.com/api.php';
3. Generar íconos de la aplicación (opcional)Si cambias el logo en assets/log.jpg, regenera los íconos con:dart run flutter_launcher_icons
4. Ejecutar en modo desarrollo# En dispositivo Android o emulador
flutter run

# En navegador web (Chrome)
flutter run -d chrome
5. Compilar APK para distribución (Release)flutter build apk --release
El instalador final se generará en:build/app/outputs/flutter-apk/app-release.apk
Nota para Windows: Si el proyecto se encuentra en una unidad distinta al disco C:\ (por ejemplo, F:\), agrega kotlin.incremental=false en android/gradle.properties para evitar conflictos de rutas relativas al compilar en modo release.🗄️ Configuración del Backend y Base de DatosEsquema SQL referencialCREATE TABLE luminarias (
    id VARCHAR(64) PRIMARY KEY,
    codigo VARCHAR(50) NOT NULL,
    area_zona VARCHAR(100) NOT NULL DEFAULT 'SIN ÁREA',
    estado VARCHAR(50) NOT NULL DEFAULT 'OPERATIVO',
    fecha_registro DATE NOT NULL,
    observacion TEXT,
    horometro DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
Endpoints de la API (api.php)MétodoParámetros / PayloadDescripciónGET—Obtiene todos los registros ordenados por fecha_registro y horometro ascendente.POST{ codigo, area_zona, estado, fecha_registro, observacion, horometro }Inserta una nueva lectura de horómetro o equipo.POST{ accion: "actualizar", id, horometro, observacion }Actualiza el horómetro y observación de una lectura existente.POST{ accion: "eliminar", id }Elimina una lectura específica por su id (UUID).🔒 SeguridadImportante: Por motivos de seguridad, las credenciales reales de la base de datos y claves de API no deben incluirse en este repositorio.Utiliza un archivo config.php excluido mediante .gitignore en el servidor para almacenar $host, $db_name, $username y $password.Para entornos de producción, se recomienda habilitar autenticación mediante cabecera X-API-KEY o tokens JWT.👨‍💻 AutorDavid — Ingeniero de Sistemas📄 LicenciaEste proyecto es de uso privado / interno. Todos los derechos reservados © 2026.