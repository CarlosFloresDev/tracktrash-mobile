import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/config.dart';
import '../data/models.dart';
import '../data/track_trash_api.dart';
import '../features/session/session.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: AppConfig.apiTimeoutSeconds),
      headers: {'Accept': 'application/json'},
    ),
  );
  ref.onDispose(dio.close);
  return dio;
});

final apiProvider = Provider<TrackTrashApi>(
  (ref) => DioTrackTrashApi(ref.watch(dioProvider)),
);

final sessionStorageProvider = Provider<SessionStorage>(
  (ref) => const SecureSessionStorage(),
);

final sessionProvider = ChangeNotifierProvider<SessionController>((ref) {
  final api = ref.watch(apiProvider);
  return SessionController(
    api: api,
    gateway: ProvisionalAuthGateway(api),
    storage: ref.watch(sessionStorageProvider),
  )..restore();
});

/// Catalog of residue types, shared by every screen that shows or picks a material.
final residueTypesProvider = FutureProvider<List<ResidueType>>(
  (ref) => ref.watch(apiProvider).residueTypes(),
);

final residueByIdProvider = Provider<Map<int, ResidueType>>((ref) {
  final items = ref.watch(residueTypesProvider).value ?? const [];
  return {for (final item in items) item.id: item};
});

final locationsProvider = FutureProvider<List<Location>>(
  (ref) => ref.watch(apiProvider).locations(),
);

final locationByIdProvider = Provider<Map<int, Location>>((ref) {
  final items = ref.watch(locationsProvider).value ?? const [];
  return {for (final item in items) item.locationId: item};
});
