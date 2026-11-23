import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';
import '../../data/enums.dart';
import '../../data/models.dart';
import 'request_providers.dart';

/// Write operations on requests and services. Each one refreshes every list that can show the result,
/// because the backend changes requests, services and indicators together.
class RequestActions {
  RequestActions(this._ref);
  final Ref _ref;

  void _refresh([int? requestId]) {
    _ref
      ..invalidate(myRequestsProvider)
      ..invalidate(pendingRequestsProvider)
      ..invalidate(detailsByRequestProvider)
      ..invalidate(gathererRequestsProvider)
      ..invalidate(gathererKilogramsProvider)
      ..invalidate(gathererRatingProvider)
      ..invalidate(generalIndicatorsProvider);
    if (requestId != null) {
      _ref
        ..invalidate(requestFullProvider(requestId))
        ..invalidate(requestHistoryProvider(requestId));
    }
  }

  User get _user => _ref.read(sessionProvider).user!;

  /// Creates the request, then its materials one by one: the backend has no "create with details" endpoint.
  /// Returns the new id and how many materials could not be saved.
  Future<({int id, int failedDetails})> create({
    required int? locationId,
    required ({
      String address,
      String district,
      String? reference,
      double? latitude,
      double? longitude,
    })?
    newLocation,
    required DateTime date,
    required String time,
    required String? observations,
    required List<({int residueTypeId, double quantity, MeasurementUnit unit})>
    items,
  }) async {
    final api = _ref.read(apiProvider);
    var resolvedLocation = locationId;
    if (newLocation != null || resolvedLocation == null) {
      final data = newLocation!;
      resolvedLocation = await api.createLocation(
        address: data.address,
        district: data.district,
        reference: data.reference,
        latitude: data.latitude,
        longitude: data.longitude,
      );
      _ref.invalidate(locationsProvider);
    }
    final id = await api.createRequest(
      userId: _user.userId,
      organizationId: _ref.read(sessionProvider).organization?.organizationId,
      locationId: resolvedLocation,
      date: date,
      time: time,
      observations: observations,
    );
    final results = await Future.wait([
      for (final item in items)
        api
            .createRequestDetail(
              requestId: id,
              residueTypeId: item.residueTypeId,
              quantity: item.quantity,
              unit: item.unit,
            )
            .then((_) => true, onError: (Object _) => false),
    ]);
    _refresh(id);
    return (id: id, failedDetails: results.where((ok) => !ok).length);
  }

  /// Cancels a request. An active service is released first: the backend then returns the request
  /// to Pending, from where it can be cancelled.
  Future<void> cancel(CollectRequestFull full, {String? reason}) async {
    final api = _ref.read(apiProvider);
    final service = full.service;
    if (service != null && service.status.isActive) {
      await api.changeServiceStatus(
        service.id,
        RequestStatus.cancelled,
        byUserId: _user.userId,
        observations: reason,
      );
    }
    await api.changeRequestStatus(
      full.request.id,
      RequestStatus.cancelled,
      byUserId: _user.userId,
      observations: reason,
    );
    _refresh(full.request.id);
  }

  Future<void> take(int requestId) async {
    final gatherer = _ref.read(sessionProvider).gatherer!;
    await _ref
        .read(apiProvider)
        .takeRequest(
          requestId: requestId,
          gathererId: gatherer.gathererId,
          byUserId: _user.userId,
        );
    _refresh(requestId);
  }

  Future<void> changeService(
    CollectRequestFull full,
    RequestStatus status, {
    String? reason,
  }) async {
    await _ref
        .read(apiProvider)
        .changeServiceStatus(
          full.service!.id,
          status,
          byUserId: _user.userId,
          observations: reason,
        );
    _refresh(full.request.id);
  }

  Future<void> recordMaterial(
    CollectRequestFull full, {
    required int residueTypeId,
    required double quantity,
    required MeasurementUnit unit,
  }) async {
    await _ref
        .read(apiProvider)
        .recordMaterial(
          serviceId: full.service!.id,
          residueTypeId: residueTypeId,
          quantity: quantity,
          unit: unit,
        );
    _ref.invalidate(serviceMaterialsProvider(full.service!.id));
    _refresh(full.request.id);
  }

  Future<void> rate(
    CollectRequestFull full, {
    required int score,
    String? comment,
  }) async {
    await _ref
        .read(apiProvider)
        .createGrade(
          serviceId: full.service!.id,
          userId: _user.userId,
          score: score,
          comment: comment,
        );
    _ref.invalidate(
      gradeProvider((serviceId: full.service!.id, userId: _user.userId)),
    );
    _refresh(full.request.id);
  }
}

final requestActionsProvider = Provider<RequestActions>(RequestActions.new);
