import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../ui/async_content.dart';
import '../../ui/eco_design.dart';
import '../requests/request_providers.dart';
import '../requests/request_tile.dart';

/// Pending requests that any verified gatherer can take.
class AvailablePage extends ConsumerWidget {
  const AvailablePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(pendingRequestsProvider);
    return RefreshIndicator(
      onRefresh: () async {
        ref
          ..invalidate(pendingRequestsProvider)
          ..invalidate(detailsByRequestProvider);
        await ref.read(pendingRequestsProvider.future);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        children: [
          Text(
            'Recojos disponibles',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Solicitudes pendientes sin recolector. Abre una para ver detalles y tomarla.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          AsyncContent(
            value: pending,
            onRetry: () => ref.invalidate(pendingRequestsProvider),
            builder: (items) => items.isEmpty
                ? const EcoEmpty(
                    title: 'No hay recojos pendientes',
                    message: 'Cuando alguien pida un recojo aparecerá aquí.',
                    icon: Icons.inventory_2_outlined,
                  )
                : Column(
                    children: [
                      for (final (i, item) in items.indexed)
                        RequestTile(request: item, index: i),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

/// Services the signed-in gatherer already took, split into in-progress and finished.
class ServicesPage extends ConsumerStatefulWidget {
  const ServicesPage({super.key});

  @override
  ConsumerState<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends ConsumerState<ServicesPage> {
  bool _active = true;

  @override
  Widget build(BuildContext context) {
    final services = ref.watch(gathererRequestsProvider);
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(gathererRequestsProvider);
        await ref.read(gathererRequestsProvider.future);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        children: [
          Text(
            'Mis servicios',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 14),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('En curso')),
              ButtonSegment(value: false, label: Text('Terminados')),
            ],
            selected: {_active},
            onSelectionChanged: (value) =>
                setState(() => _active = value.first),
          ),
          const SizedBox(height: 16),
          AsyncContent(
            value: services,
            onRetry: () => ref.invalidate(gathererRequestsProvider),
            builder: (items) {
              final visible = items
                  .where(
                    (item) =>
                        (item.service?.status.isActive ?? false) == _active,
                  )
                  .toList();
              if (visible.isEmpty) {
                return EcoEmpty(
                  title: _active
                      ? 'No tienes servicios en curso'
                      : 'Aún no terminaste servicios',
                  message: _active
                      ? 'Revisa los recojos disponibles y toma el que mejor te convenga.'
                      : 'Los recojos completados o soltados aparecerán aquí.',
                  icon: Icons.local_shipping_outlined,
                );
              }
              return Column(
                children: [
                  for (final item in visible)
                    RequestTile(request: item.request, location: item.location),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
