import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tracktrash_mobile/app/providers.dart';
import 'package:tracktrash_mobile/app/tracktrash_app.dart';
import 'package:tracktrash_mobile/data/enums.dart';
import 'package:tracktrash_mobile/features/session/session.dart';

import 'support/fakes.dart';

SessionController buildSession(FakeApi api, [MemorySessionStorage? storage]) =>
    SessionController(
      api: api,
      gateway: ProvisionalAuthGateway(api),
      storage: storage ?? MemorySessionStorage(),
    );

void main() {
  group('SessionController', () {
    test('signs in by e-mail and remembers the user', () async {
      final storage = MemorySessionStorage();
      final session = buildSession(FakeApi(users: [fakeUser()]), storage);
      expect(await session.signIn('  LUCIA@correo.pe ', 'anything'), isTrue);
      expect(session.isSignedIn, isTrue);
      expect(storage.userId, 1);
    });

    test('reports an unknown account without crashing', () async {
      final session = buildSession(FakeApi());
      expect(await session.signIn('nadie@correo.pe', 'x'), isFalse);
      expect(session.error, 'No encontramos una cuenta con ese correo.');
      expect(session.isSignedIn, isFalse);
    });

    test('rejects deactivated accounts', () async {
      final session = buildSession(FakeApi(users: [fakeUser(active: false)]));
      expect(await session.signIn('lucia@correo.pe', 'x'), isFalse);
      expect(session.error, 'Esta cuenta está desactivada.');
    });

    test('loads the gatherer profile for gatherer accounts', () async {
      final api = FakeApi(users: [fakeUser(role: UserRole.gatherer)]);
      final session = buildSession(api);
      await session.signIn('lucia@correo.pe', 'x');
      expect(session.gatherer, isNull);
      expect(session.user?.role, UserRole.gatherer);
    });

    test('restores a stored session and clears it when the user is gone', () async {
      final ok = buildSession(FakeApi(users: [fakeUser()]), MemorySessionStorage(1));
      await ok.restore();
      expect(ok.isSignedIn, isTrue);
      expect(ok.restoring, isFalse);

      final storage = MemorySessionStorage(42);
      final gone = buildSession(FakeApi(), storage);
      await gone.restore();
      expect(gone.isSignedIn, isFalse);
      expect(storage.userId, isNull);
    });

    test('sign out clears state and storage', () async {
      final storage = MemorySessionStorage();
      final session = buildSession(FakeApi(users: [fakeUser()]), storage);
      await session.signIn('lucia@correo.pe', 'x');
      await session.signOut();
      expect(session.isSignedIn, isFalse);
      expect(storage.userId, isNull);
    });
  });

  group('access flow', () {
    setUpAll(() => initializeDateFormatting('es'));

    Future<void> pumpApp(WidgetTester tester, FakeApi api) async {
      tester.view.physicalSize = const Size(900, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiProvider.overrideWithValue(api),
            sessionStorageProvider.overrideWithValue(MemorySessionStorage()),
          ],
          child: const TrackTrashApp(),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('signed-out users land on the welcome screen', (tester) async {
      await pumpApp(tester, FakeApi());
      expect(find.text('Iniciar sesión'), findsOneWidget);
      expect(find.text('Crear mi cuenta'), findsOneWidget);
    });

    testWidgets('login validates input and warns about provisional access', (tester) async {
      await pumpApp(tester, FakeApi());
      await tester.tap(find.text('Iniciar sesión'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Acceso provisional'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Ingresar'));
      await tester.pumpAndSettle();
      expect(find.text('Ingresa un correo válido'), findsOneWidget);
      expect(find.text('Ingresa tu contraseña'), findsOneWidget);
    });

    testWidgets('an unknown e-mail shows the error from the session', (tester) async {
      await pumpApp(tester, FakeApi());
      await tester.tap(find.text('Iniciar sesión'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextFormField, 'Correo'), 'nadie@correo.pe');
      await tester.enterText(find.widgetWithText(TextFormField, 'Contraseña'), 'secreto');
      await tester.tap(find.widgetWithText(FilledButton, 'Ingresar'));
      await tester.pumpAndSettle();
      expect(find.text('No encontramos una cuenta con ese correo.'), findsOneWidget);
    });
  });
}
