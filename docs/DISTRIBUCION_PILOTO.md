# Distribución del piloto

Preparación 25/10/2026: Supabase ya existe; la API sigue pendiente del acceso de Render al repositorio privado. No hay una APK conectada al servidor público ni web publicada. Consultar `docs/DESPLIEGUE_GRATUITO.md` del backend.

## Firma Android

Release usa una firma propia, sin recurrir a la clave debug. Se generó localmente `artifacts/signing/tracktrash-pilot.jks`; `android/key.properties` contiene sus datos. Ambos están ignorados por Git. Guardar una copia privada de ambos antes de distribuir: hacen falta para que los usuarios puedan actualizar la APK sin desinstalar. No regenerar ni publicar la clave.

En otro equipo, crear `android/key.properties` con `storeFile` (ruta absoluta con barras `/`), `storePassword`, `keyAlias` y `keyPassword`, suministrados mediante un canal privado.

## Compilar cuando exista la API

Crear un JSON local con `API_BASE_URL` HTTPS real, `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY`, `DEMO_MODE: "false"` y `API_TIMEOUT_SECONDS: "90"`. Son parámetros públicos de compilación; nunca incluir claves service_role ni SQL. El timeout mayor admite el arranque en frío de Render Free; los errores permiten reintento manual, sin repetir automáticamente escrituras.

```powershell
flutter build web --dart-define-from-file=<config-publica.json>
flutter build apk --release --split-per-abi --dart-define-from-file=<config-publica.json>
```

Subir `build/web` a Cloudflare Pages y habilitar ese origen exacto en CORS del backend. `web/_headers` añade cabeceras de seguridad y revalidación del código; no sustituye HTTPS ni la autorización de la API.

Compartir la variante Android adecuada (normalmente arm64-v8a) mediante un alojamiento separado si supera el límite por archivo de Pages. Probar instalación, login real, permisos, mapa y recojo persistido en teléfono antes de anunciarla disponible. Conservar la versión previa para recuperación; esta preparación usa versión `0.2.1+3`.

Validado: Flutter analyze sin incidencias y 24 pruebas aprobadas. La compilación release, instalación física y recorrido remoto completo siguen pendientes.
