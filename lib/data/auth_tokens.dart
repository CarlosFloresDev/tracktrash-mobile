import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'models.dart';

/// Token pair returned by `POST /api/Auth/Login` and `POST /api/Auth/Refresh`.
@immutable
class AuthTokens {
  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
  });

  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;

  /// Renews slightly before the real expiry so a request never leaves with a dead token.
  bool get isExpired =>
      DateTime.now().isAfter(expiresAt.subtract(const Duration(seconds: 30)));

  factory AuthTokens.fromJson(Json json) => AuthTokens(
    accessToken: json['accessToken'] as String,
    refreshToken: json['refreshToken'] as String,
    expiresAt: DateTime.parse(json['expiresAt'] as String).toUtc(),
  );

  Json toJson() => {
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'expiresAt': expiresAt.toIso8601String(),
  };
}

/// Persistence for the token pair. Secure storage on devices, memory in tests.
abstract interface class SessionStorage {
  Future<AuthTokens?> readTokens();
  Future<void> writeTokens(AuthTokens? tokens);
}

class SecureSessionStorage implements SessionStorage {
  const SecureSessionStorage();
  static const _key = 'tracktrash.tokens';
  static const _storage = FlutterSecureStorage();

  @override
  Future<AuthTokens?> readTokens() async {
    final raw = await _storage.read(key: _key);
    if (raw == null) return null;
    try {
      return AuthTokens.fromJson(jsonDecode(raw) as Json);
    } on Object {
      await _storage.delete(key: _key);
      return null;
    }
  }

  @override
  Future<void> writeTokens(AuthTokens? tokens) => tokens == null
      ? _storage.delete(key: _key)
      : _storage.write(key: _key, value: jsonEncode(tokens.toJson()));
}

/// Single source of truth for the current tokens, shared by the HTTP layer and the session.
class TokenVault {
  TokenVault(this._storage);
  final SessionStorage _storage;
  final _expired = StreamController<void>.broadcast();

  AuthTokens? _tokens;
  AuthTokens? get tokens => _tokens;

  /// Fires when the server rejects the session (refresh token revoked or expired).
  Stream<void> get onExpired => _expired.stream;

  Future<AuthTokens?> load() async {
    try {
      _tokens = await _storage.readTokens();
    } on Object {
      _tokens = null;
    }
    return _tokens;
  }

  Future<void> save(AuthTokens tokens) async {
    _tokens = tokens;
    await _storage.writeTokens(tokens).catchError((Object _) {});
  }

  Future<void> clear() async {
    _tokens = null;
    await _storage.writeTokens(null).catchError((Object _) {});
  }

  Future<void> expire() async {
    if (_tokens == null) return;
    await clear();
    _expired.add(null);
  }

  void dispose() => _expired.close();
}
