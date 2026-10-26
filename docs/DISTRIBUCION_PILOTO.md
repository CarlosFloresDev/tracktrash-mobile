# Distribución del piloto

Piloto 25/10/2026: [web publicada](https://tracktrash.pages.dev) y [API en Render Free](https://tracktrash-api.onrender.com/health/ready), conectadas a Supabase real. Los datos son ficticios. Ambos repositorios son públicos por autorización del propietario; versión actual en `feat/ecosistema-tracktrash`, PR #2 abierto. Consultar `docs/DESPLIEGUE_GRATUITO.md` del backend.

## Firma Android

Release usa una firma propia, sin recurrir a la clave debug. Se generó localmente `artifacts/signing/tracktrash-pilot.jks`; `android/key.properties` contiene sus datos. Ambos están ignorados por Git. Guardar una copia privada de ambos antes de distribuir: hacen falta para que los usuarios puedan actualizar la APK sin desinstalar. No regenerar ni publicar la clave.

En otro equipo, crear `android/key.properties` con `storeFile` (ruta absoluta con barras `/`), `storePassword`, `keyAlias` y `keyPassword`, suministrados mediante un canal privado.

## Compilar con el servidor del piloto

`config/pilot.public.json` contiene `API_BASE_URL` HTTPS real, `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY`, `DEMO_MODE: "false"` y `API_TIMEOUT_SECONDS: "90"`. Son parámetros públicos de compilación; nunca incluir claves service_role ni SQL. El timeout mayor admite el arranque en frío de Render Free; los errores permiten reintento manual, sin repetir automáticamente escrituras.

```powershell
flutter build web --dart-define-from-file=config/pilot.public.json
flutter build apk --release --split-per-abi --dart-define-from-file=config/pilot.public.json
```

Web desplegada en Cloudflare Pages; su origen exacto está habilitado en CORS del backend. `web/_headers` añade cabeceras de seguridad y revalidación del código; no sustituye HTTPS ni la autorización de la API. Volver a publicar con `npx wrangler pages deploy build/web --project-name tracktrash --branch main`; esta rama identifica el entorno de Pages, no la rama del código fuente.

Compartir la variante Android adecuada (normalmente arm64-v8a) mediante un alojamiento separado si supera el límite por archivo de Pages. Probar instalación, login real, permisos, mapa y recojo persistido en teléfono antes de anunciarla disponible. Conservar la versión previa para recuperación; esta preparación usa versión `0.2.1+3`.

Validado: Flutter analyze sin incidencias, 24 pruebas aprobadas y web Release compilada. Recorrido Edge headless sobre Pages: login real, perfil, mapa y cierre de sesión aprobados, sin excepciones de JavaScript ni controles demo. API remota: tres roles, denegaciones 401/403, CORS, recojo creado/consultado/cancelado y Location HTTPS verificados. Instalación física, recuperación completa, correo, push y hardware siguen pendientes.
