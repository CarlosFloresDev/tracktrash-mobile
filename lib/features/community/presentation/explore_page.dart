import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../ui/eco_design.dart';
import '../../../ui/async_content.dart';
import '../domain/community_models.dart';
import 'community_providers.dart';

class ExplorePage extends ConsumerStatefulWidget {
  const ExplorePage({super.key});
  @override
  ConsumerState<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends ConsumerState<ExplorePage> {
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted &&
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        ref.invalidate(mapProvider);
      }
    });
  }

  final _controller = MapController();
  String _filter = 'todos';
  bool _list = false;
  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(22),
    children: [
      Text(
        'Tu ciudad, conectada.',
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      const SizedBox(height: 8),
      const Text(
        'Encuentra un lugar para reciclar y conoce el estado de los contenedores.',
      ),
      const SizedBox(height: 18),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final item in [
            ('todos', 'Todos'),
            ('contenedor', 'Contenedores'),
            ('asociacion', 'Aliados'),
            ('acopio', 'Acopio'),
          ])
            ChoiceChip(
              label: Text(item.$2),
              selected: _filter == item.$1,
              onSelected: (_) => setState(() => _filter = item.$1),
            ),
          IconButton(
            tooltip: _list ? 'Mostrar mapa' : 'Mostrar lista',
            onPressed: () => setState(() => _list = !_list),
            icon: Icon(_list ? Icons.map_outlined : Icons.format_list_bulleted),
          ),
        ],
      ),
      const SizedBox(height: 12),
      AsyncContent(
        value: ref.watch(mapProvider),
        onRetry: () => ref.invalidate(mapProvider),
        builder: (map) {
          final places = map.places
              .where((p) => _filter == 'todos' || p.kind == _filter)
              .toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (map.cached)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Sin conexión: últimos puntos guardados. Sus estados pueden estar desactualizados; el mapa base requiere internet.',
                  ),
                ),
              if (map.places.any((p) => p.demo))
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Ubicaciones de demostración · no son aliados ni convenios reales.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              if (!_list)
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: SizedBox(
                    height: 380,
                    child: Stack(
                      children: [
                        FlutterMap(
                          mapController: _controller,
                          options: const MapOptions(
                            initialCenter: LatLng(-16.3988, -71.5369),
                            initialZoom: 14,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: const String.fromEnvironment(
                                'MAP_TILE_URL',
                                defaultValue:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              ),
                              userAgentPackageName: 'pe.tracktrash.mobile',
                            ),
                            MarkerLayer(
                              markers: places
                                  .map(
                                    (p) => Marker(
                                      point: LatLng(p.lat, p.lng),
                                      width: 48,
                                      height: 48,
                                      child: Semantics(
                                        label: p.name,
                                        button: true,
                                        child: GestureDetector(
                                          onTap: () => _details(p),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: _color(p),
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.white,
                                                width: 3,
                                              ),
                                              boxShadow: const [
                                                BoxShadow(
                                                  color: Color(0x33000000),
                                                  blurRadius: 8,
                                                ),
                                              ],
                                            ),
                                            child: Icon(
                                              _icon(p),
                                              color: Colors.white,
                                              size: 24,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                            SimpleAttributionWidget(
                              source: const Text(
                                'OpenStreetMap contributors',
                                style: TextStyle(fontSize: 10),
                              ),
                              onTap: () => launchUrl(
                                Uri.parse(
                                  'https://www.openstreetmap.org/copyright',
                                ),
                              ),
                            ),
                          ],
                        ),
                        Positioned(
                          right: 12,
                          top: 12,
                          child: FloatingActionButton.small(
                            heroTag: 'location',
                            tooltip: 'Mi ubicación',
                            onPressed: _locate,
                            backgroundColor: Colors.white,
                            child: const Icon(
                              Icons.my_location,
                              color: EcoColors.pine,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              SectionTitle(
                '${places.length} puntos para explorar',
                trailing: IconButton(
                  tooltip: 'Actualizar mapa',
                  onPressed: () => ref.invalidate(mapProvider),
                  icon: const Icon(Icons.refresh),
                ),
              ),
              if (places.isEmpty)
                const EcoEmpty(
                  title: 'Sin puntos con este filtro',
                  message: 'Prueba otra categoría o actualiza el mapa.',
                ),
              ...places.map(
                (p) => Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: _color(p).withValues(alpha: .12),
                      child: Icon(_icon(p), color: _color(p)),
                    ),
                    title: Text(p.name),
                    subtitle: Text(
                      p.kind == 'contenedor'
                          ? '${p.percent == null ? 'Nivel desconocido' : '${p.percent}% de llenado'} · ${_status(p.status)}'
                          : p.address,
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _details(p),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    ],
  );
  Color _color(MapPlace p) => p.kind != 'contenedor'
      ? EcoColors.green
      : switch (p.status) {
          'Saturado' => const Color(0xFFB94B37),
          'Atencion' => const Color(0xFFB88022),
          'Disponible' => EcoColors.green,
          _ => Colors.blueGrey,
        };
  IconData _icon(MapPlace p) => switch (p.kind) {
    'contenedor' => Icons.delete_outline,
    'asociacion' => Icons.recycling,
    _ => Icons.location_on_outlined,
  };
  String _status(String s) => switch (s) {
    'SinDatosRecientes' => 'sin datos recientes',
    'Atencion' => 'requiere atención',
    _ => s.toLowerCase(),
  };
  void _details(MapPlace p) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(_icon(p), color: _color(p), size: 40),
            const SizedBox(height: 16),
            Text(p.name, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            if (p.kind == 'contenedor') ...[
              Text('${p.percent ?? '—'}% · ${_status(p.status)}'),
              Text('Fuente: ${p.source}'),
              if (p.updatedAt != null)
                Text('Actualizado: ${p.updatedAt!.toLocal()}'),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.push('/incidencias?contenedorId=${p.id}');
                },
                icon: const Icon(Icons.report_outlined),
                label: const Text('Reportar un problema'),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _level(p);
                },
                child: const Text('Reportar nivel estimado'),
              ),
            ] else ...[
              Text(p.address),
              if (p.materials.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    'Materiales: ${p.materials.map((m) => m == 'PapelCarton' ? 'Papel y cartón' : m).join(', ')}',
                  ),
                ),
            ],
            if (p.demo)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text(
                  'Punto sintético para demostración.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    ),
  );
  Future<void> _locate() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) throw Exception();
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception();
      }
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          timeLimit: Duration(seconds: 12),
        ),
      );
      if (mounted) _controller.move(LatLng(p.latitude, p.longitude), 15);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No pudimos acceder a tu ubicación. Puedes explorar el mapa manualmente.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _level(MapPlace p) async {
    double level = (p.percent ?? 50).toDouble();
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, update) => AlertDialog(
          title: const Text('¿Qué tan lleno está?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${level.round()}%',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              Slider(
                value: level,
                min: 0,
                max: 100,
                divisions: 10,
                label: '${level.round()}%',
                onChanged: (v) => update(() => level = v),
              ),
              const Text(
                'Estimación visual no verificada. No otorga puntos ni reemplaza una lectura reciente del sensor.',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Volver'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, level.round()),
              child: const Text('Enviar nivel'),
            ),
          ],
        ),
      ),
    );
    if (result != null && mounted) {
      final ok = await ref
          .read(communityActionsProvider)
          .reportLevel(p.id, result);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ok
                  ? 'Nivel reportado. Gracias por colaborar.'
                  : ref.read(communityActionsProvider).error ??
                        'No se pudo reportar el nivel.',
            ),
          ),
        );
      }
    }
  }
}
