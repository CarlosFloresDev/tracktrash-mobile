import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracktrash_mobile/app/providers.dart';
import 'package:tracktrash_mobile/app/tracktrash_app.dart';
import 'package:tracktrash_mobile/features/session/session.dart';
import 'support/fake_pickup_repository.dart';

class TestSession extends SessionController {
  TestSession() : super(Dio());
  UserSession? _current = const UserSession(token: 'test', role: 'vecino');
  @override
  UserSession? get session => _current;

  @override
  void signOut() {
    _current = null;
    notifyListeners();
  }
}

void main() {
  testWidgets(
    'cerrar sesión elimina el estado privado sin errores de proveedores',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [sessionProvider.overrideWith((ref) => TestSession())],
          child: const TrackTrashApp(),
        ),
      );
      await tester.pump();
      await tester.tap(find.byTooltip('Cerrar sesión'));
      await tester.pumpAndSettle();
      expect(find.text('Probar como vecino'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'valida el formulario y muestra el recojo persistido por el repositorio',
    (tester) async {
      tester.view.physicalSize = const Size(430, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = FakePickupRepository();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sessionProvider.overrideWith((ref) => TestSession()),
            pickupRepositoryProvider.overrideWithValue(repo),
          ],
          child: const TrackTrashApp(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.byKey(const Key('new-pickup')), 250);
      await tester.ensureVisible(find.byKey(const Key('new-pickup')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('new-pickup')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('submit-pickup')));
      await tester.tap(find.byKey(const Key('submit-pickup')));
      await tester.pumpAndSettle();
      expect(repo.createCalls, 0);
      expect(
        find.text('Ingresa un peso mayor a 0 y hasta 500 kg.'),
        findsOneWidget,
      );
      await tester.enterText(find.byKey(const Key('pickup-kg')), '2,5');
      await tester.enterText(
        find.byKey(const Key('pickup-address')),
        'Av. Arequipa 123',
      );
      await tester.ensureVisible(find.byKey(const Key('submit-pickup')));
      await tester.tap(find.byKey(const Key('submit-pickup')));
      await tester.pumpAndSettle();
      expect(repo.createCalls, 1);
      expect(repo.lastDraft!.kg, 2.5);
      expect(find.text('Mis recojos'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Pendiente'), 250);
      expect(find.text('Pendiente'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
