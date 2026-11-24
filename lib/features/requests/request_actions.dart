import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';
import '../../data/enums.dart';
import '../../data/models.dart';
import '../../data/track_trash_api.dart';
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
      ..invalidate(requestDetailsProvider)
      ..invalidate(myApplicationsProvider)
      ..invalidate(gathererRequestsProvider)
      ..invalidate(gathererKilogramsProvider)
      ..invalidate(gathererRatingProvider)
      ..invalidate(generalIndicatorsProvider);
    if (requestId != null) {
      _ref
        ..invalidate(requestFullProvider(requestId))
        ..invalidate(requestHistoryProvider(requestId))
        ..invalidate(applicationsProvider(requestId))
        ..invalidate(compatibleGatherersProvider(requestId));
    }
  }

  User get _user => _ref.read(sessionProvider).user!;

  /// Creates the request with its materials (and a new address when needed). Returns the new id.
  Future<int> create({
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
    required List<RequestItem> items,
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
      organizationId: _ref.read(sessionProvider).organization?.organizationId,
      locationId: resolvedLocation,
      date: date,
      time: time,
      observations: observations,
      items: items,
    );
    _refresh(id);
    return id;
  }

  /// Cancels a request. An administrator releases an active service first, which returns
  /// the request to Pending; owners can only cancel while no gatherer holds it.
  Future<void> cancel(CollectRequestFull full, {String? reason}) async {
    final api = _ref.read(apiProvider);
    final service = full.service;
    if (_user.role == UserRole.admin &&
        service != null &&
        service.status.isActive) {
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

  /// Sends the signed-in gatherer's application; the requester decides who takes the pickup.
  Future<void> apply(int requestId) async {
    await _ref.read(apiProvider).applyTo(requestId);
    _refresh(requestId);
  }

  /// Admin only: assigns a gatherer without waiting for an application.
  Future<void> assign(
    int requestId,
    Gatherer gatherer,
    double commission,
  ) async {
    await _ref
        .read(apiProvider)
        .assignGatherer(
          requestId: requestId,
          gathererId: gatherer.gathererId,
          commissionPercentage: commission,
          byUserId: _user.userId,
        );
    _refresh(requestId);
  }

  Future<void> accept(PickupApplication application) async {
    await _ref
        .read(apiProvider)
        .acceptApplication(application.collectRequestId, application.id);
    _refresh(application.collectRequestId);
  }

  Future<void> reject(PickupApplication application) async {
    await _ref
        .read(apiProvider)
        .rejectApplication(application.collectRequestId, application.id);
    _refresh(application.collectRequestId);
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
