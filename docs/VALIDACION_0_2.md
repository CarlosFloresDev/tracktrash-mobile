# Validación local · 24/10/2026

Entorno: Windows, Flutter 3.41.6/Dart 3.11.4, API .NET 10 y PostgreSQL 17/PostGIS 3.5 en Docker. La API usa datos sintéticos de Development, sin Supabase remoto ni información personal real.

| Comprobación | Resultado |
|---|---|
| Formato y flutter analyze | Sin incidencias |
| flutter test | 19 pruebas aprobadas |
| Backend asociado | 36 pruebas aprobadas, compilación Release sin errores/advertencias |
| Contenedor Linux API | Usuario UID 1654; health/ready y perfil autenticado responden 200 contra PostgreSQL local |
| Dependencias .NET | Consulta NuGet de vulnerabilidades, incluidas transitivas, sin vulnerabilidades conocidas reportadas en la fecha de revisión |
| Build web | Completado |
| APK Android debug | Completado; requiere instalación posterior para validar dispositivo |
| Recorrido HTTP real en Edge headless | Crear con ubicación y autoasignación → aceptar → iniciar viaje → confirmar código → canjear beneficio |
| Comunidad en Edge | Mapa → reportar problema → consultar bandeja → suscribir recordatorio → operador toma atención → resuelve |
| Navegación y presentación | Anchos 360, 430 y 1280; cambio de rol y cierre de sesión sin errores JavaScript |
| Caché | Pruebas de falla de almacenamiento sin bloquear HTTP, recuperación del mapa anterior y separación por servidor |

Los scripts `tools/smoke_web.py` y `tools/smoke_community_web.py` se ejecutaron contra la API/BD reales. Habilitan semántica Flutter para interactuar con controles accesibles y comprueban respuestas del servidor. Son herramientas opcionales de QA, no parte del runtime ni sustituto de pruebas físicas. Crean datos de prueba; no eliminan solicitudes ajenas.

Las capturas de [screenshots](screenshots) documentan el estado local. No demuestran precisión del hardware, carga, disponibilidad, entrega push ni cumplimiento legal. Algunos contenedores aparecen sin datos recientes deliberadamente: no se falsifica su estado para que el mapa parezca activo.

CI independiente en [backend](https://github.com/CarlosFloresDev/tracktrash-backend/actions) y [mobile](https://github.com/CarlosFloresDev/tracktrash-mobile/actions). Revisar los checks del commit exacto en cada PR.

Para release todavía faltan firma de distribución propia, proyecto Auth/retornos, HTTPS/hosting, políticas de privacidad, proveedor de mosaicos apropiado al tráfico, validación Android/iOS y los módulos señalados en la matriz del backend.
