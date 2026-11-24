import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../core/api_failure.dart';
import '../../data/auth_tokens.dart';
import '../../data/enums.dart';
import '../../data/models.dart';
import '../../data/track_trash_api.dart';

/// Signed-in state. Login exchanges e-mail and password for a JWT pair kept in [TokenVault];
/// the HTTP layer renews it, and when the server ends the session this controller signs out.
class SessionController extends ChangeNotifier {
  SessionController({required TrackTrashApi api, required TokenVault vault})
    : _api = api,
      _vault = vault {
    _expiry = vault.onExpired.listen(
      (_) => _clearProfile(message: 'Tu sesión expiró. Vuelve a ingresar.'),
    );
  }

  final TrackTrashApi _api;
  final TokenVault _vault;
  late final StreamSubscription<void> _expiry;
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

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  /// Restores the previous session, if any. Called once at startup.
  Future<void> restore() async {
    try {
      if (await _vault.load() != null) await _load(await _api.me());
    } on ApiFailure catch (failure) {
      // A network error keeps the tokens so the next start can retry; a rejection drops them.
      if (failure.statusCode != null) await _vault.clear();
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
      await _vault.save(await _authenticate(email, password));
      final user = await _api.me();
      if (!user.isActive) {
        await signOut();
        throw const ApiFailure('Esta cuenta está desactivada.');
      }
      await _load(user);
      return true;
    } on ApiFailure catch (failure) {
      _error = failure.message;
      return false;
    } finally {
      _busy = false;
      _notify();
    }
  }

  Future<AuthTokens> _authenticate(String email, String password) async {
    try {
      return await _api.login(email, password);
    } on ApiFailure catch (failure) {
      if (failure.statusCode == 401) {
        throw const ApiFailure(
          'Correo o contraseña incorrectos, o cuenta desactivada.',
          statusCode: 401,
        );
      }
      rethrow;
    }
  }

  /// Revokes the refresh token on the server (best effort) and forgets the session locally.
  Future<void> signOut() async {
    final refreshToken = _vault.tokens?.refreshToken;
    _clearProfile();
    await _vault.clear();
    if (refreshToken != null) {
      await _api.logout(refreshToken).catchError((Object _) {});
    }
  }

  /// Reloads the signed-in user and role profiles (after an edit, or a verification by an admin).
  Future<void> refresh() async {
    if (_user == null) return;
    try {
      await _load(await _api.me());
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

  void _clearProfile({String? message}) {
    if (_user == null && message != null) return;
    _user = null;
    _gatherer = null;
    _organization = null;
    _error = message;
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    _expiry.cancel();
    super.dispose();
  }
}
