import 'package:shared_preferences/shared_preferences.dart';

abstract interface class PublicMapCache {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

class SharedPreferencesMapCache implements PublicMapCache {
  const SharedPreferencesMapCache();

  // Inicializar el plugin al usarlo: si el almacenamiento está bloqueado o no
  // disponible, el repositorio debe poder mostrar igualmente la respuesta HTTP.
  @override
  Future<String?> read(String key) async =>
      SharedPreferencesAsync().getString(key);

  @override
  Future<void> write(String key, String value) async =>
      SharedPreferencesAsync().setString(key, value);
}
