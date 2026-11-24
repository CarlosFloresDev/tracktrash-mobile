import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/providers.dart';
import '../../data/enums.dart';
import '../../data/models.dart';
import '../../ui/async_content.dart';
import '../../ui/eco_design.dart';
import '../../ui/widgets.dart';
import '../requests/request_providers.dart';
import '../requests/request_tile.dart';

/// Pending requests whose materials the verified gatherer accepts, plus their applications.
class AvailablePage extends ConsumerWidget {
  const AvailablePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gatherer = ref.watch(sessionProvider).gatherer;
    final pending = ref.watch(pendingRequestsProvider);
    final applications = ref.watch(myApplicationsProvider);
    return RefreshIndicator(
      onRefresh: () async {
        ref
          ..invalidate(pendingRequestsProvider)
          ..invalidate(myApplicationsProvider)
          ..invalidate(requestDetailsProvider);
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
            'Solicitudes pendientes con materiales que aceptas. Abre una y postúlate; el solicitante elige al recolector.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          if (gatherer == null || !gatherer.canTakeRequests)
            const EcoEmpty(
              title: 'Necesitas estar verificado',
              message:
                  'Cuando el equipo apruebe tu documento verás aquí los recojos disponibles.',
              icon: Icons.verified_user_outlined,
            )
          else if (gatherer.supportedResidueTypes.isEmpty)
            EcoEmpty(
              title: 'Elige los materiales que aceptas',
              message:
                  'Solo verás solicitudes cuyos materiales coincidan con tu selección.',
              icon: Icons.recycling_rounded,
              action: FilledButton(
                onPressed: () => context.go('/perfil'),
                child: const Text('Configurar materiales'),
              ),
            )
          else
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
          if ((applications.value ?? const []).isNotEmpty) ...[
            const SectionTitle('Mis postulaciones'),
            for (final item in applications.value!) _ApplicationTile(item),
          ],
        ],
      ),
    );
  }
}

class _ApplicationTile extends StatelessWidget {
  const _ApplicationTile(this.application);
  final PickupApplication application;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      onTap: () => context.push('/solicitudes/${application.collectRequestId}'),
      leading: Icon(switch (application.status) {
        ApplicationStatus.accepted => Icons.check_circle_rounded,
        ApplicationStatus.rejected => Icons.cancel_outlined,
        ApplicationStatus.withdrawn => Icons.undo_rounded,
        ApplicationStatus.pending => Icons.hourglass_top_rounded,
      }, color: EcoColors.green),
      title: Text('Solicitud #${application.collectRequestId}'),
      subtitle: Text(
        '${application.status.label} · ${formatTimestamp(application.appliedAt)}',
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
    ),
  );
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
                      ? 'Revisa los recojos disponibles y postúlate al que mejor te convenga.'
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
