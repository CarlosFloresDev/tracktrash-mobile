import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tracktrash_mobile/core/api_failure.dart';
import 'package:tracktrash_mobile/features/community/data/community_repository.dart';
import 'package:tracktrash_mobile/features/community/domain/community_models.dart';
import 'package:tracktrash_mobile/features/community/presentation/community_actions.dart';
import 'package:tracktrash_mobile/features/session/secure_session_storage.dart';

class TestCommunityRepository implements CommunityRepository {
  int calls = 0;
  bool fail = false;
  @override
  Future<void> redeem(String id, String key) async {
    calls++;
    if (fail) throw const ApiFailure('Saldo insuficiente');
  }

  @override
  Future<void> report(String id, String type, String text) async {
    calls++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'canje bloquea doble envío y notifica actualización una sola vez',
    () async {
      final repo = TestCommunityRepository();
      var changes = 0;
      final vm = CommunityActions(repo, () => changes++);
      addTearDown(vm.dispose);
      final a = vm.redeem('beneficio', 'clave');
      expect(await vm.redeem('beneficio', 'clave'), false);
      expect(await a, true);
      expect(repo.calls, 1);
      expect(changes, 1);
    },
  );
  test('un error de negocio conserva mensaje y permite reintento', () async {
    final repo = TestCommunityRepository()..fail = true;
    final vm = CommunityActions(repo, () {});
    addTearDown(vm.dispose);
    expect(await vm.redeem('b', 'k'), false);
    expect(vm.error, 'Saldo insuficiente');
    expect(vm.busy, false);
    repo.fail = false;
    expect(await vm.redeem('b', 'k'), true);
    expect(vm.error, isNull);
  });
  test('un resultado tardío no actualiza un ViewModel liberado', () async {
    var changes = 0;
    final vm = CommunityActions(TestCommunityRepository(), () => changes++);
    final pending = vm.report('c', 'tipo', 'descripción');
    vm.dispose();
    await pending;
    expect(changes, 0);
  });
  test('mapa distingue datos de demostración y caché desactualizada', () {
    final map = CommunityMap.fromJson({
      'contenedores': [
        {
          'id': 'c',
          'nombre': 'Tacho',
          'latitud': -16.4,
          'longitud': -71.5,
          'estado': 'SinDatosRecientes',
          'porcentaje': 90,
          'demostracion': true,
        },
      ],
      'asociaciones': [],
      'puntosAcopio': [],
    }, cached: true);
    expect(map.cached, true);
    expect(map.places.single.demo, true);
    expect(map.places.single.status, 'SinDatosRecientes');
  });
  test(
    'perfil serializado no incluye campos para elevar roles ni modificar racha',
    () {
      const profile = CommunityProfile(
        name: 'Vecino',
        phone: '999111222',
        address: 'Prueba',
        alerts: true,
        streak: 5,
        bestStreak: 8,
      );
      expect(profile.toJson().containsKey('rol'), false);
      expect(profile.toJson().containsKey('rachaActual'), false);
    },
  );
  test(
    'sesión persistida se elimina del almacenamiento seguro al salir',
    () async {
      FlutterSecureStorage.setMockInitialValues({});
      const storage = SecureSessionStorage();
      await storage.initialize();
      await storage.persistSession('session-test');
      expect(await storage.hasAccessToken(), true);
      expect(await storage.accessToken(), 'session-test');
      await storage.removePersistedSession();
      expect(await storage.hasAccessToken(), false);
    },
  );
}
