# Desarrollo de TrackTrash Flutter

- Leer README y la matriz de cobertura del backend; consumir el contrato HTTP versionado.
- Mantener UI/estado/datos separados. Pantallas sin Dio directo; reglas, permisos y saldos definitivos pertenecen al backend.
- No persistir datos privados en SharedPreferences. La caché actual contiene únicamente el mapa público; tokens Supabase usan secure storage.
- Incluir carga, vacío, error y reintento. Respetar animaciones reducidas, navegación accesible y anchos pequeños.
- SDK fijado en .fvmrc. No actualizar el SDK global ni dependencias indiscriminadamente.
- Validar formato, flutter analyze y flutter test; compilar web/APK cuando cambien integraciones. Pruebas de widget para interacción relevante, sin duplicar el código de implementación.
- Datos/ubicaciones/beneficios de demostración deben estar identificados. Crear commits por cambios coherentes; no guardar build/, tokens ni secretos.
