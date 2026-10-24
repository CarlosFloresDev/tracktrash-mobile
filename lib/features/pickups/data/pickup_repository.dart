import 'package:dio/dio.dart';
import '../../../core/api_failure.dart';
import '../domain/pickup.dart';

abstract interface class PickupRepository {
  Future<List<Pickup>> list({int page = 1});
  Future<int> points();
  Future<Pickup> create(PickupDraft draft);
  Future<Pickup> accept(String id);
  Future<Pickup> confirm(String id, String code);
}

class ApiPickupRepository implements PickupRepository {
  ApiPickupRepository(this._dio, this._token);
  final Dio _dio;
  final String _token;
  Options get _options => Options(headers: {'Authorization': 'Bearer $_token'});

  Future<T> _request<T>(Future<T> Function() action) async {
    if (_token.isEmpty) {
      throw const ApiFailure('Inicia sesión para continuar.');
    }
    try {
      return await action();
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  @override
  Future<List<Pickup>> list({int page = 1}) => _request(() async {
    final response = await _dio.get<List<dynamic>>(
      '/api/v1/solicitudes',
      queryParameters: {'pagina': page},
      options: _options,
    );
    return response.data!
        .map((j) => Pickup.fromJson(j as Map<String, dynamic>))
        .toList();
  });

  @override
  Future<int> points() => _request(() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/perfil/impacto',
      options: _options,
    );
    return response.data!['puntos'] as int;
  });

  @override
  Future<Pickup> create(PickupDraft draft) =>
      _post('/api/v1/solicitudes', draft.toJson());

  @override
  Future<Pickup> accept(String id) =>
      _post('/api/v1/solicitudes/$id/aceptacion', null);

  @override
  Future<Pickup> confirm(String id, String code) =>
      _post('/api/v1/solicitudes/$id/confirmacion', {'codigo': code});

  Future<Pickup> _post(String path, Map<String, dynamic>? data) =>
      _request(() async {
        final response = await _dio.post<Map<String, dynamic>>(
          path,
          data: data,
          options: _options,
        );
        return Pickup.fromJson(response.data!);
      });
}
