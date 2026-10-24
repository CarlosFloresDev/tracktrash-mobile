import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/pickups/presentation/home_screen.dart';
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
        return state.matchedLocation == '/bienvenida' ? null : '/bienvenida';
      }
      if (state.matchedLocation == '/bienvenida') return '/';
      if (session.session!.isRecycler &&
          state.matchedLocation == '/solicitar') {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/bienvenida', builder: (_, _) => const WelcomeScreen()),
      GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
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
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF087F5B),
        primary: const Color(0xFF087F5B),
        surface: const Color(0xFFF6FAF7),
      ),
      scaffoldBackgroundColor: const Color(0xFFF6FAF7),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      cardTheme: const CardThemeData(
        elevation: 0,
        color: Colors.white,
        margin: EdgeInsets.only(bottom: 12),
      ),
    ),
    routerConfig: ref.watch(routerProvider),
  );
}
