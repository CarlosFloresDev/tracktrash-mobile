import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tracktrash_mobile/app/providers.dart';
import 'package:tracktrash_mobile/app/tracktrash_app.dart';
import 'package:tracktrash_mobile/data/auth_tokens.dart';
import 'package:tracktrash_mobile/data/enums.dart';
import 'package:tracktrash_mobile/data/models.dart';
import 'package:tracktrash_mobile/features/session/session.dart';

import 'support/fakes.dart';

const password = 'secreto123';

({SessionController session, FakeApi api, MemorySessionStorage storage})
buildSession(List<(User, String)> accounts, {MemorySessionStorage? storage}) {
  final store = storage ?? MemorySessionStorage();
  final api = FakeApi(accounts: accounts, vault: TokenVault(store));
  return (
    session: SessionController(api: api, vault: api.vault),
    api: api,
    storage: store,
  );
}

void main() {
  group('SessionController', () {
    test('signs in with e-mail and password and stores the tokens', () async {
      final s = buildSession([(fakeUser(), password)]);
      expect(await s.session.signIn('  LUCIA@correo.pe ', password), isTrue);
      expect(s.session.isSignedIn, isTrue);
      expect(s.storage.tokens?.accessToken, 'token-1');
    });

    test('rejects a wrong password', () async {
      final s = buildSession([(fakeUser(), password)]);
      expect(await s.session.signIn('lucia@correo.pe', 'otra'), isFalse);
      expect(
        s.session.error,
        'Correo o contraseña incorrectos, o cuenta desactivada.',
      );
      expect(s.session.isSignedIn, isFalse);
      expect(s.storage.tokens, isNull);
    });

    test('rejects deactivated accounts', () async {
      final s = buildSession([(fakeUser(active: false), password)]);
      expect(await s.session.signIn('lucia@correo.pe', password), isFalse);
      expect(s.session.isSignedIn, isFalse);
    });

    test('loads the gatherer profile for gatherer accounts', () async {
      final s = buildSession([(fakeUser(role: UserRole.gatherer), password)]);
      await s.session.signIn('lucia@correo.pe', password);
      expect(s.session.gatherer, isNull);
      expect(s.session.user?.role, UserRole.gatherer);
    });

    test('restores stored tokens and drops rejected ones', () async {
      final ok = buildSession([
        (fakeUser(), password),
      ], storage: MemorySessionStorage(fakeTokens('old')));
      ok.api.issue('old', fakeUser());
      await ok.session.restore();
      expect(ok.session.isSignedIn, isTrue);
      expect(ok.session.restoring, isFalse);

      final gone = buildSession(
        const [],
        storage: MemorySessionStorage(fakeTokens('revoked')),
      );
      await gone.session.restore();
      expect(gone.session.isSignedIn, isFalse);
      expect(gone.storage.tokens, isNull);
    });

    test('sign out revokes the refresh token and clears storage', () async {
      final s = buildSession([(fakeUser(), password)]);
      await s.session.signIn('lucia@correo.pe', password);
      await s.session.signOut();
      expect(s.session.isSignedIn, isFalse);
      expect(s.storage.tokens, isNull);
      expect(s.api.revoked, ['refresh-token-1']);
    });

    test('an expired session signs the user out with a message', () async {
      final s = buildSession([(fakeUser(), password)]);
      await s.session.signIn('lucia@correo.pe', password);
      await s.api.vault.expire();
      await Future<void>.delayed(Duration.zero);
      expect(s.session.isSignedIn, isFalse);
      expect(s.session.error, 'Tu sesión expiró. Vuelve a ingresar.');
    });
  });

  group('access flow', () {
    setUpAll(() => initializeDateFormatting('es'));

    Future<void> pumpApp(WidgetTester tester, FakeApi api) async {
      tester.view.physicalSize = const Size(900, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      // Endless decorative animations would keep pumpAndSettle waiting forever.
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiProvider.overrideWithValue(api),
            tokenVaultProvider.overrideWithValue(api.vault),
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

    testWidgets('login validates input', (tester) async {
      await pumpApp(tester, FakeApi());
      await tester.tap(find.text('Iniciar sesión'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Acceso provisional'), findsNothing);

      await tester.tap(find.widgetWithText(FilledButton, 'Ingresar'));
      await tester.pumpAndSettle();
      expect(find.text('Ingresa un correo válido'), findsOneWidget);
      expect(find.text('Ingresa tu contraseña'), findsOneWidget);
    });

    testWidgets('wrong credentials show the error from the session', (
      tester,
    ) async {
      await pumpApp(tester, FakeApi());
      await tester.tap(find.text('Iniciar sesión'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Correo'),
        'nadie@correo.pe',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Contraseña'),
        'secreto',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Ingresar'));
      await tester.pumpAndSettle();
      expect(
        find.text('Correo o contraseña incorrectos, o cuenta desactivada.'),
        findsOneWidget,
      );
    });
  });
}
