import 'package:dio/dio.dart';
import '../core/api_failure.dart';
import 'auth_interceptor.dart';
import 'auth_tokens.dart';
import 'enums.dart';
import 'models.dart';

typedef RequestItem = ({
  int residueTypeId,
  double quantity,
  MeasurementUnit unit,
});

/// Contract with the TrackTrash backend. Screens depend on this interface, never on Dio.
abstract interface class TrackTrashApi {
  Future<AuthTokens> login(String email, String password);
  Future<void> logout(String refreshToken);

  /// Profile of the account behind the current access token.
  Future<User> me();
  Future<int> createUser({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required UserRole role,
    String? phone,
  });
  Future<void> updateUser(
    User user, {
    required String firstName,
    required String lastName,
    String? phone,
    int? locationId,
    bool? isActive,
  });
  Future<void> changePassword(int userId, String current, String next);

  /// Admin only.
  Future<List<User>> users();

  Future<int> createLocation({
    required String address,
    required String district,
    String? reference,
    double? latitude,
    double? longitude,
  });
  Future<List<Location>> locations();

  Future<List<CollectRequest>> requestsByUser(int userId);

  /// Admin only.
  Future<List<CollectRequest>> allRequests();

  /// Pending requests whose materials the signed-in gatherer accepts.
  Future<List<CollectRequest>> pendingRequests();
  Future<CollectRequestFull> requestFull(int id);
  Future<List<RequestDetail>> detailsOf(int requestId);
  Future<List<RequestHistory>> requestHistory(int id);
  Future<RequesterProfile> requesterProfile(int requestId);

  /// Creates the request together with its materials in one call.
  Future<int> createRequest({
    required int locationId,
    required DateTime date,
    required String time,
    required List<RequestItem> items,
    int? organizationId,
    String? observations,
  });
  Future<void> changeRequestStatus(
    int id,
    RequestStatus status, {
    int? byUserId,
    String? observations,
  });

  Future<List<PickupApplication>> applicationsOf(int requestId);
  Future<void> applyTo(int requestId);
  Future<void> acceptApplication(int requestId, int applicationId);
  Future<void> rejectApplication(int requestId, int applicationId);
  Future<List<PickupApplication>> myApplications();

  Future<List<PickupService>> servicesByGatherer(int gathererId);

  /// Admin only: assigns a gatherer directly, without an application.
  Future<void> assignGatherer({
    required int requestId,
    required int gathererId,
    required double commissionPercentage,
    required int byUserId,
  });
  Future<void> changeServiceStatus(
    int serviceId,
    RequestStatus status, {
    int? byUserId,
    String? observations,
  });

  Future<List<RecoveredMaterial>> materialsByService(int serviceId);
  Future<void> recordMaterial({
    required int serviceId,
    required int residueTypeId,
    required double quantity,
    required MeasurementUnit unit,
  });

  Future<Grade?> gradeFor(int serviceId, int userId);
  Future<Grade> gradeById(int gradeId);

  /// Ids of the grades a gatherer received.
  Future<List<int>> gradeIdsOfGatherer(int gathererId);
  Future<void> createGrade({
    required int serviceId,
    required int userId,
    required int score,
    String? comment,
  });

  Future<Gatherer?> gathererByUser(int userId);
  Future<Gatherer> gathererById(int gathererId);

  /// Verified gatherers that accept every material of the request.
  Future<List<Gatherer>> gatherersFor(int requestId);

  /// Admin only.
  Future<List<Gatherer>> gatherers();

  /// Admin only: verification and activation.
  Future<void> updateGatherer(
    Gatherer gatherer, {
    VerificationStatus? verification,
    bool? isActive,
  });
  Future<void> setMyResidueTypes(List<int> residueTypeIds);
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

  /// Admin only.
  Future<void> saveResidueType({
    int? id,
    required String name,
    required ResidueCategory category,
    required bool isRecyclable,
    required bool isActive,
    String? description,
    String? instructions,
  });
  Future<List<CollectionPoint>> collectionPoints();

  /// Admin only.
  Future<GeneralIndicators> generalIndicators();
}

class DioTrackTrashApi implements TrackTrashApi {
  DioTrackTrashApi(this._dio);
  final Dio _dio;

  static final _anonymous = Options(extra: {anonymous: true});

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
    () async => ((await _dio.get<List<dynamic>>('/api/$path')).data ?? const [])
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

  Future<int> _create(String path, Json body, [Options? options]) => _run(
    () async =>
        ((await _dio.post<dynamic>(
              '/api/$path',
              data: body,
              options: options,
            )).data)
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

  static String? _blankToNull(String? value) =>
      value == null || value.trim().isEmpty ? null : value.trim();

  @override
  Future<AuthTokens> login(String email, String password) => _run(
    () async => AuthTokens.fromJson(
      (await _dio.post<Json>(
        '/api/Auth/Login',
        data: {'email': email.trim().toLowerCase(), 'password': password},
        options: _anonymous,
      )).data!,
    ),
  );

  @override
  Future<void> logout(String refreshToken) => _run(
    () => _dio.post<dynamic>(
      '/api/Auth/Logout',
      data: {'refreshToken': refreshToken},
      options: _anonymous,
    ),
  );

  @override
  Future<User> me() async => User.fromJson(await _getMap('User/me'));

  @override
  Future<int> createUser({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required UserRole role,
    String? phone,
  }) => _create(
    'User',
    _clean({
      'firstName': firstName.trim(),
      'lastName': lastName.trim(),
      'email': email.trim().toLowerCase(),
      'password': password,
      'roleId': role.api,
      'phone': _blankToNull(phone),
    }),
    _anonymous,
  );

  @override
  Future<void> updateUser(
    User user, {
    required String firstName,
    required String lastName,
    String? phone,
    int? locationId,
    bool? isActive,
  }) => _send(
    'PUT',
    'User/${user.userId}',
    _clean({
      'firstName': firstName.trim(),
      'lastName': lastName.trim(),
      'phone': _blankToNull(phone),
      'roleId': user.role.api,
      'locationId': locationId ?? user.locationId,
      'isActive': isActive ?? user.isActive,
    }),
  );

  @override
  Future<List<User>> users() async => [
    for (final json in await _getList('User')) User.fromJson(json),
  ];

  @override
  Future<void> changePassword(int userId, String current, String next) => _send(
    'PUT',
    'User/$userId/password',
    {'currentPassword': current, 'newPassword': next},
  );

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
      'reference': _blankToNull(reference),
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
  Future<List<CollectRequest>> allRequests() async => [
    for (final json in await _getList('CollectRequest'))
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
  Future<List<RequestDetail>> detailsOf(int requestId) async => [
    for (final json in await _getList(
      'RequestDetail/collect-request/$requestId',
    ))
      RequestDetail.fromJson(json),
  ];

  @override
  Future<List<RequestHistory>> requestHistory(int id) async => [
    for (final json in await _getList('RequestHistory/collect-request/$id'))
      RequestHistory.fromJson(json),
  ];

  @override
  Future<RequesterProfile> requesterProfile(int requestId) async =>
      RequesterProfile.fromJson(
        await _getMap('CollectRequest/$requestId/requester-profile'),
      );

  @override
  Future<int> createRequest({
    required int locationId,
    required DateTime date,
    required String time,
    required List<RequestItem> items,
    int? organizationId,
    String? observations,
  }) => _create(
    'CollectRequest',
    _clean({
      'organizationId': organizationId,
      'locationId': locationId,
      'scheduledDate': _dateOnly(date),
      'scheduledTime': time.length == 5 ? '$time:00' : time,
      'observations': _blankToNull(observations),
      'details': [
        for (final item in items)
          {
            'residueTypeId': item.residueTypeId,
            'estimatedQuantity': item.quantity,
            'unitId': item.unit.api,
          },
      ],
    }),
  );

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
  Future<List<PickupApplication>> applicationsOf(int requestId) async => [
    for (final json in await _getList('CollectRequest/$requestId/applications'))
      PickupApplication.fromJson(json),
  ];

  @override
  Future<void> applyTo(int requestId) =>
      _send('POST', 'CollectRequest/$requestId/applications');

  @override
  Future<void> acceptApplication(int requestId, int applicationId) => _send(
    'POST',
    'CollectRequest/$requestId/applications/$applicationId/accept',
  );

  @override
  Future<void> rejectApplication(int requestId, int applicationId) => _send(
    'POST',
    'CollectRequest/$requestId/applications/$applicationId/reject',
  );

  @override
  Future<List<PickupApplication>> myApplications() async => [
    for (final json in await _getList('Gatherer/me/applications'))
      PickupApplication.fromJson(json),
  ];

  @override
  Future<List<PickupService>> servicesByGatherer(int gathererId) async => [
    for (final json in await _getList('PickupService/gatherer/$gathererId'))
      PickupService.fromJson(json),
  ];

  @override
  Future<void> assignGatherer({
    required int requestId,
    required int gathererId,
    required double commissionPercentage,
    required int byUserId,
  }) => _create('PickupService', {
    'collectRequestId': requestId,
    'gathererId': gathererId,
    'commissionPercentage': commissionPercentage,
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
  Future<Grade> gradeById(int gradeId) async =>
      Grade.fromJson(await _getMap('Grade/$gradeId'));

  @override
  Future<List<int>> gradeIdsOfGatherer(int gathererId) async => [
    for (final json in await _getList('GathererGrade/gatherer/$gathererId'))
      json['gradeId'] as int,
  ];

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
      'comment': _blankToNull(comment),
    }),
  );

  @override
  Future<Gatherer?> gathererByUser(int userId) =>
      _getOrNull('Gatherer/user/$userId', Gatherer.fromJson);

  @override
  Future<Gatherer> gathererById(int gathererId) async =>
      Gatherer.fromJson(await _getMap('Gatherer/$gathererId'));

  @override
  Future<List<Gatherer>> gatherersFor(int requestId) async => [
    for (final json in await _getList(
      'Gatherer/available/collect-request/$requestId',
    ))
      Gatherer.fromJson(json),
  ];

  @override
  Future<List<Gatherer>> gatherers() async => [
    for (final json in await _getList('Gatherer')) Gatherer.fromJson(json),
  ];

  @override
  Future<void> updateGatherer(
    Gatherer gatherer, {
    VerificationStatus? verification,
    bool? isActive,
  }) => _send('PUT', 'Gatherer/${gatherer.gathererId}', {
    'gathererId': gatherer.gathererId,
    'gathererTypeId': gatherer.type.api,
    'description': gatherer.description,
    'verificationDocument': gatherer.verificationDocument,
    'verificationStatusId': (verification ?? gatherer.verification).api,
    'isActive': isActive ?? gatherer.isActive,
  });

  @override
  Future<void> setMyResidueTypes(List<int> residueTypeIds) => _send(
    'PUT',
    'Gatherer/me/residue-types',
    {'residueTypeIds': residueTypeIds},
  );

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
      'taxId': _blankToNull(taxId),
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
  Future<void> saveResidueType({
    int? id,
    required String name,
    required ResidueCategory category,
    required bool isRecyclable,
    required bool isActive,
    String? description,
    String? instructions,
  }) {
    final body = <String, dynamic>{
      'name': name.trim(),
      'residueCategoryId': category.api,
      'isRecyclable': isRecyclable,
      'description': _blankToNull(description),
      'classificationInstructions': _blankToNull(instructions),
    };
    if (id == null) return _create('ResidueType', _clean(body));
    return _send('PUT', 'ResidueType/$id', {
      ...body,
      'residueTypeId': id,
      'isActive': isActive,
    });
  }

  @override
  Future<List<CollectionPoint>> collectionPoints() async => [
    for (final json in await _getList('CollectionPoint'))
      CollectionPoint.fromJson(json),
  ];

  @override
  Future<GeneralIndicators> generalIndicators() async =>
      GeneralIndicators.fromJson(await _getMap('Indicator/general'));
}

String _dateOnly(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
