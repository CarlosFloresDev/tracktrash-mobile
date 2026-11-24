import 'dart:async';
import 'package:dio/dio.dart';
import 'auth_tokens.dart';
import 'models.dart';

/// Marks a request that must travel without a Bearer token (login, refresh, logout, sign-up).
const anonymous = 'anonymous';
const _retried = 'retried';

/// Adds the Bearer token, renews it when it expires and retries once after a
/// `401 ACCESS_TOKEN_EXPIRED`. The refresh token rotates, so concurrent renewals share one call.
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor(this._vault, this._plain);

  final TokenVault _vault;

  /// Client without this interceptor, used for refresh calls and retries.
  final Dio _plain;
  Future<AuthTokens?>? _refreshing;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra[anonymous] == true) return handler.next(options);
    var tokens = _vault.tokens;
    if (tokens != null && tokens.isExpired) tokens = await refresh();
    if (tokens != null) {
      options.headers['Authorization'] = 'Bearer ${tokens.accessToken}';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final error = err;
    final options = error.requestOptions;
    final response = error.response;
    if (response?.statusCode != 401 ||
        options.extra[anonymous] == true ||
        options.extra[_retried] == true ||
        _vault.tokens == null) {
      return handler.next(error);
    }
    final data = response?.data;
    // The backend also answers 401 for business rules ("Only verified gatherers can apply."):
    // those carry an `error` message and no `code`, and must not end the session.
    if (data is Map && data['error'] is String && data['code'] == null) {
      return handler.next(error);
    }
    final expired = data is Map && data['code'] == 'ACCESS_TOKEN_EXPIRED';
    final sent = options.headers['Authorization'];
    final current = 'Bearer ${_vault.tokens?.accessToken}';
    if (!expired && sent == current) {
      // The token is valid but no longer accepted (user deactivated, key rotated): end the session.
      await _vault.expire();
      return handler.next(error);
    }
    final tokens = sent == current ? await refresh() : _vault.tokens;
    if (tokens == null) return handler.next(error);
    try {
      options
        ..headers['Authorization'] = 'Bearer ${tokens.accessToken}'
        ..extra[_retried] = true;
      handler.resolve(await _plain.fetch<dynamic>(options));
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  /// Renews the token pair once, even if several requests ask at the same time.
  Future<AuthTokens?> refresh() =>
      _refreshing ??= _refresh().whenComplete(() => _refreshing = null);

  Future<AuthTokens?> _refresh() async {
    final current = _vault.tokens;
    if (current == null) return null;
    try {
      final response = await _plain.post<Json>(
        '/api/Auth/Refresh',
        data: {'refreshToken': current.refreshToken},
      );
      final tokens = AuthTokens.fromJson(response.data!);
      await _vault.save(tokens);
      return tokens;
    } on DioException catch (error) {
      final status = error.response?.statusCode;
      if (status == 401 || status == 400) await _vault.expire();
      return null;
    }
  }
}
