import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracktrash_mobile/core/api_failure.dart';
import 'package:tracktrash_mobile/data/enums.dart';
import 'package:tracktrash_mobile/data/models.dart';
import 'package:tracktrash_mobile/data/track_trash_api.dart';

/// Shape captured from `GET /api/CollectRequest/{id}/full` on the real backend.
const _full = {
  'request': {
    'collectRequestId': 7,
    'userId': 3,
    'organizationId': null,
    'locationId': 3,
    'requestedAt': '2026-11-23T06:25:36.171311Z',
    'scheduledDate': '2026-11-28',
    'scheduledTime': '09:30:00',
    'statusId': 'Completed',
    'observations': null,
    'updatedAt': '2026-11-23T06:25:36.236018Z',
  },
  'location': {
    'locationId': 3,
    'address': 'Av. Cayma 1020',
    'reference': 'Costado del mercado',
    'district': 'Cayma',
    'province': 'Arequipa',
    'department': 'Arequipa',
    'latitude': -16.3665000,
    'longitude': -71.5456,
    'createdAt': '2026-11-23T06:25:34.786365Z',
  },
  'details': [
    {
      'requestDetailId': 12,
      'collectRequestId': 7,
      'residueTypeId': 5,
      'estimatedQuantity': 6.00,
      'unitId': 'Kg',
      'observations': null,
    },
  ],
  'pickupService': {
    'pickupServiceId': 3,
    'collectRequestId': 7,
    'gathererId': 3,
    'assignedAt': '2026-11-23T06:25:36.181736Z',
    'startedAt': '2026-11-23T06:25:36.187733Z',
    'completedAt': null,
    'statusId': 'InProgress',
    'commissionPercentage': 10.00,
    'observations': null,
  },
};

void main() {
  group('models', () {
    test('parse the full request payload of the backend', () {
      final full = CollectRequestFull.fromJson(_full);
      expect(full.request.status, RequestStatus.completed);
      expect(full.request.timeLabel, '09:30');
      expect(full.request.scheduledDate, DateTime(2026, 11, 28));
      expect(full.location.hasCoordinates, isTrue);
      expect(full.location.summary, 'Av. Cayma 1020, Cayma');
      expect(full.details.single.quantity, 6.0);
      expect(full.details.single.unit, MeasurementUnit.kg);
      expect(full.service?.status, RequestStatus.inProgress);
      expect(full.service?.completedAt, isNull);
    });

    test('accept integer decimals and a missing pickup service', () {
      final json = {
        ..._full,
        'pickupService': null,
        'details': [
          {
            ...(_full['details'] as List).first as Map<String, dynamic>,
            'estimatedQuantity': 6,
          },
        ],
      };
      final full = CollectRequestFull.fromJson(json);
      expect(full.service, isNull);
      expect(full.details.single.quantity, 6.0);
    });

    test('user helpers', () {
      final user = User.fromJson({
        'userId': 1,
        'firstName': 'Lucia',
        'lastName': 'Mamani',
        'email': 'lucia@correo.pe',
        'phone': null,
        'roleId': 'Gatherer',
        'locationId': null,
        'isActive': true,
      });
      expect(user.fullName, 'Lucia Mamani');
      expect(user.initials, 'LM');
      expect(user.role, UserRole.gatherer);
    });
  });

  group('status rules', () {
    test('mirror the backend transitions', () {
      expect(RequestStatus.pending.next, [
        RequestStatus.assigned,
        RequestStatus.cancelled,
      ]);
      expect(RequestStatus.inProgress.next, contains(RequestStatus.completed));
      expect(RequestStatus.completed.next, isEmpty);
      expect(RequestStatus.cancelled.isFinal, isTrue);
      expect(RequestStatus.assigned.isActive, isTrue);
    });

    test('unknown API values fall back safely', () {
      expect(RequestStatus.parse('Unknown'), RequestStatus.pending);
      expect(UserRole.parse('Unknown'), UserRole.generator);
    });
  });

  group('ApiFailure', () {
    DioException failure(int status, Object? data) => DioException(
      requestOptions: RequestOptions(path: '/x'),
      response: Response(
        requestOptions: RequestOptions(path: '/x'),
        statusCode: status,
        data: data,
      ),
    );

    test('reads the { error } shape', () {
      final result = ApiFailure.fromDio(
        failure(400, {'error': 'Email is already registered.'}),
      );
      expect(result.message, 'Email is already registered.');
      expect(result.statusCode, 400);
    });

    test('flattens validation errors', () {
      final result = ApiFailure.fromDio(
        failure(400, {
          'errors': {
            'Email': ['Not valid.'],
            'Password': ['Too short.'],
          },
        }),
      );
      expect(result.message, 'Not valid.\nToo short.');
    });

    test('hides server error details on 5xx', () {
      final result = ApiFailure.fromDio(
        failure(500, {'error': 'An unexpected error occurred.'}),
      );
      expect(result.message, contains('servidor'));
    });

    test('reports connectivity problems without a response', () {
      final result = ApiFailure.fromDio(
        DioException(requestOptions: RequestOptions(path: '/x')),
      );
      expect(result.message, contains('conectar'));
    });
  });

  group('DioTrackTrashApi', () {
    Dio dioReturning(int status, Object? data) {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) => status < 400
              ? handler.resolve(
                  Response(
                    requestOptions: options,
                    statusCode: status,
                    data: data,
                  ),
                )
              : handler.reject(
                  DioException(
                    requestOptions: options,
                    type: DioExceptionType.badResponse,
                    response: Response(
                      requestOptions: options,
                      statusCode: status,
                      data: data,
                    ),
                  ),
                ),
        ),
      );
      return dio;
    }

    test('a missing profile is null, not an error', () async {
      final api = DioTrackTrashApi(
        dioReturning(404, {'error': 'Gatherer not found.'}),
      );
      expect(await api.gathererByUser(99), isNull);
    });

    test('other failures still surface', () async {
      final api = DioTrackTrashApi(dioReturning(500, {'error': 'x'}));
      expect(api.gathererByUser(1), throwsA(isA<ApiFailure>()));
    });

    test('lists are parsed into models', () async {
      final api = DioTrackTrashApi(
        dioReturning(200, [
          {
            'residueTypeId': 1,
            'name': 'Vidrio',
            'residueCategoryId': 'Recyclable',
            'description': null,
            'isRecyclable': true,
            'classificationInstructions': 'Separar por color.',
            'isActive': true,
            'createdAt': '2026-11-23T06:25:35Z',
          },
        ]),
      );
      final types = await api.residueTypes();
      expect(types.single.name, 'Vidrio');
      expect(types.single.category, ResidueCategory.recyclable);
    });
  });
}
