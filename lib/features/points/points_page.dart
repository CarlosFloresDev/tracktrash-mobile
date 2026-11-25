import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../app/providers.dart';
import '../../core/config.dart';
import '../../data/models.dart';
import '../../ui/async_content.dart';
import '../../ui/eco_design.dart';
import '../../ui/filters.dart';
import '../../ui/widgets.dart';

final collectionPointsProvider =
    FutureProvider.autoDispose<List<CollectionPoint>>((ref) async {
      final points = await ref.watch(apiProvider).collectionPoints();
      await ref.watch(locationsProvider.future);
      return points.where((item) => item.isActive).toList();
    });

class PointsPage extends ConsumerStatefulWidget {
  const PointsPage({super.key});

  @override
  ConsumerState<PointsPage> createState() => _PointsPageState();
}

class _PointsPageState extends ConsumerState<PointsPage> {
  final _controller = MapController();
  int? _selected;
  String _query = '';
  String? _district;
  int _page = 1;

  void _resetFilters() {
    setState(() {
      _query = '';
      _district = null;
      _page = 1;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _select(CollectionPoint point, Location? location) {
    setState(() => _selected = point.id);
    if (location != null && location.hasCoordinates) {
      _controller.move(LatLng(location.latitude!, location.longitude!), 15);
    }
  }

  @override
  Widget build(BuildContext context) {
    final points = ref.watch(collectionPointsProvider);
    final locations = ref.watch(locationByIdProvider);
    return AsyncContent(
      value: points,
      onRetry: () {
        ref
          ..invalidate(collectionPointsProvider)
          ..invalidate(locationsProvider);
      },
      builder: (items) {
        if (items.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: EcoEmpty(
              title: 'Aún no hay puntos de acopio',
              message: 'Cuando el equipo registre puntos, aparecerán aquí.',
              icon: Icons.recycling_rounded,
            ),
          );
        }
        final districts = [
          for (final district
              in items
                  .map((item) => locations[item.locationId]?.district)
                  .whereType<String>()
                  .toSet())
            district,
        ]..sort();
        final filtered = items.where((item) {
          final location = locations[item.locationId];
          final matchesDistrict =
              _district == null || location?.district == _district;
          final matchesSearch = matchesQuery(_query, [
            item.name,
            location?.address,
            location?.district,
            item.openingHours,
            item.description,
          ]);
          return matchesDistrict && matchesSearch;
        }).toList();
        final pageCount = (filtered.length / kPageSize).ceil();
        final page = pageCount == 0 ? 1 : _page.clamp(1, pageCount).toInt();
        final visible = pageOf(filtered, page);
        final activeFilters = _query.isNotEmpty || _district != null;
        final withCoordinates = [
          for (final item in filtered)
            if (locations[item.locationId]?.hasCoordinates ?? false) item,
        ];
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Puntos de acopio',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SearchField(
                    value: _query,
                    hint: 'Buscar punto, dirección u horario',
                    onChanged: (value) => setState(() {
                      _query = value;
                      _page = 1;
                    }),
                  ),
                  const SizedBox(height: 12),
                  FilterChipsRow<String>(
                    options: [
                      const ChipOption(null, 'Todos'),
                      for (final district in districts)
                        ChipOption(district, district),
                    ],
                    selected: _district,
                    onSelected: (value) => setState(() {
                      _district = value;
                      _page = 1;
                    }),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 260,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: FlutterMap(
                  mapController: _controller,
                  options: const MapOptions(
                    initialCenter: LatLng(
                      AppConfig.defaultLatitude,
                      AppConfig.defaultLongitude,
                    ),
                    initialZoom: 12.5,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'pe.tracktrash.mobile',
                    ),
                    MarkerLayer(
                      markers: [
                        for (final item in withCoordinates)
                          Marker(
                            point: LatLng(
                              locations[item.locationId]!.latitude!,
                              locations[item.locationId]!.longitude!,
                            ),
                            width: 48,
                            height: 48,
                            child: Semantics(
                              button: true,
                              label: item.name,
                              child: GestureDetector(
                                onTap: () =>
                                    _select(item, locations[item.locationId]),
                                child: Icon(
                                  Icons.location_on_rounded,
                                  size: item.id == _selected ? 46 : 38,
                                  color: item.id == _selected
                                      ? EcoColors.pine
                                      : EcoColors.green,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const RichAttributionWidget(
                      attributions: [TextSourceAttribution('OpenStreetMap')],
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                children: [
                  if (filtered.isNotEmpty) ...[
                    FilterSummary(
                      shown: filtered.length,
                      total: items.length,
                      active: activeFilters,
                      onReset: _resetFilters,
                    ),
                    const SizedBox(height: 12),
                    for (final item in visible)
                      _PointCard(
                        point: item,
                        location: locations[item.locationId],
                        selected: item.id == _selected,
                        onTap: () => _select(item, locations[item.locationId]),
                      ),
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
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PointCard extends StatelessWidget {
  const _PointCard({
    required this.point,
    required this.location,
    required this.selected,
    required this.onTap,
  });
  final CollectionPoint point;
  final Location? location;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24),
      side: BorderSide(
        color: selected ? EcoColors.green : const Color(0xFFE6EBE1),
        width: selected ? 2 : 1,
      ),
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(point.name, style: Theme.of(context).textTheme.titleLarge),
            if (point.description != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(point.description!),
              ),
            const SizedBox(height: 8),
            if (location != null)
              InfoRow(icon: Icons.place_outlined, text: location!.summary),
            if (point.openingHours != null)
              InfoRow(icon: Icons.schedule_rounded, text: point.openingHours!),
            if (point.managerName != null)
              InfoRow(
                icon: Icons.person_outline_rounded,
                text: 'Encargado: ${point.managerName}',
              ),
            if (point.phone != null)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.only(right: 8),
                    minimumSize: const Size(0, 40),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: const TextStyle(fontSize: 15),
                  ),
                  onPressed: () =>
                      launchUrl(Uri(scheme: 'tel', path: point.phone)),
                  icon: const Icon(Icons.call_outlined, size: 20),
                  label: Text(point.phone!),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
