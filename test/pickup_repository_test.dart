import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracktrash_mobile/core/api_failure.dart';
import 'package:tracktrash_mobile/features/pickups/data/pickup_repository.dart';
import 'package:tracktrash_mobile/features/pickups/domain/pickup.dart';

class StubAdapter implements HttpClientAdapter {
  RequestOptions? request;
  int status = 200;
  Object payload = <Object>[];
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    request = options;
    return ResponseBody.fromString(
      jsonEncode(payload),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test(
    'envía identidad y página; admite campos privados ocultos por la API',
    () async {
      final adapter = StubAdapter()
        ..payload = [
          {
            'id': 'test-1',
            'material': 'Vidrio',
            'cantidadEstimadaKg': 2,
            'programadaPara': '2026-10-24T12:00:00Z',
            'estado': 'Pendiente',
            'direccion': null,
            'codigoConfirmacion': null,
          },
        ];
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
        ..httpClientAdapter = adapter;
      addTearDown(dio.close);
      final result = await ApiPickupRepository(dio, 'test-token').list(page: 2);
      expect(adapter.request!.headers['Authorization'], 'Bearer test-token');
      expect(adapter.request!.queryParameters['pagina'], 2);
      expect(result.single.address, isNull);
      expect(result.single.materialLabel, 'Vidrio');
    },
  );

  test(
    'traduce ProblemDetails y no devuelve un éxito cuando falla el servidor',
    () async {
      final adapter = StubAdapter()
        ..status = 409
        ..payload = {'title': 'La solicitud cambió'};
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
        ..httpClientAdapter = adapter;
      addTearDown(dio.close);
      await expectLater(
        ApiPickupRepository(dio, 'test').accept('1'),
        throwsA(
          isA<ApiFailure>().having(
            (e) => e.message,
            'mensaje',
            'La solicitud cambió',
          ),
        ),
      );
    },
  );

  test('serializa la fecha en UTC y conserva la clave de idempotencia', () {
    final draft = PickupDraft(
      key: 'key-1',
      material: RecyclableMaterial.metal,
      kg: 1,
      address: '  Av. Arequipa 123  ',
      scheduledAt: DateTime.parse('2026-10-24T10:30:00-05:00'),
    );
    expect(draft.toJson()['programadaPara'], '2026-10-24T15:30:00.000Z');
    expect(draft.toJson()['claveSolicitud'], 'key-1');
    expect(draft.toJson()['direccion'], 'Av. Arequipa 123');
  });
}
