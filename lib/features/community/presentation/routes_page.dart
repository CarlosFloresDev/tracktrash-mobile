import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../ui/eco_design.dart';
import '../../../ui/async_content.dart';
import 'community_providers.dart';

class RoutesPage extends ConsumerWidget {
  const RoutesPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = ref.watch(communityActionsProvider);
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
                    ...items.map(
                      (r) => Card(
                        child: Padding(
                          padding: const EdgeInsets.all(22),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                                      r['nombre'] as String,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(r['zona'] as String),
                              const SizedBox(height: 8),
                              Text(
                                'Próximo horario: ${DateFormat('EEE d MMM · HH:mm', 'es_PE').format(DateTime.parse(r['proximoPaso'] as String).toLocal())}',
                              ),
                              if (r['demostracion'] == true)
                                const Padding(
                                  padding: EdgeInsets.only(top: 10),
                                  child: Text(
                                    'Horario sintético de demostración, sin convenio municipal real.',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                              const SizedBox(height: 14),
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text(
                                  'Recordarme 20 minutos antes',
                                ),
                                subtitle: const Text(
                                  'Aviso en la bandeja de TrackTrash.',
                                ),
                                value: r['suscrito'] as bool,
                                onChanged: actions.busy
                                    ? null
                                    : (v) => actions.subscribe(
                                        r['id'] as String,
                                        v,
                                      ),
                              ),
                              TextButton.icon(
                                onPressed: actions.busy
                                    ? null
                                    : () async {
                                        final ok = await actions.reportPass(
                                          r['id'] as String,
                                        );
                                        if (ok && context.mounted)
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Paso registrado como reporte vecinal no verificado.',
                                              ),
                                            ),
                                          );
                                      },
                                icon: const Icon(Icons.campaign_outlined),
                                label: const Text(
                                  'Reportar que el camión pasó',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
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
