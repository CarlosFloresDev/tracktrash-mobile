# TrackTrash Mobile

App Flutter independiente para TrackTrash. Backend: [tracktrash-backend](https://github.com/CarlosFloresDev/tracktrash-backend).

## Primer incremento

Acceso local de demostración como vecino/reciclador; creación de solicitudes, listado con estados, aceptación, código de confirmación e historial de puntos. Las pantallas consumen la API real; no incluyen datos ficticios como sustituto de una conexión fallida. Guía básica de materiales incluida.

Registro/login de usuarios reales, caché persistente sin conexión, mapa, sensores, incidencias, fotos y push siguen pendientes. El modo de demostración aparece identificado y se desactiva por defecto en compilaciones release.

## Ejecutar

SDK Flutter 3.41.6 / Dart 3.11.4, fijado en `.fvmrc`. El lockfile contiene versiones compatibles; no es necesario actualizar el SDK global. Si utilizas FVM, ejecuta sus comandos equivalentes con `fvm flutter`.

Primero iniciar backend y PostgreSQL siguiendo su README. Para probar en Edge:

```powershell
flutter pub get
flutter run -d edge --web-port=5300 --dart-define=API_BASE_URL=http://localhost:5080 --dart-define=DEMO_MODE=true
```

Android Emulator utiliza `10.0.2.2` para acceder al equipo anfitrión:

```powershell
flutter run -d <id-android> --dart-define=API_BASE_URL=http://10.0.2.2:5080 --dart-define=DEMO_MODE=true
```

En teléfono físico usar la IP LAN del equipo y exponer la API solo en la red de desarrollo; el README del backend incluye el comando. HTTP local se admite únicamente en el manifest de debug. Producción requiere HTTPS.

## Probar el recorrido

1. Ingresar como vecino y solicitar un recojo con datos de prueba.
2. Copiar el código visible en la tarjeta del vecino.
3. Cerrar sesión e ingresar como reciclador.
4. Aceptar el recojo; la dirección se habilita después de aceptarlo.
5. Confirmar con el código compartido por el vecino.
6. Volver como vecino o actualizar su sesión abierta: entrega confirmada y 20 puntos.

El cambio de rol es una herramienta local de demostración, no una forma de asignar permisos en producción. La sesión actual vive en memoria; no se persisten tokens de prueba. El paquete secure storage queda preparado para el siguiente incremento de autenticación.

## Validación

```powershell
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build web --dart-define=DEMO_MODE=true --dart-define=API_BASE_URL=http://localhost:5080
```

Las pruebas cubren validación/interacción de formulario, serialización, encabezados de identidad, errores, doble envío, reintentos y estado del ViewModel. La compilación web permite revisar la interfaz mientras se prepara el dispositivo Android. No equivale a validar APK o iOS; Android requiere licencias SDK aceptadas y teléfono/emulador, e iOS requiere macOS/Xcode.

## Arquitectura

- `app`: tema, router y registro de dependencias.
- `core`: configuración y errores de comunicación.
- `features/session`: estado de sesión y bienvenida.
- `features/pickups/domain`: modelos inmutables.
- `features/pickups/data`: contrato y repositorio API con Dio.
- `features/pickups/presentation`: ViewModel y pantallas.

Riverpod crea/inyecta dependencias y expone ViewModels ChangeNotifier, siguiendo MVVM. Las pantallas no llaman a Dio ni deciden reglas de puntos. go_router protege rutas según la sesión. Las reglas y permisos definitivos se verifican en C#.

API v1: contrato documentado en [backend/docs/API.md](https://github.com/CarlosFloresDev/tracktrash-backend/blob/feat/primer-flujo-recojos/docs/API.md). Próximos módulos: identidad real, aliados/mapa, cancelación, contenedores/incidencias y notificaciones.

## Git

`main` mantiene la base integrada, las tareas se desarrollan en ramas `feat/<tarea>` y se revisan mediante pull requests. CI ejecuta formato, análisis, pruebas y compilación web.
