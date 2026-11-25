import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../ui/async_content.dart';
import '../../ui/eco_design.dart';
import '../../app/providers.dart';
import '../../data/enums.dart';
import '../../ui/filters.dart';
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
  String _query = '';
  RequestStatus? _status;
  int _page = 1;

  void _resetFilters() {
    setState(() {
      _query = '';
      _status = null;
      _page = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final requests = ref.watch(visibleRequestsProvider);
    final locations = ref.watch(locationByIdProvider);
    final isAdmin = ref.watch(sessionProvider).user?.role == UserRole.admin;
    return RefreshIndicator(
      onRefresh: () async {
        ref
          ..invalidate(visibleRequestsProvider)
          ..invalidate(requestDetailsProvider);
        await ref.read(visibleRequestsProvider.future);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        children: [
          Text(
            isAdmin ? 'Solicitudes' : 'Mis solicitudes',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 14),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('En curso')),
              ButtonSegment(value: false, label: Text('Terminadas')),
            ],
            selected: {_active},
            onSelectionChanged: (value) => setState(() {
              _active = value.first;
              _status = null;
              _page = 1;
            }),
          ),
          AsyncContent(
            value: requests,
            onRetry: () => ref.invalidate(visibleRequestsProvider),
            builder: (items) {
              final segment = items
                  .where((item) => item.status.isActive == _active)
                  .toList();
              if (segment.isEmpty) {
                return EcoEmpty(
                  title: _active
                      ? 'No tienes solicitudes en curso'
                      : 'Aún no hay solicitudes terminadas',
                  message: _active
                      ? 'Pide un recojo y sigue su estado desde aquí.'
                      : 'Cuando se complete o cancele un recojo aparecerá en esta lista.',
                  icon: Icons.inventory_2_outlined,
                  action: _active && !isAdmin
                      ? FilledButton(
                          onPressed: () => context.push('/solicitar'),
                          child: const Text('Nueva solicitud'),
                        )
                      : null,
                );
              }
              final statusOptions = _active
                  ? const [
                      RequestStatus.pending,
                      RequestStatus.assigned,
                      RequestStatus.inProgress,
                    ]
                  : const [RequestStatus.completed, RequestStatus.cancelled];
              final filtered = segment.where((item) {
                final location = locations[item.locationId];
                final matchesStatus = _status == null || item.status == _status;
                final matchesSearch = matchesQuery(_query, [
                  '#${item.id}',
                  location?.address,
                  location?.district,
                  item.observations,
                ]);
                return matchesStatus && matchesSearch;
              }).toList();
              final pageCount = (filtered.length / kPageSize).ceil();
              final page = pageCount == 0
                  ? 1
                  : _page.clamp(1, pageCount).toInt();
              final visible = pageOf(filtered, page);
              final activeFilters = _query.isNotEmpty || _status != null;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  SearchField(
                    value: _query,
                    hint: 'Buscar por N°, dirección o distrito',
                    onChanged: (value) => setState(() {
                      _query = value;
                      _page = 1;
                    }),
                  ),
                  const SizedBox(height: 12),
                  FilterChipsRow<RequestStatus>(
                    options: [
                      ChipOption(null, 'Todos', count: segment.length),
                      for (final status in statusOptions)
                        ChipOption(
                          status,
                          status.label,
                          count: segment
                              .where((item) => item.status == status)
                              .length,
                        ),
                    ],
                    selected: _status,
                    onSelected: (value) => setState(() {
                      _status = value;
                      _page = 1;
                    }),
                  ),
                  if (filtered.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    FilterSummary(
                      shown: filtered.length,
                      total: segment.length,
                      active: activeFilters,
                      onReset: _resetFilters,
                    ),
                    for (final (i, item) in visible.indexed)
                      RequestTile(request: item, index: i),
                    const SizedBox(height: 8),
                    PaginationBar(
                      page: page,
                      pageCount: pageCount,
                      total: filtered.length,
                      onChanged: (value) => setState(() => _page = value),
                    ),
                  ] else
                    EcoEmpty(
                      title: 'Sin resultados',
                      message:
                          'Prueba con otras palabras o limpia los filtros.',
                      icon: Icons.search_off_rounded,
                      action: TextButton(
                        onPressed: _resetFilters,
                        child: const Text('Limpiar filtros'),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
