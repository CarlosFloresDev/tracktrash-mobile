import 'package:flutter/foundation.dart';
import '../../../core/api_failure.dart';
import '../data/pickup_repository.dart';
import '../domain/pickup.dart';

@immutable
class PickupsState {
  const PickupsState({
    this.items = const [],
    this.points = 0,
    this.loading = false,
    this.saving = false,
    this.error,
    this.hasMore = false,
  });
  final List<Pickup> items;
  final int points;
  final bool loading;
  final bool saving;
  final String? error;
  final bool hasMore;
}

class PickupsViewModel extends ChangeNotifier {
  PickupsViewModel(this._repository);
  final PickupRepository _repository;
  PickupsState _state = const PickupsState();
  PickupsState get state => _state;
  int _page = 1;
  bool _disposed = false;

  void _emit(PickupsState state) {
    if (_disposed) return;
    _state = state;
    notifyListeners();
  }

  Future<void> load({bool more = false}) async {
    if (_state.loading || _state.saving) return;
    final previous = _state;
    _emit(
      PickupsState(
        items: previous.items,
        points: previous.points,
        loading: true,
        hasMore: previous.hasMore,
      ),
    );
    try {
      final nextPage = more ? _page + 1 : 1;
      final results = await Future.wait([
        _repository.list(page: nextPage),
        _repository.points(),
      ]);
      final items = results[0] as List<Pickup>;
      _page = nextPage;
      final all = more ? [...previous.items, ...items] : items;
      final unique = {for (final item in all) item.id: item};
      _emit(
        PickupsState(
          items: List.unmodifiable(unique.values),
          points: results[1] as int,
          hasMore: items.length == 50,
        ),
      );
    } catch (e) {
      _emit(
        PickupsState(
          items: previous.items,
          points: previous.points,
          hasMore: previous.hasMore,
          error: _message(e),
        ),
      );
    }
  }

  Future<bool> create(PickupDraft draft) =>
      _mutate(() => _repository.create(draft));
  Future<bool> accept(String id) => _mutate(() => _repository.accept(id));
  Future<bool> confirm(String id, String code) =>
      _mutate(() => _repository.confirm(id, code));

  Future<bool> _mutate(Future<Pickup> Function() action) async {
    if (_state.saving || _state.loading) return false;
    final previous = _state;
    _emit(
      PickupsState(
        items: previous.items,
        points: previous.points,
        saving: true,
        hasMore: previous.hasMore,
      ),
    );
    try {
      final item = await action();
      _emit(
        PickupsState(
          items: List.unmodifiable([
            item,
            ...previous.items.where((i) => i.id != item.id),
          ]),
          points: previous.points,
          hasMore: previous.hasMore,
        ),
      );
      return true;
    } catch (e) {
      _emit(
        PickupsState(
          items: previous.items,
          points: previous.points,
          hasMore: previous.hasMore,
          error: _message(e),
        ),
      );
      return false;
    }
  }

  String _message(Object e) =>
      e is ApiFailure ? e.message : 'Ocurrió un problema. Vuelve a intentarlo.';

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
