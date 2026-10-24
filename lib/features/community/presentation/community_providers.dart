import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';
import '../data/community_repository.dart';
import 'community_actions.dart';

final communityRepositoryProvider = Provider<CommunityRepository>(
  (ref) => ApiCommunityRepository(
    ref.watch(dioProvider),
    ref.watch(sessionProvider.select((s) => s.session?.token)) ?? '',
  ),
);
final mapProvider = FutureProvider(
  (ref) => ref.watch(communityRepositoryProvider).map(),
);
final profileProvider = FutureProvider(
  (ref) => ref.watch(communityRepositoryProvider).profile(),
);
final noticesProvider = FutureProvider(
  (ref) => ref.watch(communityRepositoryProvider).notices(),
);
final issuesProvider = FutureProvider(
  (ref) => ref.watch(communityRepositoryProvider).issues(),
);
final rewardsProvider = FutureProvider(
  (ref) => ref.watch(communityRepositoryProvider).rewards(),
);
final redemptionsProvider = FutureProvider(
  (ref) => ref.watch(communityRepositoryProvider).redemptions(),
);
final metricsProvider = FutureProvider(
  (ref) => ref.watch(communityRepositoryProvider).metrics(),
);
final routesProvider = FutureProvider(
  (ref) => ref.watch(communityRepositoryProvider).routes(),
);
final movementsProvider = FutureProvider(
  (ref) => ref.watch(communityRepositoryProvider).movements(),
);
final communityActionsProvider = ChangeNotifierProvider.autoDispose(
  (ref) => CommunityActions(ref.watch(communityRepositoryProvider), () {
    ref.invalidate(profileProvider);
    ref.invalidate(noticesProvider);
    ref.invalidate(issuesProvider);
    ref.invalidate(rewardsProvider);
    ref.invalidate(redemptionsProvider);
    ref.invalidate(metricsProvider);
    ref.invalidate(routesProvider);
    ref.invalidate(movementsProvider);
    ref.invalidate(mapProvider);
    ref.read(pickupsProvider).load();
  }),
);
