import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../core/api_failure.dart';
import '../../core/config.dart';

@immutable
class UserSession {
  const UserSession({required this.token, required this.role});
  final String token;
  final String role;
  bool get isRecycler => role == 'reciclador';
}

class SessionController extends ChangeNotifier {
  SessionController(this._dio);
  final Dio _dio;
  UserSession? _session;
  UserSession? get session => _session;
  bool _busy = false;
  bool get busy => _busy;
  String? _error;
  String? get error => _error;

  Future<void> signInDemo(String role) async {
    if (!AppConfig.demoMode || _busy) return;
    _busy = true;
    _error = null;
    notifyListeners();
    final token = role == 'reciclador' ? 'demo-reciclador' : 'demo-vecino';
    try {
      final result = await _dio.get<Map<String, dynamic>>(
        '/api/v1/perfil',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      _session = UserSession(token: token, role: result.data!['rol'] as String);
    } on DioException catch (e) {
      _error = ApiFailure.fromDio(e).message;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  void signOut() {
    _session = null;
    _error = null;
    notifyListeners();
  }
}
