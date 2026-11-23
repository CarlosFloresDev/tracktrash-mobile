# TrackTrash Mobile

App Flutter de TrackTrash: coordina recojos de residuos reciclables en Arequipa entre hogares, organizaciones y
recolectores. Consume la API de `Luladusilva/TrackTrash` (ASP.NET Core, PostgreSQL).

## Qué hace

| Rol | Recorridos |
| --- | --- |
| Hogar y organización | Crear solicitud (materiales, dirección con GPS opcional, fecha y hora), seguir su estado, ver historial, cancelar y calificar el servicio |
| Recolector | Ver recojos disponibles, tomarlos, iniciar, registrar material recuperado, finalizar o soltar; ver sus servicios, kilos y calificación |
| Administrador | Indicadores generales (la gestión completa está en la web) |
| Todos | Mapa de puntos de acopio, perfil y cambio de datos |

## Estructura

```
lib/
  core/      configuración y ApiFailure (errores del backend en español)
  data/      enums, modelos y TrackTrashApi (interfaz) + DioTrackTrashApi
  features/  session, requests, gatherer, home, points, profile
  app/       providers, router y shell con navegación por rol
  ui/        tema Eco y widgets compartidos
test/        modelos, errores de API, sesión y flujo de acceso
```

Las pantallas no usan Dio: dependen de `TrackTrashApi`, que en pruebas se reemplaza por un fake.

## Acceso provisional

El backend aún no tiene login ni valida contraseñas (ver `docs/HALLAZGOS_BACKEND.md` en el repo web). La app
identifica la cuenta por correo mediante `AuthGateway` (`lib/features/session/session.dart`) y lo avisa en la pantalla
de ingreso. Cuando exista `POST /api/Auth/login` solo hay que añadir otra implementación de `AuthGateway`.

## Ejecutar

Flutter 3.41.6 (ver `.fvmrc`). Con el backend corriendo (`local-dev/run-api.cmd` del repo web):

```powershell
flutter pub get
flutter run -d edge --dart-define=API_BASE_URL=http://localhost:5145
```

Emulador Android: `API_BASE_URL=http://10.0.2.2:5145`. Teléfono físico: la IP de tu PC en la red local.
HTTP solo para desarrollo; producción requiere HTTPS.

```powershell
flutter analyze
flutter test
```
