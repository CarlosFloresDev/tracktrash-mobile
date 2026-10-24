import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracktrash_mobile/features/community/data/community_repository.dart';
import 'package:tracktrash_mobile/features/community/data/public_map_cache.dart';
import 'pickup_repository_test.dart' show StubAdapter;

class MemoryMapCache implements PublicMapCache {
  final entries = <String, String>{};
  bool broken = false;
  @override
  Future<String?> read(String key) async {
    if (broken) throw StateError('Almacenamiento no disponible');
    return entries[key];
  }

  @override
  Future<void> write(String key, String value) async {
    if (broken) throw StateError('Almacenamiento no disponible');
    entries[key] = value;
  }
}

const payload = {
  'contenedores': [
    {'id': 'demo', 'nombre': 'Tacho', 'latitud': -16.4, 'longitud': -71.5},
  ],
  'asociaciones': [],
  'puntosAcopio': [],
};

void main() {
  test(
    'la falla de almacenamiento no impide consultar y mostrar el mapa HTTP',
    () async {
      final adapter = StubAdapter()..payload = payload;
      final dio = Dio(BaseOptions(baseUrl: 'https://api.example'))
        ..httpClientAdapter = adapter;
      addTearDown(dio.close);
      final cache = MemoryMapCache()..broken = true;
      final result = await ApiCommunityRepository(
        dio,
        'token',
        mapCache: cache,
      ).map();
      expect(result.places.single.name, 'Tacho');
      expect(result.cached, false);
      expect(adapter.request!.path, contains('/mapa'));
    },
  );

  test(
    'si falla la API muestra el último mapa público y lo marca antiguo',
    () async {
      final adapter = StubAdapter()..payload = payload;
      final dio = Dio(BaseOptions(baseUrl: 'https://api.example'))
        ..httpClientAdapter = adapter;
      addTearDown(dio.close);
      final cache = MemoryMapCache();
      final repo = ApiCommunityRepository(dio, 'token', mapCache: cache);
      await repo.map();
      adapter.status = 503;
      final result = await repo.map();
      expect(result.cached, true);
      expect(result.places.single.id, 'demo');
      expect(jsonDecode(cache.entries.values.single), payload);
    },
  );

  test('el mapa guardado se separa por servidor de origen', () async {
    final cache = MemoryMapCache();
    for (final host in ['https://api-a.example', 'https://api-b.example']) {
      final dio = Dio(BaseOptions(baseUrl: host))
        ..httpClientAdapter = (StubAdapter()..payload = payload);
      addTearDown(dio.close);
      await ApiCommunityRepository(dio, 'token', mapCache: cache).map();
    }
    expect(cache.entries.length, 2);
  });
}
