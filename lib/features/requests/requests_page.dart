import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../ui/async_content.dart';
import '../../ui/eco_design.dart';
import 'request_providers.dart';
import 'request_tile.dart';

/// "Mis solicitudes" for households and organizations.
class RequestsPage extends ConsumerStatefulWidget {
  const RequestsPage({super.key});

  @override
  ConsumerState<RequestsPage> createState() => _RequestsPageState();
}

class _RequestsPageState extends ConsumerState<RequestsPage> {
  bool _active = true;

  @override
  Widget build(BuildContext context) {
    final requests = ref.watch(myRequestsProvider);
    return RefreshIndicator(
      onRefresh: () async {
        ref
          ..invalidate(myRequestsProvider)
          ..invalidate(detailsByRequestProvider);
        await ref.read(myRequestsProvider.future);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        children: [
          Text(
            'Mis solicitudes',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 14),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('En curso')),
              ButtonSegment(value: false, label: Text('Terminadas')),
            ],
            selected: {_active},
            onSelectionChanged: (value) =>
                setState(() => _active = value.first),
          ),
          const SizedBox(height: 16),
          AsyncContent(
            value: requests,
            onRetry: () => ref.invalidate(myRequestsProvider),
            builder: (items) {
              final visible = items
                  .where((item) => item.status.isActive == _active)
                  .toList();
              if (visible.isEmpty) {
                return EcoEmpty(
                  title: _active
                      ? 'No tienes solicitudes en curso'
                      : 'Aún no hay solicitudes terminadas',
                  message: _active
                      ? 'Pide un recojo y sigue su estado desde aquí.'
                      : 'Cuando se complete o cancele un recojo aparecerá en esta lista.',
                  icon: Icons.inventory_2_outlined,
                  action: _active
                      ? FilledButton(
                          onPressed: () => context.push('/solicitar'),
                          child: const Text('Nueva solicitud'),
                        )
                      : null,
                );
              }
              return Column(
                children: [
                  for (final (i, item) in visible.indexed)
                    RequestTile(request: item, index: i),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
