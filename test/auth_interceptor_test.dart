import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracktrash_mobile/data/auth_interceptor.dart';
import 'package:tracktrash_mobile/data/auth_tokens.dart';

import 'support/fakes.dart';

/// Answers every request with [status] and [body], recording the Authorization header it saw.
class FakeBackend implements HttpClientAdapter {
  FakeBackend(this.respond);
  final ResponseBody Function(RequestOptions options) respond;
  final seen = <String?>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    seen.add(options.headers['Authorization'] as String?);
    return respond(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody json(int status, String body) => ResponseBody.fromString(
  body,
  status,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

({Dio dio, TokenVault vault, FakeBackend backend}) build(FakeBackend backend) {
  final vault = TokenVault(MemorySessionStorage());
  final plain = Dio()..httpClientAdapter = backend;
  final dio = Dio()
    ..httpClientAdapter = backend
    ..interceptors.add(AuthInterceptor(vault, plain));
  return (dio: dio, vault: vault, backend: backend);
}

void main() {
  test('adds the Bearer token', () async {
    final s = build(FakeBackend((_) => json(200, '{}')));
    await s.vault.save(fakeTokens('abc'));
    await s.dio.get<dynamic>('http://api/x');
    expect(s.backend.seen.single, 'Bearer abc');
  });

  test('a business 401 keeps the session', () async {
    final s = build(
      FakeBackend(
        (_) =>
            json(401, '{"error":"Only active, verified gatherers can apply."}'),
      ),
    );
    await s.vault.save(fakeTokens('abc'));
    var expired = false;
    s.vault.onExpired.listen((_) => expired = true);
    await expectLater(
      s.dio.post<dynamic>('http://api/apply'),
      throwsA(isA<DioException>()),
    );
    await Future<void>.delayed(Duration.zero);
    expect(expired, isFalse);
    expect(s.vault.tokens?.accessToken, 'abc');
  });

  test('a rejected token ends the session', () async {
    final s = build(FakeBackend((_) => json(401, '')));
    await s.vault.save(fakeTokens('abc'));
    var expired = false;
    s.vault.onExpired.listen((_) => expired = true);
    await expectLater(
      s.dio.get<dynamic>('http://api/me'),
      throwsA(isA<DioException>()),
    );
    await Future<void>.delayed(Duration.zero);
    expect(expired, isTrue);
    expect(s.vault.tokens, isNull);
  });

  test('an expired access token is refreshed and the call retried', () async {
    var calls = 0;
    final s = build(
      FakeBackend((options) {
        if (options.path.endsWith('/api/Auth/Refresh')) {
          final next = DateTime.now().toUtc().add(const Duration(hours: 4));
          return json(
            200,
            '{"accessToken":"new","refreshToken":"r2","expiresAt":"${next.toIso8601String()}"}',
          );
        }
        calls++;
        return calls == 1
            ? json(401, '{"code":"ACCESS_TOKEN_EXPIRED","error":"expired"}')
            : json(200, '{"ok":true}');
      }),
    );
    await s.vault.save(fakeTokens('old'));
    final response = await s.dio.get<dynamic>('http://api/api/User/me');
    expect(response.statusCode, 200);
    expect(s.vault.tokens?.accessToken, 'new');
    expect(s.backend.seen.last, 'Bearer new');
  });
}
