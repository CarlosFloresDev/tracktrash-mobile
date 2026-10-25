import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../ui/eco_design.dart';
import '../../../ui/async_content.dart';
import '../domain/community_models.dart';
import 'community_providers.dart';

class RoutesPage extends ConsumerWidget {
  const RoutesPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = ref.watch(communityActionsProvider);
    final profile = ref.watch(profileProvider).valueOrNull;
    final paused =
        profile != null &&
        (!profile.alerts || !profile.notificationPreferences.schedules);
    return Scaffold(
      appBar: AppBar(title: const Text('Horarios de recolección')),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.all(22),
            children: [
              Text(
                'Prepara tu día,\ncuida tu barrio.',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 14),
              const Text(
                'Estos avisos se basan en horarios programados. No indican la ubicación ni una llegada calculada con GPS.',
              ),
              if (paused)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Text(
                    'Tus avisos de horarios están pausados en Perfil. Las suscripciones se conservan; activa esos avisos para recibir nuevos recordatorios.',
                  ),
                ),
              const SizedBox(height: 22),
              if (actions.error != null)
                Text(
                  actions.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              AsyncContent(
                value: ref.watch(routesProvider),
                onRetry: () => ref.invalidate(routesProvider),
                builder: (items) => Column(
                  children: [
                    if (items.isEmpty)
                      const EcoEmpty(
                        title: 'Aún no hay horarios publicados',
                        message:
                            'Las rutas aparecerán cuando se registren horarios verificados.',
                      ),
                    for (final route in items)
                      _RouteCard(key: ValueKey(route.id), route: route),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RouteCard extends ConsumerStatefulWidget {
  const _RouteCard({super.key, required this.route});
  final RouteSchedule route;
  @override
  ConsumerState<_RouteCard> createState() => _RouteCardState();
}

class _RouteCardState extends ConsumerState<_RouteCard> {
  late int _minutes;
  @override
  void initState() {
    super.initState();
    _minutes = widget.route.minutesBefore ?? 20;
  }

  @override
  void didUpdateWidget(covariant _RouteCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.route.minutesBefore != widget.route.minutesBefore ||
        oldWidget.route.subscribed != widget.route.subscribed) {
      _minutes = widget.route.minutesBefore ?? 20;
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.route;
    final actions = ref.watch(communityActionsProvider);
    final options = {for (var n = 5; n <= 60; n += 5) n, _minutes}.toList()
      ..sort();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.local_shipping_outlined,
                  color: EcoColors.green,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    r.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(r.zone),
            const SizedBox(height: 8),
            Text(
              'Próximo horario: ${DateFormat('EEE d MMM · HH:mm', 'es_PE').format(r.nextPass)}',
            ),
            if (r.demo)
              const Padding(
                padding: EdgeInsets.only(top: 10),
                child: Text(
                  'Horario sintético de demostración, sin convenio municipal real.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            const SizedBox(height: 20),
            DropdownButtonFormField<int>(
              key: ValueKey('route-minutes-${r.id}-$_minutes'),
              initialValue: _minutes,
              decoration: const InputDecoration(
                labelText: 'Anticipación del aviso',
              ),
              isExpanded: true,
              items: [
                for (final n in options)
                  DropdownMenuItem(value: n, child: Text('$n minutos antes')),
              ],
              onChanged: actions.busy
                  ? null
                  : (v) {
                      if (v != null) setState(() => _minutes = v);
                    },
            ),
            SwitchListTile(
              key: ValueKey('route-subscribe-${r.id}'),
              contentPadding: EdgeInsets.zero,
              title: const Text('Activar recordatorio'),
              subtitle: const Text('Aviso en la bandeja de TrackTrash.'),
              value: r.subscribed,
              onChanged: actions.busy
                  ? null
                  : (v) => actions.subscribe(r.id, v, minutesBefore: _minutes),
            ),
            if (r.subscribed && _minutes != (r.minutesBefore ?? 20))
              FilledButton(
                onPressed: actions.busy
                    ? null
                    : () => actions.subscribe(
                        r.id,
                        true,
                        minutesBefore: _minutes,
                      ),
                child: const Text('Guardar anticipación'),
              ),
            TextButton.icon(
              onPressed: actions.busy
                  ? null
                  : () async {
                      final ok = await actions.reportPass(r.id);
                      if (ok && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Paso registrado como reporte vecinal no verificado.',
                            ),
                          ),
                        );
                      }
                    },
              icon: const Icon(Icons.campaign_outlined),
              label: const Text('Reportar que el camión pasó'),
            ),
          ],
        ),
      ),
    );
  }
}
