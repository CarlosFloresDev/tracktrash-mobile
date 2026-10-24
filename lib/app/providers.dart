import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config.dart';
import '../features/pickups/data/pickup_repository.dart';
import '../features/pickups/presentation/pickups_view_model.dart';
import '../features/session/session.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );
  ref.onDispose(dio.close);
  return dio;
});

final sessionProvider = ChangeNotifierProvider<SessionController>(
  (ref) => SessionController(
    ref.watch(dioProvider),
    auth: AppConfig.authConfigured ? Supabase.instance.client : null,
  ),
);

final pickupRepositoryProvider = Provider<PickupRepository>((ref) {
  final session = ref.watch(sessionProvider).session;
  return ApiPickupRepository(ref.watch(dioProvider), session?.token ?? '');
});

final pickupsProvider = ChangeNotifierProvider.autoDispose<PickupsViewModel>(
  (ref) => PickupsViewModel(ref.watch(pickupRepositoryProvider)),
);
