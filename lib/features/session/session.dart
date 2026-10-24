import 'package:dio/dio.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  SessionController(this._dio, {SupabaseClient? auth}) : _auth = auth {
    if (auth != null) {
      _subscription = auth.auth.onAuthStateChange.listen((data) {
        if (data.event == AuthChangeEvent.tokenRefreshed &&
            data.session != null) {
          unawaited(_applyToken(data.session!.accessToken));
        }
        if (data.event == AuthChangeEvent.signedOut && _session != null) {
          _session = null;
          _notify();
        }
      });
      if (auth.auth.currentSession != null) {
        scheduleMicrotask(
          () => _applyToken(auth.auth.currentSession!.accessToken),
        );
      }
    }
  }
  final Dio _dio;
  final SupabaseClient? _auth;
  StreamSubscription<AuthState>? _subscription;
  bool _disposed = false;
  int _generation = 0;
  String? _message;
  String? get message => _message;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

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
    final generation = ++_generation;
    _notify();
    final token = role == 'admin'
        ? 'demo-admin'
        : role == 'reciclador'
        ? 'demo-reciclador'
        : 'demo-vecino';
    try {
      final result = await _dio.get<Map<String, dynamic>>(
        '/api/v1/perfil',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (!_disposed && generation == _generation) {
        _session = UserSession(
          token: token,
          role: result.data!['rol'] as String,
        );
      }
    } on DioException catch (e) {
      _error = ApiFailure.fromDio(e).message;
    } finally {
      _busy = false;
      _notify();
    }
  }

  void signOut() {
    _generation++;
    _session = null;
    _error = null;
    _notify();
    if (_auth != null) {
      unawaited(_auth.auth.signOut().catchError((Object _) {}));
    }
  }

  Future<void> _applyToken(String token) async {
    final generation = _generation;
    try {
      final result = await _dio.get<Map<String, dynamic>>(
        '/api/v1/perfil',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (!_disposed && generation == _generation) {
        _session = UserSession(
          token: token,
          role: result.data!['rol'] as String,
        );
        _notify();
      }
    } on DioException catch (e) {
      if (!_disposed && generation == _generation) {
        _error = ApiFailure.fromDio(e).message;
        _notify();
      }
    }
  }

  Future<void> signIn(
    String email,
    String password, {
    bool register = false,
  }) async {
    if (_auth == null || _busy) return;
    _busy = true;
    _error = null;
    _message = null;
    _notify();
    try {
      final result = register
          ? await _auth.auth.signUp(email: email, password: password)
          : await _auth.auth.signInWithPassword(
              email: email,
              password: password,
            );
      if (result.session != null) {
        await _applyToken(result.session!.accessToken);
      } else {
        _message =
            'Revisa tu correo para confirmar tu cuenta y después inicia sesión.';
      }
    } on AuthException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'No pudimos conectar con el servicio de acceso.';
    } finally {
      _busy = false;
      _notify();
    }
  }

  Future<void> recover(String email) async {
    if (_auth == null || _busy) return;
    _busy = true;
    _error = null;
    _message = null;
    _notify();
    try {
      await _auth.auth.resetPasswordForEmail(email);
      _message =
          'Si el correo tiene una cuenta, recibirás instrucciones para recuperar el acceso.';
    } on AuthException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'No pudimos solicitar la recuperación.';
    } finally {
      _busy = false;
      _notify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    _subscription?.cancel();
    super.dispose();
  }
}
