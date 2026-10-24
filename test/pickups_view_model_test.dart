import 'package:flutter_test/flutter_test.dart';
import 'package:tracktrash_mobile/features/pickups/domain/pickup.dart';
import 'package:tracktrash_mobile/features/pickups/presentation/pickups_view_model.dart';
import 'support/fake_pickup_repository.dart';

PickupDraft draft() => PickupDraft(
  key: 'test-1',
  material: RecyclableMaterial.paper,
  kg: 2.5,
  address: 'Av. Arequipa 123',
  scheduledAt: DateTime.now().add(const Duration(days: 1)),
);

void main() {
  test(
    'conserva la información previa cuando falla la actualización',
    () async {
      final repo = FakePickupRepository();
      await repo.create(draft());
      final vm = PickupsViewModel(repo);
      addTearDown(vm.dispose);
      await vm.load();
      repo.failLoad = true;
      await vm.load();
      expect(vm.state.items.single.id, 'test-1');
      expect(vm.state.error, 'Sin conexión');
      expect(vm.state.loading, false);
    },
  );

  test('evita envíos dobles mientras la operación está pendiente', () async {
    final repo = FakePickupRepository();
    final vm = PickupsViewModel(repo);
    addTearDown(vm.dispose);
    final first = vm.create(draft());
    expect(await vm.create(draft()), false);
    expect(await first, true);
    expect(repo.createCalls, 1);
  });

  test('un error de creación permite reintentar sin perder la clave', () async {
    final repo = FakePickupRepository()..failCreate = true;
    final vm = PickupsViewModel(repo);
    addTearDown(vm.dispose);
    final request = draft();
    expect(await vm.create(request), false);
    repo.failCreate = false;
    expect(await vm.create(request), true);
    expect(repo.lastDraft!.key, request.key);
    expect(vm.state.error, isNull);
  });

  test('actualiza el estado local de la entrega sin duplicar filas', () async {
    final repo = FakePickupRepository();
    final vm = PickupsViewModel(repo);
    addTearDown(vm.dispose);
    await vm.create(draft());
    await vm.accept('test-1');
    expect(vm.state.items.single.status, 'Aceptada');
    expect(await vm.confirm('test-1', '000000'), false);
    expect(vm.state.items.single.status, 'Aceptada');
    expect(await vm.confirm('test-1', '123456'), true);
    expect(vm.state.items.single.status, 'Confirmada');
    await vm.load();
    expect(vm.state.points, 20);
  });

  test('no actualiza una pantalla liberada durante una petición', () async {
    final vm = PickupsViewModel(FakePickupRepository());
    final pending = vm.load();
    vm.dispose();
    await pending;
  });
}
