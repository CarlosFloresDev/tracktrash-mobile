import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tracktrash_mobile/features/community/domain/community_models.dart';
import 'package:tracktrash_mobile/features/community/data/community_repository.dart';
import 'package:tracktrash_mobile/features/community/presentation/community_actions.dart';
import 'package:tracktrash_mobile/features/community/presentation/community_providers.dart';
import 'package:tracktrash_mobile/features/community/presentation/notification_preferences_fields.dart';
import 'package:tracktrash_mobile/features/community/presentation/routes_page.dart';
import 'package:tracktrash_mobile/features/community/presentation/profile_page.dart';
import 'community_test.dart' show TestCommunityRepository;
import 'pickup_repository_test.dart' show StubAdapter;

class PreferencesRepository extends TestCommunityRepository {
  CommunityProfile? savedProfile;
  int? selectedMinutes;
  Completer<void>? pending;
  @override
  Future<void> saveProfile(CommunityProfile profile) async {
    savedProfile = profile;
  }

  @override
  Future<void> subscribe(
    String id,
    bool enabled, {
    int minutesBefore = 20,
  }) async {
    calls++;
    selectedMinutes = minutesBefore;
    if (pending != null) await pending!.future;
  }
}

const profile = CommunityProfile(
  name: 'Vecino',
  phone: '',
  address: '',
  alerts: true,
);

void main() {
  setUpAll(() async => initializeDateFormatting('es_PE'));

  testWidgets(
    'pausar todos conserva los tipos elegidos y deshabilita sus controles',
    (tester) async {
      var enabled = true;
      var prefs = const NotificationPreferences();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: StatefulBuilder(
                builder: (context, update) => NotificationPreferencesFields(
                  enabled: enabled,
                  preferences: prefs,
                  onEnabledChanged: (v) => update(() => enabled = v),
                  onPreferencesChanged: (v) => update(() => prefs = v),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.ensureVisible(find.byKey(const Key('notice-pickups')));
      await tester.tap(find.byKey(const Key('notice-pickups')));
      await tester.pumpAndSettle();
      expect(prefs.pickups, false);
      await tester.ensureVisible(find.byKey(const Key('notice-master')));
      await tester.tap(find.byKey(const Key('notice-master')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<SwitchListTile>(find.byKey(const Key('notice-schedules')))
            .onChanged,
        isNull,
      );
      await tester.tap(find.byKey(const Key('notice-master')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<SwitchListTile>(find.byKey(const Key('notice-pickups')))
            .value,
        false,
      );
      expect(
        tester
            .widget<SwitchListTile>(find.byKey(const Key('notice-schedules')))
            .value,
        true,
      );
    },
  );

  testWidgets('perfil envía la selección individual solo al guardar', (
    tester,
  ) async {
    final repo = PreferencesRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileProvider.overrideWith((ref) async => profile),
          communityActionsProvider.overrideWith(
            (ref) => CommunityActions(repo, () {}),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: ProfilePage())),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('notice-rewards')),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.byKey(const Key('notice-rewards')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('notice-rewards')));
    await tester.pumpAndSettle();
    expect(repo.savedProfile, isNull);
    await tester.scrollUntilVisible(
      find.text('Guardar cambios'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();
    expect(repo.savedProfile!.notificationPreferences.rewards, false);
    expect(repo.savedProfile!.notificationPreferences.schedules, true);
    expect(repo.savedProfile!.alerts, true);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'cambiar la anticipación requiere guardar y no duplica el envío',
    (tester) async {
      final repo = PreferencesRepository()..pending = Completer<void>();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            profileProvider.overrideWith((ref) async => profile),
            routesProvider.overrideWith(
              (ref) async => [
                RouteSchedule(
                  id: 'route',
                  name: 'Ruta de prueba',
                  zone: 'Zona',
                  nextPass: DateTime(2026, 10, 26, 19),
                  demo: true,
                  subscribed: true,
                  minutesBefore: 20,
                ),
              ],
            ),
            communityActionsProvider.overrideWith(
              (ref) => CommunityActions(repo, () {}),
            ),
          ],
          child: const MaterialApp(home: RoutesPage()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('20 minutos antes'), findsOneWidget);
      await tester.ensureVisible(find.byType(DropdownButtonFormField<int>));
      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('35 minutos antes').last);
      await tester.pumpAndSettle();
      expect(repo.calls, 0);
      await tester.ensureVisible(find.text('Guardar anticipación'));
      await tester.tap(find.text('Guardar anticipación'));
      await tester.pump();
      await tester.tap(find.text('Guardar anticipación'));
      await tester.pump();
      expect(repo.calls, 1);
      expect(repo.selectedMinutes, 35);
      repo.pending!.complete();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'serialización conserva preferencias y tolera respuesta del contrato anterior',
    () {
      final json = profile.toJson();
      json['preferenciasAvisos'] = const NotificationPreferences(
        pickups: false,
      ).toJson();
      final loaded = CommunityProfile.fromJson(json);
      expect(loaded.notificationPreferences.pickups, false);
      json.remove('preferenciasAvisos');
      expect(
        CommunityProfile.fromJson(json).notificationPreferences.pickups,
        true,
      );
    },
  );

  test(
    'repositorio transmite la anticipación elegida sin fijarla en 20',
    () async {
      final adapter = StubAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
        ..httpClientAdapter = adapter;
      addTearDown(dio.close);
      await ApiCommunityRepository(
        dio,
        'token',
      ).subscribe('route', true, minutesBefore: 35);
      expect(adapter.request!.data, {'minutosAntes': 35});
      expect(adapter.request!.headers['Authorization'], 'Bearer token');
    },
  );
}
