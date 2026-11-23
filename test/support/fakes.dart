import 'package:tracktrash_mobile/core/api_failure.dart';
import 'package:tracktrash_mobile/data/models.dart';
import 'package:tracktrash_mobile/data/enums.dart';
import 'package:tracktrash_mobile/data/track_trash_api.dart';
import 'package:tracktrash_mobile/features/session/session.dart';

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

/// Only the calls a test needs are implemented; anything else fails loudly.
class FakeApi implements TrackTrashApi {
  FakeApi({this.users = const []});
  final List<User> users;
  Gatherer? gatherer;

  @override
  Future<User> userByEmail(String email) async {
    final found = users.where((user) => user.email == email.trim().toLowerCase());
    if (found.isEmpty) {
      throw const ApiFailure('User not found.', statusCode: 404);
    }
    return found.first;
  }

  @override
  Future<User> userById(int id) async => users.firstWhere(
    (user) => user.userId == id,
    orElse: () => throw const ApiFailure('User not found.', statusCode: 404),
  );

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
  MemorySessionStorage([this.userId]);
  int? userId;

  @override
  Future<int?> readUserId() async => userId;

  @override
  Future<void> writeUserId(int? value) async => userId = value;
}
