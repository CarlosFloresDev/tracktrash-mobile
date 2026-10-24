import 'package:dio/dio.dart';

class ApiFailure implements Exception {
  const ApiFailure(this.message);
  final String message;

  factory ApiFailure.fromDio(DioException error) {
    final data = error.response?.data;
    if (data is Map && data['errors'] is Map) {
      final errors = data['errors'] as Map;
      return ApiFailure(errors.values.expand((e) => e as List).join('\n'));
    }
    if (data is Map && data['title'] is String) {
      return ApiFailure(data['title'] as String);
    }
    return ApiFailure(switch (error.response?.statusCode) {
      401 => 'Tu sesión no es válida. Vuelve a ingresar.',
      403 => 'No tienes permiso para esta operación.',
      409 => 'La solicitud cambió. Actualiza antes de volver a intentarlo.',
      429 => 'Has realizado varios intentos. Espera un minuto.',
      _ => 'No pudimos conectar. Revisa tu conexión y vuelve a intentarlo.',
    });
  }

  @override
  String toString() => message;
}
