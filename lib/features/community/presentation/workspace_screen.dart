import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/providers.dart';
import '../../../core/config.dart';
import '../../../ui/eco_design.dart';
import 'dashboard_page.dart';
import 'explore_page.dart';
import 'impact_page.dart';
import 'profile_page.dart';
import 'pickups_page.dart';

class WorkspaceScreen extends ConsumerStatefulWidget {
  const WorkspaceScreen({super.key});
  @override
  ConsumerState<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends ConsumerState<WorkspaceScreen> {
  int _index = 0;
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) ref.read(pickupsProvider).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider).session;
    if (session == null) return const SizedBox.shrink();
    final titles = ['Inicio', 'Explorar', 'Recojos', 'Mi impacto', 'Perfil'];
    final body = switch (_index) {
      0 => DashboardPage(
        onExplore: () => setState(() => _index = 1),
        onPickups: () => setState(() => _index = 2),
      ),
      1 => const ExplorePage(),
      2 => const PickupsPage(),
      3 => const ImpactPage(),
      _ => const ProfilePage(),
    };
    final wide = MediaQuery.sizeOf(context).width >= 1000;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.recycling_rounded, color: EcoColors.green),
            const SizedBox(width: 8),
            const Flexible(
              child: Text(
                'TrackTrash',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (wide) ...[
              const SizedBox(width: 22),
              Text(
                titles[_index],
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ],
        ),
        actions: [
          if (AppConfig.demoMode)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Chip(label: Text('Demo', style: TextStyle(fontSize: 11))),
            ),
          IconButton(
            tooltip: 'Notificaciones',
            onPressed: () => context.push('/notificaciones'),
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: () => ref.read(sessionProvider).signOut(),
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: Row(
        children: [
          if (wide)
            NavigationRail(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              labelType: NavigationRailLabelType.all,
              backgroundColor: EcoColors.background,
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: Text('Inicio'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.map_outlined),
                  label: Text('Explorar'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.local_shipping_outlined),
                  label: Text('Recojos'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.eco_outlined),
                  label: Text('Impacto'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.person_outline),
                  label: Text('Perfil'),
                ),
              ],
            ),
          Expanded(
            child: AnimatedSwitcher(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 200),
              child: KeyedSubtree(
                key: ValueKey(_index),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: body,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: 'Inicio',
                ),
                NavigationDestination(
                  icon: Icon(Icons.map_outlined),
                  label: 'Explorar',
                ),
                NavigationDestination(
                  icon: Icon(Icons.local_shipping_outlined),
                  label: 'Recojos',
                ),
                NavigationDestination(
                  icon: Icon(Icons.eco_outlined),
                  label: 'Impacto',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  label: 'Perfil',
                ),
              ],
            ),
    );
  }
}
