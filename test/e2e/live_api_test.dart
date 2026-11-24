// End-to-end check of the data layer against a running backend.
// Skipped unless E2E_API is set, e.g.:
//   flutter test test/e2e --dart-define=E2E_API=http://localhost:5145 \
//     --dart-define=E2E_ADMIN=admin@correo.pe --dart-define=E2E_ADMIN_PASSWORD=...
@Tags(['e2e'])
library;

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracktrash_mobile/data/auth_interceptor.dart';
import 'package:tracktrash_mobile/data/auth_tokens.dart';
import 'package:tracktrash_mobile/data/enums.dart';
import 'package:tracktrash_mobile/data/track_trash_api.dart';
import 'package:tracktrash_mobile/features/session/session.dart';

import '../support/fakes.dart';

const baseUrl = String.fromEnvironment('E2E_API');
const adminEmail = String.fromEnvironment('E2E_ADMIN');
const adminPassword = String.fromEnvironment('E2E_ADMIN_PASSWORD');

/// One signed-in client, wired exactly like the app.
class Client {
  Client() {
    final options = BaseOptions(baseUrl: baseUrl);
    dio = Dio(options)..interceptors.add(AuthInterceptor(vault, Dio(options)));
    api = DioTrackTrashApi(dio);
    session = SessionController(api: api, vault: vault);
  }

  final vault = TokenVault(MemorySessionStorage());
  late final Dio dio;
  late final TrackTrashApi api;
  late final SessionController session;

  Future<void> signIn(String email, String password) async {
    expect(
      await session.signIn(email, password),
      isTrue,
      reason: session.error,
    );
  }
}

void main() {
  final stamp = DateTime.now().millisecondsSinceEpoch;
  const password = 'Prueba2026!';

  test(
    'household asks, gatherer applies, household accepts, gatherer completes',
    () async {
      final household = Client();
      final gatherer = Client();
      final admin = Client();
      final residentEmail = 'hogar$stamp@correo.pe';
      final gathererEmail = 'reco$stamp@correo.pe';

      // Sign-up is anonymous; everything else needs the token.
      await household.api.createUser(
        firstName: 'Lucia',
        lastName: 'Mamani',
        email: residentEmail,
        password: password,
        role: UserRole.generator,
      );
      final gathererUserId = await gatherer.api.createUser(
        firstName: 'Rosa',
        lastName: 'Quispe',
        email: gathererEmail,
        password: password,
        role: UserRole.gatherer,
      );

      await household.signIn(residentEmail, password);
      expect(household.session.user!.email, residentEmail);
      final locationId = await household.api.createLocation(
        address: 'Calle Mercaderes 101',
        district: 'Arequipa',
      );

      await gatherer.signIn(gathererEmail, password);
      await gatherer.api.createGatherer(
        userId: gathererUserId,
        type: GathererType.independent,
        document: 'DNI-$stamp',
      );
      await gatherer.session.refresh();
      final profile = gatherer.session.gatherer!;
      expect(profile.verification, VerificationStatus.pending);

      // An administrator verifies the gatherer (web-only feature in the app).
      await admin.signIn(adminEmail, adminPassword);
      final toVerify = (await admin.api.gatherers()).firstWhere(
        (g) => g.gathererId == profile.gathererId,
      );
      await admin.api.updateGatherer(
        toVerify,
        verification: VerificationStatus.verified,
      );
      expect(
        (await admin.api.users()).map((u) => u.email),
        contains(gathererEmail),
      );

      final catalog = (await household.api.residueTypes())
          .where((item) => item.isActive && item.isRecyclable)
          .toList();
      expect(catalog, isNotEmpty);
      final material = catalog.first;

      await gatherer.api.setMyResidueTypes([material.id]);
      await gatherer.session.refresh();
      expect(
        gatherer.session.gatherer!.supportedResidueTypes.map((e) => e.id),
        [material.id],
      );

      final requestId = await household.api.createRequest(
        locationId: locationId,
        date: DateTime.now().add(const Duration(days: 2)),
        time: '10:30',
        items: [
          (residueTypeId: material.id, quantity: 4.5, unit: MeasurementUnit.kg),
        ],
      );
      expect(await household.api.detailsOf(requestId), hasLength(1));

      expect(
        (await admin.api.allRequests()).map((r) => r.id),
        contains(requestId),
      );

      final compatible = await household.api.gatherersFor(requestId);
      expect(compatible.map((g) => g.gathererId), contains(profile.gathererId));

      final pending = await gatherer.api.pendingRequests();
      expect(pending.map((r) => r.id), contains(requestId));
      expect(
        (await gatherer.api.requesterProfile(requestId)).displayName,
        'Lucia Mamani',
      );

      await gatherer.api.applyTo(requestId);
      final mine = await gatherer.api.myApplications();
      expect(mine.single.collectRequestId, requestId);
      expect(mine.single.status, ApplicationStatus.pending);

      final received = await household.api.applicationsOf(requestId);
      expect(received.single.fullName, 'Rosa Quispe');
      await household.api.acceptApplication(requestId, received.single.id);

      final full = await gatherer.api.requestFull(requestId);
      expect(full.service?.gathererId, profile.gathererId);
      expect(full.request.status, RequestStatus.assigned);

      final serviceId = full.service!.id;
      await gatherer.api.changeServiceStatus(
        serviceId,
        RequestStatus.inProgress,
      );
      await gatherer.api.recordMaterial(
        serviceId: serviceId,
        residueTypeId: material.id,
        quantity: 4.2,
        unit: MeasurementUnit.kg,
      );
      await gatherer.api.changeServiceStatus(
        serviceId,
        RequestStatus.completed,
      );

      await household.api.createGrade(
        serviceId: serviceId,
        userId: household.session.user!.userId,
        score: 5,
        comment: 'Puntual',
      );
      final gradeIds = await gatherer.api.gradeIdsOfGatherer(
        profile.gathererId,
      );
      expect(gradeIds, hasLength(1));
      expect((await gatherer.api.gradeById(gradeIds.single)).score, 5);

      // A forged expiry forces the interceptor to rotate the refresh token transparently.
      final before = household.vault.tokens!;
      await household.vault.save(
        AuthTokens(
          accessToken: before.accessToken,
          refreshToken: before.refreshToken,
          expiresAt: DateTime.now().toUtc().subtract(
            const Duration(minutes: 1),
          ),
        ),
      );
      expect((await household.api.me()).email, residentEmail);
      expect(household.vault.tokens!.refreshToken, isNot(before.refreshToken));

      // Logout revokes the refresh token: reusing it is rejected.
      final refresh = household.vault.tokens!.refreshToken;
      await household.session.signOut();
      final reuse = await Dio(BaseOptions(baseUrl: baseUrl)).post<dynamic>(
        '/api/Auth/Refresh',
        data: {'refreshToken': refresh},
        options: Options(validateStatus: (_) => true),
      );
      expect(reuse.statusCode, 401);
    },
    skip: baseUrl.isEmpty ? 'Set --dart-define=E2E_API to run' : false,
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
