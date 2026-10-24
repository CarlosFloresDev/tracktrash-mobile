import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../app/providers.dart';
import '../../../ui/eco_design.dart';
import '../../../ui/async_content.dart';
import 'community_providers.dart';

class ImpactPage extends ConsumerStatefulWidget {
  const ImpactPage({super.key});
  @override
  ConsumerState<ImpactPage> createState() => _ImpactPageState();
}

class _ImpactPageState extends ConsumerState<ImpactPage> {
  final _keys = <String, String>{};
  @override
  Widget build(BuildContext context) {
    final points = ref.watch(pickupsProvider).state.points;
    final actions = ref.watch(communityActionsProvider);
    final session = ref.watch(sessionProvider).session!;
    return ListView(
      padding: const EdgeInsets.all(22),
      children: [
        Text(
          'Cada entrega deja huella.',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 10),
        const Text(
          'Tus acciones suman. Consulta tus puntos y descubre nuevas formas de seguir participando.',
        ),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            color: EcoColors.lime,
            borderRadius: BorderRadius.circular(26),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('TU SALDO DISPONIBLE'),
                    Text(
                      '$points puntos',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const Text('20 puntos por entrega · máximo 200 al día.'),
                  ],
                ),
              ),
              const Icon(
                Icons.auto_awesome_outlined,
                size: 48,
                color: EcoColors.pine,
              ),
            ],
          ),
        ),
        if (actions.error != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              actions.error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        if (ref.watch(profileProvider).valueOrNull case final profile?)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Card(
              child: ListTile(
                leading: const Icon(
                  Icons.local_fire_department_outlined,
                  color: EcoColors.green,
                ),
                title: Text('${profile.streak} días de racha'),
                subtitle: Text(
                  'Tu mejor racha: ${profile.bestStreak} días con entregas confirmadas.',
                ),
              ),
            ),
          ),
        const SectionTitle('Beneficios para seguir sumando'),
        AsyncContent(
          value: ref.watch(rewardsProvider),
          onRetry: () => ref.invalidate(rewardsProvider),
          builder: (items) => Column(
            children: [
              if (items.isEmpty)
                const EcoEmpty(
                  title: 'Pronto habrá nuevas oportunidades',
                  message: 'Los beneficios activos aparecerán aquí.',
                ),
              ...items.map(
                (r) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const CircleAvatar(
                              backgroundColor: Color(0xFFF0F6E5),
                              child: Icon(
                                Icons.redeem_outlined,
                                color: EcoColors.green,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                r.name,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            Text(
                              '${r.cost} pts',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: EcoColors.green,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(r.description),
                        const SizedBox(height: 12),
                        Text(
                          '${r.stock} disponibles${r.demo ? ' · Demostración' : ''}',
                        ),
                        const SizedBox(height: 14),
                        FilledButton(
                          onPressed:
                              actions.busy ||
                                  r.stock == 0 ||
                                  points < r.cost ||
                                  session.role != 'vecino'
                              ? null
                              : () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Confirmar canje'),
                                      content: Text(
                                        'Usarás ${r.cost} puntos para ${r.name}. ¿Deseas continuar?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, false),
                                          child: const Text('Volver'),
                                        ),
                                        FilledButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, true),
                                          child: const Text('Canjear'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm != true) return;
                                  final key = _keys.putIfAbsent(
                                    r.id,
                                    () => const Uuid().v4(),
                                  );
                                  final ok = await actions.redeem(r.id, key);
                                  if (ok && context.mounted) {
                                    _keys.remove(r.id);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Canje registrado. Consulta tu código en Mis canjes.',
                                        ),
                                      ),
                                    );
                                  }
                                },
                          child: Text(
                            points < r.cost
                                ? 'Te faltan ${r.cost - points} puntos'
                                : 'Canjear beneficio',
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
        const SectionTitle('Historial de puntos'),
        AsyncContent(
          value: ref.watch(movementsProvider),
          onRetry: () => ref.invalidate(movementsProvider),
          builder: (items) => Column(
            children: [
              if (items.isEmpty)
                const EcoEmpty(
                  title: 'Tus primeras acciones están por venir',
                  message: 'Aquí verás los puntos obtenidos y utilizados.',
                ),
              ...items.map(
                (m) => Card(
                  child: ListTile(
                    leading: Icon(
                      (m['puntos'] as int) > 0
                          ? Icons.add_circle_outline
                          : Icons.remove_circle_outline,
                      color: EcoColors.green,
                    ),
                    title: Text(m['motivo'] as String),
                    trailing: Text(
                      '${(m['puntos'] as int) > 0 ? '+' : ''}${m['puntos']} pts',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SectionTitle('Mis canjes'),
        AsyncContent(
          value: ref.watch(redemptionsProvider),
          onRetry: () => ref.invalidate(redemptionsProvider),
          builder: (items) => Column(
            children: [
              if (items.isEmpty)
                const EcoEmpty(
                  title: 'Todavía no tienes canjes',
                  message: 'Tus códigos de canje aparecerán aquí.',
                ),
              ...items.map(
                (r) => Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(18),
                    leading: const Icon(Icons.confirmation_number_outlined),
                    title: SelectableText('Código ${r.code}'),
                    subtitle: Text('${r.cost} puntos utilizados'),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(top: 20, bottom: 20),
          child: Text(
            'Las cantidades de los recojos son estimaciones. Todavía no se calcula un indicador de CO₂ evitado.',
          ),
        ),
      ],
    );
  }
}
