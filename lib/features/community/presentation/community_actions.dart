import 'package:flutter/foundation.dart';
import '../../../core/api_failure.dart';
import '../data/community_repository.dart';
import '../domain/community_models.dart';

class CommunityActions extends ChangeNotifier {
  CommunityActions(this._repo, this._onChanged);
  final CommunityRepository _repo;
  final VoidCallback _onChanged;
  bool _busy = false, _disposed = false;
  String? _error;
  bool get busy => _busy;
  String? get error => _error;
  Future<bool> _run(Future<void> Function() action) async {
    if (_busy) return false;
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await action();
      if (!_disposed) _onChanged();
      return true;
    } catch (e) {
      _error = e is ApiFailure
          ? e.message
          : 'No pudimos completar la operación.';
      return false;
    } finally {
      _busy = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<bool> report(String id, String type, String text) =>
      _run(() => _repo.report(id, type, text));
  Future<bool> redeem(String id, String key) =>
      _run(() => _repo.redeem(id, key));
  Future<bool> saveProfile(CommunityProfile p) =>
      _run(() => _repo.saveProfile(p));
  Future<bool> attend(String id) => _run(() => _repo.attend(id));
  Future<bool> resolve(String id, String text) =>
      _run(() => _repo.resolve(id, text));
  Future<bool> readNotice(String id) => _run(() => _repo.readNotice(id));
  Future<bool> travel(String id) => _run(() => _repo.travel(id));
  Future<bool> cancel(String id, String reason) =>
      _run(() => _repo.cancel(id, reason));
  Future<bool> assign(String id) => _run(() => _repo.assign(id));
  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
