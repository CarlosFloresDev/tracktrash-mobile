import 'package:tracktrash_mobile/core/api_failure.dart';
import 'package:tracktrash_mobile/data/auth_tokens.dart';
import 'package:tracktrash_mobile/data/models.dart';
import 'package:tracktrash_mobile/data/enums.dart';
import 'package:tracktrash_mobile/data/track_trash_api.dart';

User fakeUser({
  int id = 1,
  UserRole role = UserRole.generator,
  bool active = true,
  String email = 'lucia@correo.pe',
}) => User(
  userId: id,
  firstName: 'Lucia',
  lastName: 'Mamani',
  email: email,
  role: role,
  isActive: active,
);

AuthTokens fakeTokens(String access) => AuthTokens(
  accessToken: access,
  refreshToken: 'refresh-$access',
  expiresAt: DateTime.now().toUtc().add(const Duration(hours: 4)),
);

/// In-memory backend: accounts are `(user, password)`, tokens map to the account that owns them.
/// Only the calls a test needs are implemented; anything else fails loudly.
class FakeApi implements TrackTrashApi {
  FakeApi({this.accounts = const [], TokenVault? vault})
    : vault = vault ?? TokenVault(MemorySessionStorage());

  final List<(User, String)> accounts;
  final TokenVault vault;
  final Map<String, User> _issued = {};
  final List<String> revoked = [];
  Gatherer? gatherer;

  @override
  Future<AuthTokens> login(String email, String password) async {
    final found = accounts.where(
      (account) =>
          account.$1.email == email.trim().toLowerCase() &&
          account.$2 == password &&
          account.$1.isActive,
    );
    if (found.isEmpty) {
      throw const ApiFailure('Invalid credentials.', statusCode: 401);
    }
    final tokens = fakeTokens('token-${found.first.$1.userId}');
    _issued[tokens.accessToken] = found.first.$1;
    return tokens;
  }

  @override
  Future<void> logout(String refreshToken) async => revoked.add(refreshToken);

  @override
  Future<User> me() async {
    final user = _issued[vault.tokens?.accessToken];
    if (user == null) {
      throw const ApiFailure('Unauthorized.', statusCode: 401);
    }
    return user;
  }

  /// Simulates a token issued in a previous app run.
  void issue(String accessToken, User user) => _issued[accessToken] = user;

  @override
  Future<Gatherer?> gathererByUser(int userId) async => gatherer;

  @override
  Future<Organization?> organizationByUser(int userId) async => null;

  @override
  Future<List<ResidueType>> residueTypes() async => const [];

  @override
  Future<List<Location>> locations() async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not faked');
}

class MemorySessionStorage implements SessionStorage {
  MemorySessionStorage([this.tokens]);
  AuthTokens? tokens;

  @override
  Future<AuthTokens?> readTokens() async => tokens;

  @override
  Future<void> writeTokens(AuthTokens? value) async => tokens = value;
}
