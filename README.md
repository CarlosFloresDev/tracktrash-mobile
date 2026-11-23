<p align="center">
  <img src="docs/assets/banner.svg" alt="TrackTrash, app móvil de recojo y reciclaje en Arequipa" width="100%">
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.41-143d2b?style=for-the-badge&logo=flutter&logoColor=d7f58b" alt="Flutter 3.41">
  <img src="https://img.shields.io/badge/Dart-3.11-143d2b?style=for-the-badge&logo=dart&logoColor=d7f58b" alt="Dart 3.11">
  <img src="https://img.shields.io/badge/Riverpod-estado-143d2b?style=for-the-badge" alt="Riverpod">
  <img src="https://img.shields.io/badge/Android-APK-143d2b?style=for-the-badge&logo=android&logoColor=d7f58b" alt="Android">
  <img src="https://img.shields.io/badge/Pruebas-21-143d2b?style=for-the-badge" alt="21 pruebas">
</p>

<p align="center">
  <a href="#funcionalidades">Funcionalidades</a> ·
  <a href="#capturas">Capturas</a> ·
  <a href="#arquitectura">Arquitectura</a> ·
  <a href="#ejecutar">Ejecutar</a>
</p>

## Sobre el proyecto

**TrackTrash** coordina el recojo de residuos reciclables en Arequipa entre hogares, organizaciones y recolectores
verificados. Esta es la app móvil, pensada para el uso en la calle: pedir un recojo desde casa o tomarlo y registrar los
kilos recuperados como recolector. Comparte el contrato con la [plataforma web](https://github.com/CarlosFloresDev/tracktrash-web).

| Repositorio | Tecnología |
| --- | --- |
| Mobile (este repositorio) | Flutter, Riverpod, go_router, Dio |
| [Web](https://github.com/CarlosFloresDev/tracktrash-web) | React, TypeScript, Tailwind CSS |
| [Backend](https://github.com/Luladusilva/TrackTrash) | ASP.NET Core 10, CQRS con MediatR, PostgreSQL |

## Funcionalidades

| Rol | Recorridos |
| --- | --- |
| Hogar y organización | Crear solicitudes (materiales, dirección con GPS opcional, fecha y hora), seguir su estado, ver historial, cancelar y calificar |
| Recolector | Ver recojos disponibles, tomarlos, iniciar, registrar material recuperado, finalizar o soltar; kilos y calificación propios |
| Administrador | Indicadores generales (la gestión completa está en la web) |
| Todos | Mapa de puntos de acopio con contacto, perfil y edición de datos |

Experiencia: banner animado, mascota flotante, entrada escalonada de tarjetas, tirar para actualizar, estados de carga,
vacío y error, y respeto a la opción "reducir movimiento" del sistema.

## Capturas

<p align="center">
  <img src="docs/assets/m-login.png" alt="Ingreso" width="23%">
  <img src="docs/assets/m-home.png" alt="Inicio del hogar" width="23%">
  <img src="docs/assets/m-requests.png" alt="Mis solicitudes" width="23%">
  <img src="docs/assets/m-points.png" alt="Puntos de acopio" width="23%">
</p>

## Arquitectura

```mermaid
flowchart LR
  subgraph App["tracktrash-mobile"]
    UI["features/* (pantallas)"] --> Prov["Providers Riverpod"]
    Prov --> Actions["RequestActions"]
    Prov --> Api["TrackTrashApi (interfaz)"]
    Actions --> Api
    UI --> Session["SessionController + AuthGateway"]
  end
  Api -->|Dio, JSON| API["API ASP.NET Core"]
  API --> DB[("PostgreSQL")]
```

```
lib/
  core/      configuración y ApiFailure (errores del backend en español)
  data/      enums, modelos y TrackTrashApi + DioTrackTrashApi
  features/  session, requests, gatherer, home, points, profile
  app/       providers, router y navegación por rol
  ui/        tema, animaciones y widgets compartidos
test/        modelos, errores de API, sesión y flujo de acceso
```

* Las pantallas no usan Dio directamente: dependen de `TrackTrashApi`, que en pruebas se reemplaza por un fake.
* `AuthGateway` aísla el acceso. El backend aún no valida contraseñas; la app identifica la cuenta por correo y lo avisa.
  Cuando exista `POST /api/Auth/login` solo se agrega otra implementación.
* Las transiciones de estado replican las reglas del backend para ofrecer solo acciones válidas.

## Ejecutar

Flutter 3.41.6 (ver `.fvmrc`). Con la API corriendo (instrucciones en el repositorio web, carpeta `local-dev`):

```powershell
flutter pub get
flutter run --dart-define=API_BASE_URL=http://localhost:5145
```

| Entorno | `API_BASE_URL` |
| --- | --- |
| Navegador o escritorio | `http://localhost:5145` |
| Emulador Android | `http://10.0.2.2:5145` |
| Teléfono físico | `http://<IP-de-tu-PC>:5145` |
| Producción | `https://<api-en-render>` |

```powershell
flutter analyze
flutter test
flutter build apk --release --dart-define=API_BASE_URL=https://<api-en-render>
```

Cuentas de ejemplo (contraseña `TrackTrash2026!`): `lucia@correo.pe` (hogar), `elmer@recicla.pe` (recolector),
`admin@tracktrash.pe` (administrador).

---

<p align="center">Proyecto académico de Tecsup Arequipa, 2026.</p>
