import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/community/presentation/workspace_screen.dart';
import '../features/community/presentation/notices_page.dart';
import '../features/community/presentation/issues_page.dart';
import '../features/community/presentation/operation_page.dart';
import '../features/community/presentation/routes_page.dart';
import '../ui/eco_design.dart';
import '../features/session/login_screen.dart';
import '../features/pickups/presentation/create_pickup_screen.dart';
import '../features/session/welcome_screen.dart';
import 'providers.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final session = ref.read(sessionProvider);
  final router = GoRouter(
    refreshListenable: session,
    redirect: (context, state) {
      final signedIn = session.session != null;
      if (!signedIn) {
        if (state.matchedLocation == '/acceso') return null;
        return state.matchedLocation == '/bienvenida' ? null : '/bienvenida';
      }
      if (state.matchedLocation == '/bienvenida' ||
          state.matchedLocation == '/acceso') {
        return '/';
      }
      if (state.matchedLocation == '/operacion' &&
          session.session!.role != 'admin') {
        return '/';
      }
      if (session.session!.isRecycler &&
          state.matchedLocation == '/solicitar') {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/bienvenida', builder: (_, _) => const WelcomeScreen()),
      GoRoute(
        path: '/acceso',
        builder: (_, s) =>
            LoginScreen(register: s.uri.queryParameters['registro'] == 'true'),
      ),
      GoRoute(path: '/', builder: (_, _) => const WorkspaceScreen()),
      GoRoute(path: '/notificaciones', builder: (_, _) => const NoticesPage()),
      GoRoute(path: '/horarios', builder: (_, _) => const RoutesPage()),
      GoRoute(
        path: '/incidencias',
        builder: (_, s) => IssuesPage(
          initialContainerId: s.uri.queryParameters['contenedorId'],
        ),
      ),
      GoRoute(path: '/operacion', builder: (_, _) => const OperationPage()),
      GoRoute(
        path: '/solicitar',
        builder: (_, _) => const CreatePickupScreen(),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

class TrackTrashApp extends ConsumerWidget {
  const TrackTrashApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
    title: 'TrackTrash',
    debugShowCheckedModeBanner: false,
    locale: const Locale('es', 'PE'),
    supportedLocales: const [Locale('es', 'PE')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    theme: ecoTheme(),
    routerConfig: ref.watch(routerProvider),
  );
}
