<div align="center">
  <img src="assets/log.jpg" alt="MINA-OPS Logo" width="130" />

  <h1>⚙️ MINA-OPS — Control de Horómetros</h1>

  <p>
    <strong>Sistema multiplataforma para el registro, control operativo y reportabilidad de horómetros en maquinaria minera.</strong>
  </p>

  <p>
    <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" />
    <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart" />
    <img src="https://img.shields.io/badge/PHP-777BB4?style=for-the-badge&logo=php&logoColor=white" alt="PHP" />
    <img src="https://img.shields.io/badge/MySQL-4479A1?style=for-the-badge&logo=mysql&logoColor=white" alt="MySQL" />
    <img src="https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white" alt="Android" />
    <img src="https://img.shields.io/badge/Web-0F172A?style=for-the-badge&logo=googlechrome&logoColor=white" alt="Web" />
  </p>

  <p>
    <a href="#-descripción-general">Descripción</a> •
    <a href="#-funcionalidades-clave">Funcionalidades</a> •
    <a href="#-arquitectura-del-sistema">Arquitectura</a> •
    <a href="#-instalación-y-despliegue">Instalación</a> •
    <a href="#-seguridad">Seguridad</a> •
    <a href="#-autor">Autor</a>
  </p>
</div>

---

## 📋 Descripción General

En operaciones mineras, el control manual de horómetros suele generar retrasos en la consolidación de horas trabajadas, errores de digitación y pérdida de trazabilidad por zona.

**MINA-OPS** resuelve este problema mediante una aplicación móvil (**Android**) y **Web** conectada en tiempo real a un backend centralizado. Permite digitalizar las lecturas diarias de equipos auxiliares (torres de iluminación `CO-TI`, grupos electrógenos `CO-GE`, entre otros), calcular horas operadas automáticamente y emitir reportes consolidados en formato **Excel (`.xlsx`)** listos para supervisión y facturación.

---

## ✨ Funcionalidades Clave

| Módulo | Capacidades Principales |
| :--- | :--- |
| **📊 Dashboard Operativo** | Indicadores diarios y semanales (KPIs): total de horas operadas, cantidad de lecturas, promedio de horas y navegación ágil por calendario. |
| **⏱️ Registro de Horómetros** | Precarga automática del último horómetro del equipo, validación de integridad de lecturas, edición y eliminación controlada. |
| **🚜 Gestión de Flota** | Alta y administración de equipos clasificados por código interno (`CO-TI`, `CO-GE`), área/zona de operación, estado y observaciones. |
| **📑 Reportes en Excel** | Generación local de archivos `.xlsx` consolidados, listos para descargar o compartir directamente por WhatsApp, correo o Drive. |
| **☁️ Sincronización Cloud** | Persistencia en tiempo real contra base de datos MySQL a través de una API REST ligera en PHP. |
| **📱 Diseño Responsivo** | Interfaz adaptable para smartphones en campo y navegadores de escritorio con control de escala tipográfica. |

---

## 🏛️ Arquitectura del Sistema

```mermaid
flowchart LR
    A["📱 App Android / 🌐 Web<br/>Flutter & Dart"] <-->|"HTTP / JSON"| B["⚙️ API REST<br/>PHP + PDO"]
    B <-->|"Consultas SQL"| C[("🗄️ Base de Datos<br/>MySQL")]
    A -->|"Motor Local"| D["📑 Reportes Excel<br/>.xlsx / Share"]
```

<details>
<summary><strong>📂 Ver estructura de carpetas del proyecto</strong></summary>

```text
control_horom/
├── assets/
│   └── log.jpg                         # Ícono oficial y branding de la aplicación
├── lib/
│   ├── core/
│   │   ├── api_service.dart            # Cliente HTTP para consumo de la API REST
│   │   ├── app_theme.dart              # Paleta corporativa y configuración de tema
│   │   ├── date_utils_mina.dart        # Utilidades de formato y semanas operativas
│   │   └── responsive.dart             # Breakpoints y adaptación móvil/web
│   ├── models/
│   │   ├── equipo.dart                 # Entidad Equipo (código, tipo, zona, estado)
│   │   └── registro_horometro.dart     # Entidad Lectura de Horómetro
│   ├── state/
│   │   └── mina_controller.dart        # Gestión de estado (ChangeNotifier) y reglas de negocio
│   ├── ui/
│   │   ├── screens/
│   │   │   ├── dashboard_screen.dart           # Panel de KPIs y resumen operativo
│   │   │   ├── registro_horometro_screen.dart  # Formulario de captura con validaciones
│   │   │   ├── registro_equipo_screen.dart     # Catálogo y alta de equipos
│   │   │   └── reportes_screen.dart            # Generación y exportación a Excel
│   │   └── home_shell.dart             # Navegación principal (NavigationBar)
│   └── main.dart                       # Punto de entrada y configuración global
└── pubspec.yaml
```

</details>

<details>
<summary><strong>🔌 Ver contrato de la API REST</strong></summary>

| Método | Endpoint | Descripción |
| :--- | :--- | :--- |
| `GET` | `/api.php` | Retorna el historial completo de lecturas y equipos registrados en formato JSON. |
| `POST` | `/api.php` | Registra una nueva lectura de horómetro o ejecuta acciones de mantenimiento de registros. |

**Ejemplo de payload `POST`:**
```json
{
  "codigo": "CO-TI-05",
  "area_zona": "TRAMO I",
  "estado": "OPERATIVO",
  "fecha_registro": "2026-11-19",
  "observacion": "Operación normal turno día",
  "horometro": 1452.5
}
```

</details>

---

## 📸 Vista Previa

> *Para mostrar capturas de pantalla, guarda tus imágenes en `docs/screenshots/` y reemplaza las rutas en la tabla inferior.*

| Dashboard Operativo | Registro de Horómetro | Gestión de Equipos | Reportes Excel |
| :---: | :---: | :---: | :---: |
| *(pendiente)* | *(pendiente)* | *(pendiente)* | *(pendiente)* |

---

## 🛠️ Stack Tecnológico

* **Framework & Lenguaje:** Flutter · Dart (`SDK ^3.11.1`)
* **Red & Datos:** `http` · API REST en PHP (PDO) · MySQL
* **Exportación de Documentos:** `excel` · `path_provider` · `share_plus`
* **Branding & Empaquetado:** `flutter_launcher_icons`

---

## 🚀 Instalación y Despliegue

### Requisitos previos
* Flutter SDK instalado y configurado (`flutter doctor` sin errores).
* Servidor web con PHP 8+ y MySQL para alojar el backend.

### 1. Clonar e instalar dependencias

```bash
git clone [https://github.com/tu-usuario/control_horom.git](https://github.com/tu-usuario/control_horom.git)
cd control_horom
flutter pub get
```

### 2. Ejecutar en desarrollo (sin hardcodear credenciales)

Configura el endpoint en `lib/core/api_service.dart` o pásalo como variable de entorno en tiempo de ejecución:

```bash
flutter run --dart-define=API_URL=[https://tu-dominio.com/api.php](https://tu-dominio.com/api.php)
```

### 3. Compilar para Producción

```bash
# Generar APK universal para Android
flutter build apk --release --dart-define=API_URL=[https://tu-dominio.com/api.php](https://tu-dominio.com/api.php)

# Generar compilación para despliegue Web
flutter build web --release --dart-define=API_URL=[https://tu-dominio.com/api.php](https://tu-dominio.com/api.php)
```

El instalador de Android se generará en `build/app/outputs/flutter-apk/app-release.apk`.

---

## 🔒 Seguridad

* Las credenciales de conexión a MySQL y la URL productiva de la API se mantienen **excluidas del repositorio**.
* Para entornos productivos se recomienda aislar la configuración del servidor en un archivo `config.php` ignorado mediante `.gitignore` e implementar validación mediante encabezado `X-API-KEY`.

---

## 🗺️ Roadmap

- [x] Registro de horómetros con precarga de última lectura y cálculo de horas
- [x] Exportación de reportes consolidados a Excel (`.xlsx`)
- [x] Compilación Release para distribución en Android (APK)
- [ ] Autenticación de endpoints mediante `X-API-KEY` / JWT
- [ ] Modo Offline-First con sincronización automática para zonas sin cobertura
- [ ] Alertas automáticas de mantenimiento preventivo (250 h / 500 h / 1000 h)

---

## 👨‍💻 Autor

**David** — *Ingeniero de Sistemas*

Si este proyecto te resultó útil o te interesa conocer más sobre su arquitectura, no dudes en conectar o dejar una ⭐ en el repositorio.