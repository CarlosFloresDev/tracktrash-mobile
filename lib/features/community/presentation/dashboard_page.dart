import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/providers.dart';
import '../../../ui/eco_design.dart';
import '../../../ui/async_content.dart';
import 'community_providers.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({
    super.key,
    required this.onExplore,
    required this.onPickups,
  });
  final VoidCallback onExplore, onPickups;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pickups = ref.watch(pickupsProvider).state;
    final session = ref.watch(sessionProvider).session!;
    final profile = ref.watch(profileProvider);
    final name = profile.valueOrNull?.name.split(' ').first;
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 30),
      children: [
        Text(
          name == null
              ? 'UN NUEVO DÍA, UNA NUEVA OPORTUNIDAD'
              : 'HOLA, ${name.toUpperCase()} ☀',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: EcoColors.green,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Pequeñas acciones.\nUna ciudad más viva.',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 10),
        const Text(
          'Conecta con tu comunidad y dale otra oportunidad a tus materiales.',
        ),
        const SizedBox(height: 22),
        EcoEntrance(
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: EcoColors.pine,
              borderRadius: BorderRadius.circular(28),
            ),
            child: LayoutBuilder(
              builder: (context, c) => Padding(
                padding: const EdgeInsets.fromLTRB(22, 22, 4, 18),
                child: Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'TU BARRIO, MÁS VERDE',
                            style: TextStyle(
                              color: EcoColors.lime,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Reciclar empieza\ncontigo.',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(color: Colors.white),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Tacho Vivo te ayuda\na dar el siguiente paso.',
                            style: TextStyle(color: Color(0xFFD7E5D7)),
                          ),
                          const SizedBox(height: 18),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: EcoColors.lime,
                              foregroundColor: EcoColors.pine,
                            ),
                            onPressed: onExplore,
                            child: const Text('Explorar mi zona'),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Image.asset(
                        'assets/images/tacho-vivo.png',
                        height: c.maxWidth > 600 ? 240 : 210,
                        fit: BoxFit.contain,
                        semanticLabel:
                            'Tacho Vivo, nuestro compañero de reciclaje',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _Stat(
              icon: Icons.stars_outlined,
              value: '${pickups.points}',
              label: 'puntos disponibles',
            ),
            _Stat(
              icon: Icons.task_alt,
              value:
                  '${pickups.items.where((p) => p.status == 'Confirmada').length}',
              label: 'entregas en la lista',
            ),
          ],
        ),
        const SectionTitle('¿Qué hacemos hoy?'),
        if (!session.isRecycler && session.role != 'admin')
          FilledButton.icon(
            key: const Key('new-pickup'),
            onPressed: () => context.push('/solicitar'),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Solicitar un recojo'),
          ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _Action(
                icon: Icons.map_outlined,
                label: 'Puntos cercanos',
                onTap: onExplore,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _Action(
                icon: Icons.report_outlined,
                label: 'Mis reportes',
                onTap: () => context.push('/incidencias'),
              ),
            ),
          ],
        ),
        if (session.role == 'admin')
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: OutlinedButton.icon(
              onPressed: () => context.push('/operacion'),
              icon: const Icon(Icons.dashboard_outlined),
              label: const Text('Abrir panel de operación'),
            ),
          ),
        SectionTitle(
          'Mis recojos',
          trailing: TextButton(
            onPressed: onPickups,
            child: const Text('Ver todos'),
          ),
        ),
        if (pickups.loading) const LinearProgressIndicator(),
        if (pickups.error != null)
          EcoEmpty(
            title: 'No pudimos actualizar tus recojos',
            message: pickups.error!,
            action: TextButton(
              onPressed: () => ref.read(pickupsProvider).load(),
              child: const Text('Reintentar'),
            ),
          ),
        if (pickups.items.isEmpty && !pickups.loading && pickups.error == null)
          const EcoEmpty(
            title: 'Todo empieza con una entrega',
            message: 'Separa tus materiales y coordina tu primer recojo.',
          ),
        ...pickups.items
            .take(2)
            .map(
              (p) => Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(18),
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFEEF5E6),
                    child: Icon(
                      Icons.inventory_2_outlined,
                      color: EcoColors.green,
                    ),
                  ),
                  title: Text(p.materialLabel),
                  subtitle: Text('${p.estimatedKg} kg estimados'),
                  trailing: Text(p.status),
                  onTap: onPickups,
                ),
              ),
            ),
        const SectionTitle('Antes de sacar tus residuos'),
        Card(
          child: ListTile(
            contentPadding: const EdgeInsets.all(18),
            leading: const Icon(Icons.schedule, color: EcoColors.green),
            title: const Text('Horarios de recolección'),
            subtitle: const Text('Consulta rutas y activa recordatorios.'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/horarios'),
          ),
        ),
        const SectionTitle('Tu comunidad en el mapa'),
        AsyncContent(
          value: ref.watch(mapProvider),
          onRetry: () => ref.invalidate(mapProvider),
          builder: (map) => Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(18),
              leading: const Icon(
                Icons.location_on_outlined,
                color: EcoColors.green,
              ),
              title: Text('${map.places.length} puntos en esta zona'),
              subtitle: Text(
                map.cached
                    ? 'Última información guardada · puede estar desactualizada'
                    : 'Contenedores, asociaciones y puntos de acopio',
              ),
              trailing: const Icon(Icons.arrow_forward),
              onTap: onExplore,
            ),
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.value, required this.label});
  final IconData icon;
  final String value, label;
  @override
  Widget build(BuildContext context) => Container(
    width: MediaQuery.sizeOf(context).width < 600
        ? (MediaQuery.sizeOf(context).width - 60) / 2
        : 220,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: EcoColors.green),
        const SizedBox(height: 10),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Text(
            value,
            key: ValueKey(value),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
        Text(label),
      ],
    ),
  );
}

class _Action extends StatelessWidget {
  const _Action({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: EcoColors.green),
            const SizedBox(height: 14),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: EcoColors.pine,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
