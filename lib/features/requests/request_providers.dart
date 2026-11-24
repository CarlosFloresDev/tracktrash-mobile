import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';
import '../../data/enums.dart';
import '../../data/models.dart';

/// Requests created by the signed-in user.
final myRequestsProvider = FutureProvider.autoDispose<List<CollectRequest>>((
  ref,
) async {
  final user = ref.watch(sessionProvider).user;
  if (user == null) return const [];
  final items = await ref.watch(apiProvider).requestsByUser(user.userId);
  return [...items]..sort((a, b) => b.id.compareTo(a.id));
});

/// Requests shown in "Solicitudes": every request for an admin, otherwise the user's own.
final visibleRequestsProvider =
    FutureProvider.autoDispose<List<CollectRequest>>((ref) async {
      final user = ref.watch(sessionProvider).user;
      if (user == null) return const [];
      if (user.role != UserRole.admin) {
        return ref.watch(myRequestsProvider.future);
      }
      final items = await ref.watch(apiProvider).allRequests();
      return [...items]..sort((a, b) => b.id.compareTo(a.id));
    });

/// Pending requests the signed-in gatherer can apply to. The backend filters them by the
/// materials the gatherer accepts and only serves them to verified gatherers.
final pendingRequestsProvider =
    FutureProvider.autoDispose<List<CollectRequest>>((ref) async {
      final gatherer = ref.watch(sessionProvider).gatherer;
      if (gatherer == null || !gatherer.canTakeRequests) return const [];
      final items = await ref.watch(apiProvider).pendingRequests();
      return [...items]..sort(
        (a, b) => '${a.scheduledDate}${a.scheduledTime}'.compareTo(
          '${b.scheduledDate}${b.scheduledTime}',
        ),
      );
    });

/// Materials of one request, for list tiles.
final requestDetailsProvider = FutureProvider.autoDispose
    .family<List<RequestDetail>, int>(
      (ref, id) => ref.watch(apiProvider).detailsOf(id),
    );

final requestFullProvider = FutureProvider.autoDispose
    .family<CollectRequestFull, int>(
      (ref, id) => ref.watch(apiProvider).requestFull(id),
    );

final requestHistoryProvider = FutureProvider.autoDispose
    .family<List<RequestHistory>, int>((ref, id) async {
      final items = await ref.watch(apiProvider).requestHistory(id);
      return [...items]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    });

final requesterProfileProvider = FutureProvider.autoDispose
    .family<RequesterProfile, int>(
      (ref, id) => ref.watch(apiProvider).requesterProfile(id),
    );

/// Applications received by a request (visible to its owner).
final applicationsProvider = FutureProvider.autoDispose
    .family<List<PickupApplication>, int>(
      (ref, id) => ref.watch(apiProvider).applicationsOf(id),
    );

/// Verified gatherers that accept every material of a request (visible to its owner).
final compatibleGatherersProvider = FutureProvider.autoDispose
    .family<List<Gatherer>, int>(
      (ref, id) => ref.watch(apiProvider).gatherersFor(id),
    );

/// Applications sent by the signed-in gatherer.
final myApplicationsProvider =
    FutureProvider.autoDispose<List<PickupApplication>>((ref) async {
      if (ref.watch(sessionProvider).gatherer == null) return const [];
      return ref.watch(apiProvider).myApplications();
    });

final gathererByIdProvider = FutureProvider.autoDispose.family<Gatherer, int>(
  (ref, id) => ref.watch(apiProvider).gathererById(id),
);

final serviceMaterialsProvider = FutureProvider.autoDispose
    .family<List<RecoveredMaterial>, int>(
      (ref, serviceId) => ref.watch(apiProvider).materialsByService(serviceId),
    );

typedef GradeKey = ({int serviceId, int userId});

final gradeProvider = FutureProvider.autoDispose.family<Grade?, GradeKey>(
  (ref, key) => ref.watch(apiProvider).gradeFor(key.serviceId, key.userId),
);

final _myServicesProvider = FutureProvider.autoDispose<List<PickupService>>((
  ref,
) async {
  final gatherer = ref.watch(sessionProvider).gatherer;
  if (gatherer == null) return const [];
  return ref.watch(apiProvider).servicesByGatherer(gatherer.gathererId);
});

/// Requests behind the services of the signed-in gatherer.
final gathererRequestsProvider =
    FutureProvider.autoDispose<List<CollectRequestFull>>((ref) async {
      final api = ref.watch(apiProvider);
      final services = await ref.watch(_myServicesProvider.future);
      final items = await Future.wait([
        for (final service in services)
          api.requestFull(service.collectRequestId),
      ]);
      return [...items]..sort((a, b) => b.request.id.compareTo(a.request.id));
    });

/// Kilograms recovered by the signed-in gatherer.
final gathererKilogramsProvider = FutureProvider.autoDispose<double>((
  ref,
) async {
  final api = ref.watch(apiProvider);
  final services = await ref.watch(_myServicesProvider.future);
  final materials = await Future.wait([
    for (final service in services) api.materialsByService(service.id),
  ]);
  return materials
      .expand((items) => items)
      .where((item) => item.unit.api == 'Kg')
      .fold<double>(0, (sum, item) => sum + item.quantity);
});

/// Average score of the signed-in gatherer, built from the grades linked to them.
final gathererRatingProvider = FutureProvider.autoDispose<GathererRating?>((
  ref,
) async {
  final gatherer = ref.watch(sessionProvider).gatherer;
  if (gatherer == null) return null;
  final api = ref.watch(apiProvider);
  final ids = await api.gradeIdsOfGatherer(gatherer.gathererId);
  if (ids.isEmpty) return null;
  final grades = await Future.wait([for (final id in ids) api.gradeById(id)]);
  return GathererRating(
    gathererId: gatherer.gathererId,
    averageScore:
        grades.fold<int>(0, (sum, grade) => sum + grade.score) / grades.length,
    totalGrades: grades.length,
  );
});

final generalIndicatorsProvider = FutureProvider.autoDispose<GeneralIndicators>(
  (ref) => ref.watch(apiProvider).generalIndicators(),
);
