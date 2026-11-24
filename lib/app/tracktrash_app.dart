import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/enums.dart';
import '../features/gatherer/gatherer_pages.dart';
import '../features/home/home_page.dart';
import '../features/points/points_page.dart';
import '../features/profile/profile_page.dart';
import '../features/requests/create_request_screen.dart';
import '../features/requests/request_detail_screen.dart';
import '../features/requests/requests_page.dart';
import '../features/session/access_screens.dart';
import '../ui/eco_design.dart';
import '../features/admin/admin_pages.dart';
import 'providers.dart';
import 'shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final session = ref.read(sessionProvider);
  final router = GoRouter(
    refreshListenable: session,
    redirect: (context, state) {
      if (session.restoring) return null;
      final location = state.matchedLocation;
      const publicRoutes = {'/bienvenida', '/acceso', '/registro'};
      if (!session.isSignedIn) {
        return publicRoutes.contains(location) ? null : '/bienvenida';
      }
      if (publicRoutes.contains(location)) return '/';
      final role = session.user!.role;
      if (location == '/solicitar' &&
          (role == UserRole.gatherer || role == UserRole.admin)) {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/bienvenida', builder: (_, _) => const WelcomeScreen()),
      GoRoute(path: '/acceso', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/registro', builder: (_, _) => const RegisterScreen()),
      GoRoute(
        path: '/solicitar',
        builder: (_, _) => const CreateRequestScreen(),
      ),
      GoRoute(path: '/catalogo', builder: (_, _) => const AdminCatalogScreen()),
      GoRoute(
        path: '/solicitudes/:id',
        builder: (_, state) => RequestDetailScreen(
          requestId: int.parse(state.pathParameters['id']!),
        ),
      ),
      ShellRoute(
        builder: (_, _, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/', builder: (_, _) => const HomePage()),
          GoRoute(
            path: '/solicitudes',
            builder: (_, _) => const RequestsPage(),
          ),
          GoRoute(
            path: '/disponibles',
            builder: (_, _) => const AvailablePage(),
          ),
          GoRoute(path: '/servicios', builder: (_, _) => const ServicesPage()),
          GoRoute(path: '/puntos', builder: (_, _) => const PointsPage()),
          GoRoute(path: '/perfil', builder: (_, _) => const ProfilePage()),
          GoRoute(
            path: '/recolectores',
            builder: (_, _) => const AdminGatherersPage(),
          ),
          GoRoute(path: '/usuarios', builder: (_, _) => const AdminUsersPage()),
        ],
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
