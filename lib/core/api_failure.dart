import 'package:dio/dio.dart';

/// Error shown to the user. Built from the backend's `{ "error": "..." }` and
/// ASP.NET validation problem details (`{ "errors": { "Field": ["..."] } }`).
class ApiFailure implements Exception {
  const ApiFailure(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  bool get isNotFound => statusCode == 404;

  factory ApiFailure.fromDio(DioException error) {
    final status = error.response?.statusCode;
    final data = error.response?.data;

    if (data is Map) {
      final errors = data['errors'];
      if (errors is Map) {
        final messages = errors.values
            .expand((value) => value is List ? value : [value])
            .join('\n');
        if (messages.isNotEmpty) return ApiFailure(messages, statusCode: status);
      }
      final message = data['error'];
      if (message is String && (status ?? 0) < 500) {
        return ApiFailure(message, statusCode: status);
      }
    }

    if (status == null) {
      return const ApiFailure(
        'No pudimos conectar con el servidor. Revisa tu conexión.',
      );
    }
    return ApiFailure(switch (status) {
      401 => 'Tu sesión no es válida. Vuelve a ingresar.',
      403 => 'No tienes permiso para esta operación.',
      404 => 'No encontramos lo que buscabas.',
      _ => 'El servidor tuvo un problema. Intenta de nuevo en unos minutos.',
    }, statusCode: status);
  }

  @override
  String toString() => message;
}
