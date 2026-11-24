import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/config.dart';
import '../data/auth_interceptor.dart';
import '../data/auth_tokens.dart';
import '../data/models.dart';
import '../data/track_trash_api.dart';
import '../features/session/session.dart';

BaseOptions _options() => BaseOptions(
  baseUrl: AppConfig.apiUrl,
  connectTimeout: const Duration(seconds: 10),
  receiveTimeout: const Duration(seconds: AppConfig.apiTimeoutSeconds),
  headers: {'Accept': 'application/json'},
);

final sessionStorageProvider = Provider<SessionStorage>(
  (ref) => const SecureSessionStorage(),
);

final tokenVaultProvider = Provider<TokenVault>((ref) {
  final vault = TokenVault(ref.watch(sessionStorageProvider));
  ref.onDispose(vault.dispose);
  return vault;
});

final dioProvider = Provider<Dio>((ref) {
  final plain = Dio(_options());
  final dio = Dio(_options())
    ..interceptors.add(AuthInterceptor(ref.watch(tokenVaultProvider), plain));
  ref.onDispose(() {
    dio.close();
    plain.close();
  });
  return dio;
});

final apiProvider = Provider<TrackTrashApi>(
  (ref) => DioTrackTrashApi(ref.watch(dioProvider)),
);

final sessionProvider = ChangeNotifierProvider<SessionController>(
  (ref) => SessionController(
    api: ref.watch(apiProvider),
    vault: ref.watch(tokenVaultProvider),
  )..restore(),
);

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
