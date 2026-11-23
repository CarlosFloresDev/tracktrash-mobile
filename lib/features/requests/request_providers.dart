import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';
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

/// Pending requests that still have no gatherer.
final pendingRequestsProvider =
    FutureProvider.autoDispose<List<CollectRequest>>((ref) async {
      final items = await ref.watch(apiProvider).pendingRequests();
      return [...items]..sort(
        (a, b) => '${a.scheduledDate}${a.scheduledTime}'.compareTo(
          '${b.scheduledDate}${b.scheduledTime}',
        ),
      );
    });

/// Every request detail, grouped by request. The backend has no per-list summary,
/// so list screens read the materials from here.
final detailsByRequestProvider =
    FutureProvider.autoDispose<Map<int, List<RequestDetail>>>((ref) async {
      final details = await ref.watch(apiProvider).requestDetails();
      final grouped = <int, List<RequestDetail>>{};
      for (final detail in details) {
        grouped.putIfAbsent(detail.collectRequestId, () => []).add(detail);
      }
      return grouped;
    });

final requestFullProvider = FutureProvider.autoDispose
    .family<CollectRequestFull, int>(
      (ref, id) => ref.watch(apiProvider).requestFull(id),
    );

final requestHistoryProvider = FutureProvider.autoDispose
    .family<List<RequestHistory>, int>((ref, id) async {
      final items = await ref.watch(apiProvider).requestHistory(id);
      return [...items]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    });

final serviceMaterialsProvider = FutureProvider.autoDispose
    .family<List<RecoveredMaterial>, int>(
      (ref, serviceId) => ref.watch(apiProvider).materialsByService(serviceId),
    );

typedef GradeKey = ({int serviceId, int userId});

final gradeProvider = FutureProvider.autoDispose.family<Grade?, GradeKey>(
  (ref, key) => ref.watch(apiProvider).gradeFor(key.serviceId, key.userId),
);

/// Requests behind the services of the signed-in gatherer.
final gathererRequestsProvider =
    FutureProvider.autoDispose<List<CollectRequestFull>>((ref) async {
      final gatherer = ref.watch(sessionProvider).gatherer;
      if (gatherer == null) return const [];
      final api = ref.watch(apiProvider);
      final services = await api.servicesByGatherer(gatherer.gathererId);
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
  final gatherer = ref.watch(sessionProvider).gatherer;
  if (gatherer == null) return 0;
  final api = ref.watch(apiProvider);
  final services = await api.servicesByGatherer(gatherer.gathererId);
  final mine = {for (final service in services) service.id};
  final materials = await api.allMaterials();
  return materials
      .where(
        (item) => mine.contains(item.pickupServiceId) && item.unit.api == 'Kg',
      )
      .fold<double>(0, (sum, item) => sum + item.quantity);
});

final gathererRatingProvider = FutureProvider.autoDispose<GathererRating?>((
  ref,
) async {
  final gatherer = ref.watch(sessionProvider).gatherer;
  if (gatherer == null) return null;
  final ratings = await ref.watch(apiProvider).gathererRatings();
  return ratings
      .where((item) => item.gathererId == gatherer.gathererId)
      .firstOrNull;
});

final generalIndicatorsProvider = FutureProvider.autoDispose<GeneralIndicators>(
  (ref) => ref.watch(apiProvider).generalIndicators(),
);
