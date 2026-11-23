import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/enums.dart';
import 'providers.dart';

class _Destination {
  const _Destination(this.path, this.label, this.icon, this.selectedIcon);
  final String path;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

const _home = _Destination(
  '/',
  'Inicio',
  Icons.home_outlined,
  Icons.home_rounded,
);
const _requests = _Destination(
  '/solicitudes',
  'Solicitudes',
  Icons.assignment_outlined,
  Icons.assignment_rounded,
);
const _available = _Destination(
  '/disponibles',
  'Disponibles',
  Icons.inventory_2_outlined,
  Icons.inventory_2_rounded,
);
const _services = _Destination(
  '/servicios',
  'Servicios',
  Icons.local_shipping_outlined,
  Icons.local_shipping_rounded,
);
const _points = _Destination(
  '/puntos',
  'Acopio',
  Icons.recycling_outlined,
  Icons.recycling_rounded,
);
const _profile = _Destination(
  '/perfil',
  'Perfil',
  Icons.person_outline_rounded,
  Icons.person_rounded,
);

List<_Destination> _destinationsFor(UserRole role) => switch (role) {
  UserRole.gatherer => const [_home, _available, _services, _points, _profile],
  UserRole.admin => const [_home, _points, _profile],
  _ => const [_home, _requests, _points, _profile],
};

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    if (session.restoring || session.user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final role = session.user!.role;
    final destinations = _destinationsFor(role);
    final location = GoRouterState.of(context).matchedLocation;
    final index = destinations
        .indexWhere((item) => item.path == location)
        .clamp(0, destinations.length - 1);
    final canRequest =
        role == UserRole.generator || role == UserRole.organization;

    return Scaffold(
      appBar: AppBar(title: const Text('TrackTrash'), centerTitle: false),
      body: SafeArea(child: child),
      floatingActionButton:
          canRequest && (location == '/' || location == '/solicitudes')
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/solicitar'),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Nueva solicitud'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => context.go(destinations[value].path),
        destinations: [
          for (final item in destinations)
            NavigationDestination(
              icon: Icon(item.icon),
              selectedIcon: Icon(item.selectedIcon),
              label: item.label,
            ),
        ],
      ),
    );
  }
}
