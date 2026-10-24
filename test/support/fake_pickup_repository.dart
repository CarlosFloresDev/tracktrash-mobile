import 'package:tracktrash_mobile/core/api_failure.dart';
import 'package:tracktrash_mobile/features/pickups/data/pickup_repository.dart';
import 'package:tracktrash_mobile/features/pickups/domain/pickup.dart';

class FakePickupRepository implements PickupRepository {
  final List<Pickup> items = [];
  int createCalls = 0;
  bool failLoad = false;
  bool failCreate = false;
  PickupDraft? lastDraft;

  @override
  Future<List<Pickup>> list({int page = 1}) async {
    if (failLoad) throw const ApiFailure('Sin conexión');
    return List.of(items);
  }

  @override
  Future<int> points() async =>
      items.where((p) => p.status == 'Confirmada').length * 20;

  @override
  Future<Pickup> create(PickupDraft draft) async {
    createCalls++;
    lastDraft = draft;
    if (failCreate) throw const ApiFailure('No se pudo enviar');
    final item = Pickup(
      id: draft.key,
      material: draft.material.apiValue,
      estimatedKg: draft.kg,
      scheduledAt: draft.scheduledAt,
      status: 'Pendiente',
      address: draft.address,
      code: '123456',
    );
    items.add(item);
    return item;
  }

  @override
  Future<Pickup> accept(String id) async => _replace(id, 'Aceptada');

  @override
  Future<Pickup> confirm(String id, String code) async {
    if (code != '123456') throw const ApiFailure('Código incorrecto');
    return _replace(id, 'Confirmada');
  }

  Pickup _replace(String id, String status) {
    final i = items.indexWhere((p) => p.id == id);
    final p = items[i];
    return items[i] = Pickup(
      id: p.id,
      material: p.material,
      estimatedKg: p.estimatedKg,
      scheduledAt: p.scheduledAt,
      status: status,
      address: p.address,
      code: p.code,
    );
  }
}
