import 'dart:convert';
import 'package:dio/dio.dart';
import 'public_map_cache.dart';
import '../../../core/api_failure.dart';
import '../domain/community_models.dart';

abstract interface class CommunityRepository {
  Future<void> reportLevel(String id, int percentage);
  Future<List<Map<String, dynamic>>> movements();
  Future<List<RouteSchedule>> routes();
  Future<void> subscribe(String id, bool enabled, {int minutesBefore = 20});
  Future<void> reportPass(String id);
  Future<CommunityMap> map({double lat = -16.3988, double lng = -71.5369});
  Future<CommunityProfile> profile();
  Future<void> saveProfile(CommunityProfile profile);
  Future<List<CommunityIssue>> issues();
  Future<void> report(String containerId, String type, String description);
  Future<void> attend(String id);
  Future<void> resolve(String id, String description);
  Future<List<CommunityNotice>> notices();
  Future<void> readNotice(String id);
  Future<List<Reward>> rewards();
  Future<List<Redemption>> redemptions();
  Future<void> redeem(String id, String key);
  Future<OperationMetrics> metrics();
  Future<void> travel(String id);
  Future<void> cancel(String id, String reason);
  Future<void> assign(String id);
  Future<List<Map<String, dynamic>>> history(String id);
}

class ApiCommunityRepository implements CommunityRepository {
  @override
  Future<void> reportLevel(String id, int percentage) =>
      _post('contenedores/$id/reporte-nivel', {'porcentaje': percentage});
  @override
  Future<List<Map<String, dynamic>>> movements() => _list('perfil/movimientos');
  @override
  Future<List<RouteSchedule>> routes() async =>
      (await _list('rutas')).map(RouteSchedule.fromJson).toList();
  @override
  Future<void> subscribe(String id, bool enabled, {int minutesBefore = 20}) =>
      enabled
      ? _post('rutas/$id/suscripcion', {'minutosAntes': minutesBefore})
      : _request(() async {
          await _dio.delete<dynamic>(
            '/api/v1/rutas/$id/suscripcion',
            options: _options,
          );
        });
  @override
  Future<void> reportPass(String id) => _post('rutas/$id/paso');
  ApiCommunityRepository(this._dio, this._token, {PublicMapCache? mapCache})
    : _mapCache = mapCache ?? const SharedPreferencesMapCache();
  final Dio _dio;
  final String _token;
  final PublicMapCache _mapCache;
  Options get _options => Options(headers: {'Authorization': 'Bearer $_token'});
  Future<T> _request<T>(Future<T> Function() action) async {
    if (_token.isEmpty) throw const ApiFailure('Inicia sesión para continuar.');
    try {
      return await action();
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  Future<Map<String, dynamic>> _get(String path) => _request(
    () async => (await _dio.get<Map<String, dynamic>>(
      '/api/v1/$path',
      options: _options,
    )).data!,
  );
  Future<List<Map<String, dynamic>>> _list(String path) => _request(
    () async => (await _dio.get<List<dynamic>>(
      '/api/v1/$path',
      options: _options,
    )).data!.cast<Map<String, dynamic>>(),
  );
  Future<void> _post(String path, [Map<String, dynamic>? data]) => _request(
    () async {
      await _dio.post<dynamic>('/api/v1/$path', data: data, options: _options);
    },
  );
  @override
  Future<CommunityMap> map({
    double lat = -16.3988,
    double lng = -71.5369,
  }) async {
    final key =
        'public-map-${Uri.encodeComponent(_dio.options.baseUrl)}-${lat.toStringAsFixed(3)}-${lng.toStringAsFixed(3)}';
    try {
      final json = await _get('mapa?lat=$lat&lng=$lng&radioKm=10');
      try {
        await _mapCache.write(key, jsonEncode(json));
      } catch (_) {
        /* El mapa no depende de poder escribir la caché. */
      }
      return CommunityMap.fromJson(json);
    } on ApiFailure {
      try {
        final stored = await _mapCache.read(key);
        if (stored != null) {
          return CommunityMap.fromJson(
            jsonDecode(stored) as Map<String, dynamic>,
            cached: true,
          );
        }
      } catch (_) {
        /* Caché ausente o incompatible. */
      }
      rethrow;
    }
  }

  @override
  Future<CommunityProfile> profile() async =>
      CommunityProfile.fromJson(await _get('perfil'));
  @override
  Future<void> saveProfile(CommunityProfile p) => _request(() async {
    await _dio.put<dynamic>(
      '/api/v1/perfil',
      data: p.toJson(),
      options: _options,
    );
  });
  @override
  Future<List<CommunityIssue>> issues() async =>
      (await _list('incidencias')).map(CommunityIssue.fromJson).toList();
  @override
  Future<void> report(String id, String type, String text) => _post(
    'incidencias',
    {'contenedorId': id, 'tipo': type, 'descripcion': text},
  );
  @override
  Future<void> attend(String id) => _post('incidencias/$id/atencion');
  @override
  Future<void> resolve(String id, String text) =>
      _post('incidencias/$id/resolucion', {'resolucion': text});
  @override
  Future<List<CommunityNotice>> notices() async =>
      (await _list('notificaciones')).map(CommunityNotice.fromJson).toList();
  @override
  Future<void> readNotice(String id) => _post('notificaciones/$id/lectura');
  @override
  Future<List<Reward>> rewards() async =>
      (await _list('beneficios')).map(Reward.fromJson).toList();
  @override
  Future<List<Redemption>> redemptions() async =>
      (await _list('canjes')).map(Redemption.fromJson).toList();
  @override
  Future<void> redeem(String id, String key) =>
      _post('canjes', {'beneficioId': id, 'clave': key});
  @override
  Future<OperationMetrics> metrics() async =>
      OperationMetrics.fromJson(await _get('operacion/indicadores'));
  @override
  Future<void> travel(String id) => _post('solicitudes/$id/viaje');
  @override
  Future<void> cancel(String id, String reason) =>
      _post('solicitudes/$id/cancelacion', {'motivo': reason});
  @override
  Future<void> assign(String id) => _post('solicitudes/$id/asignacion');
  @override
  Future<List<Map<String, dynamic>>> history(String id) =>
      _list('solicitudes/$id/historial');
}
