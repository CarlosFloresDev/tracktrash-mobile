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
  @override
  UserSession get session => const UserSession(token: 'test', role: 'vecino');
}

void main() {
  testWidgets(
    'valida el formulario y muestra el recojo persistido por el repositorio',
    (tester) async {
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
      expect(find.text('Pendiente'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
