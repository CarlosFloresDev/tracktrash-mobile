import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/providers.dart';
import '../../data/enums.dart';
import '../../ui/async_content.dart';
import '../../ui/eco_design.dart';
import '../../ui/widgets.dart';
import '../requests/request_providers.dart';
import '../requests/request_tile.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final user = session.user!;
    return RefreshIndicator(
      onRefresh: () async {
        ref
          ..invalidate(myRequestsProvider)
          ..invalidate(pendingRequestsProvider)
          ..invalidate(gathererRequestsProvider)
          ..invalidate(gathererKilogramsProvider)
          ..invalidate(gathererRatingProvider)
          ..invalidate(generalIndicatorsProvider);
        await session.refresh();
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        children: [
          EcoEntrance(
            child: EcoHeroBanner(
              title: 'Hola, ${user.firstName}',
              subtitle: session.organization?.businessName ?? user.role.label,
            ),
          ),
          const SizedBox(height: 18),
          switch (user.role) {
            UserRole.gatherer => const _GathererHome(),
            UserRole.admin => const _AdminHome(),
            _ => const _ResidentHome(),
          },
        ],
      ),
    );
  }
}

class _ResidentHome extends ConsumerWidget {
  const _ResidentHome();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(myRequestsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AsyncContent(
          value: requests,
          onRetry: () => ref.invalidate(myRequestsProvider),
          builder: (items) {
            final active = items.where((item) => item.status.isActive).length;
            final done = items
                .where((item) => item.status == RequestStatus.completed)
                .length;
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: StatTile(
                        label: 'Recojos activos',
                        value: '$active',
                        icon: Icons.local_shipping_outlined,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatTile(
                        label: 'Completados',
                        value: '$done',
                        icon: Icons.check_circle_outline_rounded,
                        highlight: true,
                      ),
                    ),
                  ],
                ),
                const SectionTitle('Últimas solicitudes'),
                if (items.isEmpty)
                  EcoEmpty(
                    title: 'Aún no pediste ningún recojo',
                    message:
                        'Cuéntanos qué materiales tienes y coordinamos el resto.',
                    action: FilledButton(
                      onPressed: () => context.push('/solicitar'),
                      child: const Text('Crear mi primera solicitud'),
                    ),
                  )
                else
                  for (final (i, item) in items.take(4).indexed)
                    RequestTile(request: item, index: i),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _GathererHome extends ConsumerWidget {
  const _GathererHome();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final gatherer = session.gatherer;
    final services = ref.watch(gathererRequestsProvider);
    final kilograms = ref.watch(gathererKilogramsProvider);
    final rating = ref.watch(gathererRatingProvider);
    final pending = ref.watch(pendingRequestsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (gatherer == null)
          const EcoEmpty(
            title: 'Sin perfil de recolector',
            message:
                'Tu usuario no tiene un perfil de recolector. Pide al equipo que lo registre.',
            icon: Icons.badge_outlined,
          )
        else if (!gatherer.canTakeRequests)
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFDF5DC),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              gatherer.verification == VerificationStatus.pending
                  ? 'Tu cuenta está en revisión. Cuando el equipo apruebe tu documento podrás tomar recojos.'
                  : 'Tu verificación no está activa. Comunícate con el equipo de TrackTrash.',
              style: const TextStyle(color: Color(0xFFA16207)),
            ),
          ),
        Row(
          children: [
            Expanded(
              child: StatTile(
                label: 'Disponibles',
                value: '${pending.value?.length ?? 0}',
                icon: Icons.inventory_2_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatTile(
                label: 'Material recuperado',
                value: formatKg(kilograms.value ?? 0),
                icon: Icons.scale_outlined,
                highlight: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        StatTile(
          label: rating.value == null
              ? 'Aún sin calificaciones'
              : '${rating.value!.totalGrades} calificaciones',
          value: rating.value == null
              ? '-'
              : rating.value!.averageScore.toStringAsFixed(1),
          icon: Icons.star_outline_rounded,
        ),
        const SectionTitle('En curso'),
        AsyncContent(
          value: services,
          onRetry: () => ref.invalidate(gathererRequestsProvider),
          builder: (items) {
            final active = items
                .where((item) => item.service?.status.isActive ?? false)
                .toList();
            if (active.isEmpty) {
              return EcoEmpty(
                title: 'No tienes recojos en curso',
                message:
                    'Revisa los recojos disponibles y toma el que mejor te convenga.',
                icon: Icons.local_shipping_outlined,
                action: FilledButton(
                  onPressed: () => context.go('/disponibles'),
                  child: const Text('Buscar recojos'),
                ),
              );
            }
            return Column(
              children: [
                for (final item in active)
                  RequestTile(request: item.request, location: item.location),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _AdminHome extends ConsumerWidget {
  const _AdminHome();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final indicators = ref.watch(generalIndicatorsProvider);
    return AsyncContent(
      value: indicators,
      onRetry: () => ref.invalidate(generalIndicatorsProvider),
      builder: (data) => Column(
        children: [
          Row(
            children: [
              Expanded(
                child: StatTile(
                  label: 'Kilos recuperados',
                  value: formatKg(data.recoveredKilograms),
                  icon: Icons.scale_outlined,
                  highlight: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatTile(
                  label: 'Solicitudes',
                  value: '${data.totalRequests}',
                  icon: Icons.assignment_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: StatTile(
                  label: 'Servicios completados',
                  value: '${data.completedServices}',
                  icon: Icons.check_circle_outline_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatTile(
                  label: 'Recolectores verificados',
                  value: '${data.verifiedGatherers}',
                  icon: Icons.verified_user_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'La gestión de recolectores, usuarios y catálogo está en la versión web.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
