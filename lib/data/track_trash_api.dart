import 'package:dio/dio.dart';
import '../core/api_failure.dart';
import 'enums.dart';
import 'models.dart';

/// Contract with the TrackTrash backend. Screens depend on this interface, never on Dio.
abstract interface class TrackTrashApi {
  Future<User> userByEmail(String email);
  Future<User> userById(int id);
  Future<int> createUser({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required UserRole role,
    String? phone,
    int? locationId,
  });
  Future<void> updateUser(
    User user, {
    required String firstName,
    required String lastName,
    String? phone,
  });
  Future<void> changePassword(int userId, String current, String next);

  Future<int> createLocation({
    required String address,
    required String district,
    String? reference,
    double? latitude,
    double? longitude,
  });
  Future<List<Location>> locations();

  Future<List<CollectRequest>> requestsByUser(int userId);
  Future<List<CollectRequest>> pendingRequests();
  Future<CollectRequestFull> requestFull(int id);
  Future<List<RequestHistory>> requestHistory(int id);
  Future<int> createRequest({
    required int userId,
    required int locationId,
    required DateTime date,
    required String time,
    int? organizationId,
    String? observations,
  });
  Future<void> createRequestDetail({
    required int requestId,
    required int residueTypeId,
    required double quantity,
    required MeasurementUnit unit,
  });
  Future<void> changeRequestStatus(
    int id,
    RequestStatus status, {
    int? byUserId,
    String? observations,
  });
  Future<List<RequestDetail>> requestDetails();

  Future<List<PickupService>> servicesByGatherer(int gathererId);
  Future<int> takeRequest({
    required int requestId,
    required int gathererId,
    required int byUserId,
  });
  Future<void> changeServiceStatus(
    int serviceId,
    RequestStatus status, {
    int? byUserId,
    String? observations,
  });

  Future<List<RecoveredMaterial>> materialsByService(int serviceId);
  Future<List<RecoveredMaterial>> allMaterials();
  Future<void> recordMaterial({
    required int serviceId,
    required int residueTypeId,
    required double quantity,
    required MeasurementUnit unit,
  });

  Future<Grade?> gradeFor(int serviceId, int userId);
  Future<void> createGrade({
    required int serviceId,
    required int userId,
    required int score,
    String? comment,
  });

  Future<Gatherer?> gathererByUser(int userId);
  Future<List<Gatherer>> gatherers();
  Future<void> createGatherer({
    required int userId,
    required GathererType type,
    String? description,
    String? document,
  });
  Future<Organization?> organizationByUser(int userId);
  Future<void> createOrganization({
    required int userId,
    required String businessName,
    required OrganizationType type,
    String? taxId,
    int? locationId,
  });

  Future<List<ResidueType>> residueTypes();
  Future<List<CollectionPoint>> collectionPoints();
  Future<GeneralIndicators> generalIndicators();
  Future<List<GathererRating>> gathererRatings();
}

/// Commission applied when a gatherer takes a request on their own.
/// The business rule belongs to the backend; see docs in the web repository.
const defaultCommissionPercentage = 10;

class DioTrackTrashApi implements TrackTrashApi {
  DioTrackTrashApi(this._dio);
  final Dio _dio;

  Future<T> _run<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on DioException catch (error) {
      throw ApiFailure.fromDio(error);
    }
  }

  Future<Json> _getMap(String path) =>
      _run(() async => (await _dio.get<Json>('/api/$path')).data!);

  Future<List<Json>> _getList(String path) => _run(
    () async =>
        ((await _dio.get<List<dynamic>>('/api/$path')).data ?? const [])
            .cast<Json>(),
  );

  Future<T?> _getOrNull<T>(String path, T Function(Json) parse) async {
    try {
      return parse(await _getMap(path));
    } on ApiFailure catch (failure) {
      if (failure.isNotFound) return null;
      rethrow;
    }
  }

  Future<int> _create(String path, Json body) => _run(
    () async => ((await _dio.post<dynamic>('/api/$path', data: body)).data)
        as int,
  );

  Future<void> _send(String method, String path, [Json? body]) => _run(
    () => _dio.request<dynamic>(
      '/api/$path',
      data: body,
      options: Options(method: method),
    ),
  );

  static Json _clean(Json body) =>
      body..removeWhere((_, value) => value == null);

  @override
  Future<User> userByEmail(String email) async => User.fromJson(
    await _getMap('User/email/${Uri.encodeComponent(email.trim().toLowerCase())}'),
  );

  @override
  Future<User> userById(int id) async =>
      User.fromJson(await _getMap('User/$id'));

  @override
  Future<int> createUser({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required UserRole role,
    String? phone,
    int? locationId,
  }) => _create(
    'User',
    _clean({
      'firstName': firstName.trim(),
      'lastName': lastName.trim(),
      'email': email.trim().toLowerCase(),
      'password': password,
      'roleId': role.api,
      'phone': phone == null || phone.trim().isEmpty ? null : phone.trim(),
      'locationId': locationId,
    }),
  );

  @override
  Future<void> updateUser(
    User user, {
    required String firstName,
    required String lastName,
    String? phone,
  }) => _send(
    'PUT',
    'User/${user.userId}',
    _clean({
      'firstName': firstName.trim(),
      'lastName': lastName.trim(),
      'phone': phone == null || phone.trim().isEmpty ? null : phone.trim(),
      'roleId': user.role.api,
      'locationId': user.locationId,
      'isActive': user.isActive,
    }),
  );

  @override
  Future<void> changePassword(int userId, String current, String next) =>
      _send('PUT', 'User/$userId/password', {
        'currentPassword': current,
        'newPassword': next,
      });

  @override
  Future<int> createLocation({
    required String address,
    required String district,
    String? reference,
    double? latitude,
    double? longitude,
  }) => _create(
    'Location',
    _clean({
      'address': address.trim(),
      'district': district.trim(),
      'reference': reference == null || reference.trim().isEmpty
          ? null
          : reference.trim(),
      'province': 'Arequipa',
      'department': 'Arequipa',
      'latitude': latitude,
      'longitude': longitude,
    }),
  );

  @override
  Future<List<Location>> locations() async => [
    for (final json in await _getList('Location')) Location.fromJson(json),
  ];

  @override
  Future<List<CollectRequest>> requestsByUser(int userId) async => [
    for (final json in await _getList('CollectRequest/user/$userId'))
      CollectRequest.fromJson(json),
  ];

  @override
  Future<List<CollectRequest>> pendingRequests() async => [
    for (final json in await _getList('CollectRequest/pending'))
      CollectRequest.fromJson(json),
  ];

  @override
  Future<CollectRequestFull> requestFull(int id) async =>
      CollectRequestFull.fromJson(await _getMap('CollectRequest/$id/full'));

  @override
  Future<List<RequestHistory>> requestHistory(int id) async => [
    for (final json in await _getList('RequestHistory/collect-request/$id'))
      RequestHistory.fromJson(json),
  ];

  @override
  Future<int> createRequest({
    required int userId,
    required int locationId,
    required DateTime date,
    required String time,
    int? organizationId,
    String? observations,
  }) => _create(
    'CollectRequest',
    _clean({
      'userId': userId,
      'organizationId': organizationId,
      'locationId': locationId,
      'scheduledDate': _dateOnly(date),
      'scheduledTime': time.length == 5 ? '$time:00' : time,
      'observations': observations == null || observations.trim().isEmpty
          ? null
          : observations.trim(),
    }),
  );

  @override
  Future<void> createRequestDetail({
    required int requestId,
    required int residueTypeId,
    required double quantity,
    required MeasurementUnit unit,
  }) => _create('RequestDetail', {
    'collectRequestId': requestId,
    'residueTypeId': residueTypeId,
    'estimatedQuantity': quantity,
    'unitId': unit.api,
  });

  @override
  Future<void> changeRequestStatus(
    int id,
    RequestStatus status, {
    int? byUserId,
    String? observations,
  }) => _send(
    'PATCH',
    'CollectRequest/$id/status',
    _clean({
      'newStatusId': status.api,
      'changedByUserId': byUserId,
      'observations': observations,
    }),
  );

  @override
  Future<List<RequestDetail>> requestDetails() async => [
    for (final json in await _getList('RequestDetail'))
      RequestDetail.fromJson(json),
  ];

  @override
  Future<List<PickupService>> servicesByGatherer(int gathererId) async => [
    for (final json in await _getList('PickupService/gatherer/$gathererId'))
      PickupService.fromJson(json),
  ];

  @override
  Future<int> takeRequest({
    required int requestId,
    required int gathererId,
    required int byUserId,
  }) => _create('PickupService', {
    'collectRequestId': requestId,
    'gathererId': gathererId,
    'commissionPercentage': defaultCommissionPercentage,
    'assignedByUserId': byUserId,
  });

  @override
  Future<void> changeServiceStatus(
    int serviceId,
    RequestStatus status, {
    int? byUserId,
    String? observations,
  }) => _send(
    'PATCH',
    'PickupService/$serviceId/status',
    _clean({
      'newStatusId': status.api,
      'changedByUserId': byUserId,
      'observations': observations,
    }),
  );

  @override
  Future<List<RecoveredMaterial>> materialsByService(int serviceId) async => [
    for (final json in await _getList(
      'RecoveredMaterial/pickup-service/$serviceId',
    ))
      RecoveredMaterial.fromJson(json),
  ];

  @override
  Future<List<RecoveredMaterial>> allMaterials() async => [
    for (final json in await _getList('RecoveredMaterial'))
      RecoveredMaterial.fromJson(json),
  ];

  @override
  Future<void> recordMaterial({
    required int serviceId,
    required int residueTypeId,
    required double quantity,
    required MeasurementUnit unit,
  }) => _create('RecoveredMaterial', {
    'pickupServiceId': serviceId,
    'residueTypeId': residueTypeId,
    'quantity': quantity,
    'unitId': unit.api,
  });

  @override
  Future<Grade?> gradeFor(int serviceId, int userId) => _getOrNull(
    'Grade/pickup-service/$serviceId/user/$userId',
    Grade.fromJson,
  );

  @override
  Future<void> createGrade({
    required int serviceId,
    required int userId,
    required int score,
    String? comment,
  }) => _create(
    'Grade',
    _clean({
      'pickupServiceId': serviceId,
      'userId': userId,
      'score': score,
      'comment': comment == null || comment.trim().isEmpty
          ? null
          : comment.trim(),
    }),
  );

  @override
  Future<Gatherer?> gathererByUser(int userId) =>
      _getOrNull('Gatherer/user/$userId', Gatherer.fromJson);

  @override
  Future<List<Gatherer>> gatherers() async => [
    for (final json in await _getList('Gatherer')) Gatherer.fromJson(json),
  ];

  @override
  Future<void> createGatherer({
    required int userId,
    required GathererType type,
    String? description,
    String? document,
  }) => _create(
    'Gatherer',
    _clean({
      'userId': userId,
      'gathererTypeId': type.api,
      'description': description,
      'verificationDocument': document,
    }),
  );

  @override
  Future<Organization?> organizationByUser(int userId) =>
      _getOrNull('Organization/user/$userId', Organization.fromJson);

  @override
  Future<void> createOrganization({
    required int userId,
    required String businessName,
    required OrganizationType type,
    String? taxId,
    int? locationId,
  }) => _create(
    'Organization',
    _clean({
      'userId': userId,
      'businessName': businessName.trim(),
      'taxId': taxId == null || taxId.trim().isEmpty ? null : taxId.trim(),
      'organizationTypeId': type.api,
      'locationId': locationId,
      'subscriptionPlanId': 'Basic',
    }),
  );

  @override
  Future<List<ResidueType>> residueTypes() async => [
    for (final json in await _getList('ResidueType'))
      ResidueType.fromJson(json),
  ];

  @override
  Future<List<CollectionPoint>> collectionPoints() async => [
    for (final json in await _getList('CollectionPoint'))
      CollectionPoint.fromJson(json),
  ];

  @override
  Future<GeneralIndicators> generalIndicators() async =>
      GeneralIndicators.fromJson(await _getMap('Indicator/general'));

  @override
  Future<List<GathererRating>> gathererRatings() async => [
    for (final json in await _getList('Indicator/gatherer-ratings'))
      GathererRating.fromJson(json),
  ];
}

String _dateOnly(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
