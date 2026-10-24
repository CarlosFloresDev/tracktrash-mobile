import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../ui/eco_design.dart';
import '../../../ui/async_content.dart';
import 'community_providers.dart';

class OperationPage extends ConsumerWidget {
  const OperationPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(
      title: const Text('Panel de operación'),
      actions: [
        IconButton(
          tooltip: 'Actualizar indicadores',
          onPressed: () => ref.invalidate(metricsProvider),
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Una vista para actuar.',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 12),
            const Text(
              'Monitorea el estado de la red y prioriza la atención de tu comunidad.',
            ),
            const SizedBox(height: 24),
            AsyncContent(
              value: ref.watch(metricsProvider),
              onRetry: () => ref.invalidate(metricsProvider),
              builder: (m) => Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _Metric(
                    'Contenedores registrados',
                    '${m.bins}',
                    Icons.delete_outline,
                  ),
                  _Metric(
                    'Saturados con dato reciente',
                    '${m.full}',
                    Icons.warning_amber_rounded,
                  ),
                  _Metric(
                    'Incidencias por atender',
                    '${m.issues}',
                    Icons.report_outlined,
                  ),
                  _Metric(
                    'Recojos confirmados',
                    '${m.pickups}',
                    Icons.task_alt,
                  ),
                  _Metric(
                    'Kg estimados en entregas',
                    '${m.estimatedKg.toStringAsFixed(1)} kg',
                    Icons.eco_outlined,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.push('/incidencias'),
              icon: const Icon(Icons.support_agent),
              label: const Text('Gestionar incidencias'),
            ),
            const SizedBox(height: 18),
            const Text(
              'Los kilogramos son estimaciones registradas en las solicitudes confirmadas. Este panel no certifica peso real ni ahorro de CO₂.',
            ),
          ],
        ),
      ),
    ),
  );
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value, this.icon);
  final String label, value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 260,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: EcoColors.green),
            const SizedBox(height: 16),
            Text(value, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(label),
          ],
        ),
      ),
    ),
  );
}
