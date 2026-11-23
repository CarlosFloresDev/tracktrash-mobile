import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/api_failure.dart';
import '../../data/models.dart';
import '../../data/track_trash_api.dart';

/// The backend does not expose authentication yet: there is no login endpoint and tokens are not validated.
/// Everything about "signing in" goes through this gateway so adopting a real
/// `POST /api/Auth/login` later only means providing another implementation.
abstract interface class AuthGateway {
  bool get verifiesPassword;
  Future<User> signIn(String email, String password);
  Future<User> restore(int userId);
}

/// Provisional: resolves the account by e-mail. The password is NOT verified by the backend.
class ProvisionalAuthGateway implements AuthGateway {
  ProvisionalAuthGateway(this._api);
  final TrackTrashApi _api;

  @override
  bool get verifiesPassword => false;

  @override
  Future<User> signIn(String email, String password) async {
    try {
      return _ensureActive(await _api.userByEmail(email));
    } on ApiFailure catch (failure) {
      if (failure.isNotFound) {
        throw const ApiFailure('No encontramos una cuenta con ese correo.');
      }
      rethrow;
    }
  }

  @override
  Future<User> restore(int userId) async =>
      _ensureActive(await _api.userById(userId));

  User _ensureActive(User user) {
    if (!user.isActive) throw const ApiFailure('Esta cuenta está desactivada.');
    return user;
  }
}

abstract interface class SessionStorage {
  Future<int?> readUserId();
  Future<void> writeUserId(int? userId);
}

class SecureSessionStorage implements SessionStorage {
  const SecureSessionStorage();
  static const _key = 'tracktrash.user_id';
  static const _storage = FlutterSecureStorage();

  @override
  Future<int?> readUserId() async {
    final raw = await _storage.read(key: _key);
    return raw == null ? null : int.tryParse(raw);
  }

  @override
  Future<void> writeUserId(int? userId) => userId == null
      ? _storage.delete(key: _key)
      : _storage.write(key: _key, value: '$userId');
}

class SessionController extends ChangeNotifier {
  SessionController({
    required TrackTrashApi api,
    required AuthGateway gateway,
    required SessionStorage storage,
  }) : _api = api,
       _gateway = gateway,
       _storage = storage;

  final TrackTrashApi _api;
  final AuthGateway _gateway;
  final SessionStorage _storage;
  bool _disposed = false;

  User? _user;
  Gatherer? _gatherer;
  Organization? _organization;
  bool _restoring = true;
  bool _busy = false;
  String? _error;

  User? get user => _user;
  Gatherer? get gatherer => _gatherer;
  Organization? get organization => _organization;
  bool get isSignedIn => _user != null;
  bool get restoring => _restoring;
  bool get busy => _busy;
  String? get error => _error;
  bool get verifiesPassword => _gateway.verifiesPassword;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  /// Restores the previous session, if any. Called once at startup.
  Future<void> restore() async {
    try {
      final id = await _storage.readUserId();
      if (id != null) {
        final user = await _gateway.restore(id);
        await _load(user);
      }
    } on ApiFailure {
      await _storage.writeUserId(null);
    } catch (_) {
      // Storage unavailable (for example in some browsers): start signed out.
    } finally {
      _restoring = false;
      _notify();
    }
  }

  Future<bool> signIn(String email, String password) async {
    if (_busy) return false;
    _busy = true;
    _error = null;
    _notify();
    try {
      final user = await _gateway.signIn(email, password);
      await _load(user);
      await _storage.writeUserId(user.userId).catchError((Object _) {});
      return true;
    } on ApiFailure catch (failure) {
      _error = failure.message;
      return false;
    } finally {
      _busy = false;
      _notify();
    }
  }

  Future<void> signOut() async {
    _user = null;
    _gatherer = null;
    _organization = null;
    _error = null;
    _notify();
    await _storage.writeUserId(null).catchError((Object _) {});
  }

  /// Reloads the signed-in user and role profiles (after an edit, or a verification by an admin).
  Future<void> refresh() async {
    final current = _user;
    if (current == null) return;
    try {
      await _load(await _api.userById(current.userId));
      _notify();
    } on ApiFailure {
      // Keep the cached profile; the next screen load reports connectivity problems.
    }
  }

  Future<void> _load(User user) async {
    final gatherer = user.role == UserRole.gatherer
        ? await _api.gathererByUser(user.userId)
        : null;
    final organization = user.role == UserRole.organization
        ? await _api.organizationByUser(user.userId)
        : null;
    _user = user;
    _gatherer = gatherer;
    _organization = organization;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
