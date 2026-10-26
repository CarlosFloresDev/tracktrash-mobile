import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../app/providers.dart';
import '../../../ui/eco_design.dart';
import '../../pickups/domain/pickup.dart';
import 'community_providers.dart';
import 'issues_page.dart';

class PickupsPage extends ConsumerWidget {
  const PickupsPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final model = ref.watch(pickupsProvider);
    final actions = ref.watch(communityActionsProvider);
    final state = model.state;
    final session = ref.watch(sessionProvider).session!;
    final recycler = session.isRecycler;
    return RefreshIndicator(
      onRefresh: () => model.load(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(22),
        children: [
          Text(
            recycler
                ? 'Una entrega,\nmuchas posibilidades.'
                : 'Tus recojos,\npaso a paso.',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          const Text(
            'Consulta el estado de cada solicitud y coordina una entrega segura.',
          ),
          const SizedBox(height: 20),
          if (!recycler && session.role == 'vecino')
            FilledButton.icon(
              onPressed: () => context.push('/solicitar'),
              icon: const Icon(Icons.add),
              label: const Text('Solicitar un recojo'),
            ),
          if (state.loading || state.saving || actions.busy)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: LinearProgressIndicator(),
            ),
          if (state.error != null || actions.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text(
                state.error ?? actions.error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          const SectionTitle('Seguimiento de recojos'),
          if (state.items.isEmpty && !state.loading)
            EcoEmpty(
              title: 'Aún no hay recojos aquí',
              message: recycler
                  ? 'Las solicitudes disponibles aparecerán en esta sección.'
                  : 'Tu próxima entrega puede comenzar hoy.',
              action: TextButton(
                onPressed: () => model.load(),
                child: const Text('Actualizar'),
              ),
            ),
          ...state.items.map(
            (p) => EcoEntrance(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              p.materialLabel,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          Chip(label: Text(p.status)),
                        ],
                      ),
                      Text('${p.estimatedKg.toStringAsFixed(2)} kg estimados'),
                      const SizedBox(height: 8),
                      Text(
                        DateFormat(
                          'EEE d MMM · HH:mm',
                          'es_PE',
                        ).format(p.scheduledAt),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        p.address ??
                            'La dirección se comparte al aceptar la solicitud.',
                      ),
                      if (p.code != null &&
                          p.status != 'Confirmada' &&
                          p.status != 'Cancelada') ...[
                        const Divider(height: 28),
                        const Text(
                          'Comparte el código solo al entregar los materiales.',
                        ),
                        SelectableText(
                          p.code!,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(letterSpacing: 4),
                        ),
                      ],
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (recycler && p.status == 'Pendiente')
                            FilledButton(
                              onPressed: actions.busy || state.saving
                                  ? null
                                  : () => model.accept(p.id),
                              child: const Text('Aceptar recojo'),
                            ),
                          if (recycler && p.status == 'Aceptada')
                            FilledButton(
                              onPressed: actions.busy
                                  ? null
                                  : () => actions.travel(p.id),
                              child: const Text('Iniciar viaje'),
                            ),
                          if (recycler &&
                              (p.status == 'Aceptada' ||
                                  p.status == 'EnCamino'))
                            OutlinedButton(
                              onPressed: actions.busy
                                  ? null
                                  : () => _confirm(context, ref, p),
                              child: const Text('Confirmar con código'),
                            ),
                          if (!recycler && p.status == 'Pendiente')
                            OutlinedButton(
                              onPressed: actions.busy
                                  ? null
                                  : () => actions.assign(p.id),
                              child: const Text('Asignar aliado cercano'),
                            ),
                          if (p.status != 'Confirmada' &&
                              p.status != 'Cancelada')
                            TextButton(
                              onPressed: actions.busy
                                  ? null
                                  : () async {
                                      final text = await askText(
                                        context,
                                        'Cancelar recojo',
                                        'Motivo de cancelación',
                                      );
                                      if (text != null) {
                                        await actions.cancel(p.id, text);
                                      }
                                    },
                              child: const Text('Cancelar'),
                            ),
                          TextButton(
                            onPressed: () => _history(context, ref, p.id),
                            child: const Text('Ver historial'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (state.hasMore)
            TextButton(
              onPressed: state.loading ? null : () => model.load(more: true),
              child: const Text('Cargar más'),
            ),
        ],
      ),
    );
  }

  Future<void> _confirm(BuildContext context, WidgetRef ref, Pickup p) async {
    var value = '';
    final form = GlobalKey<FormState>();
    final code = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar entrega'),
        content: Form(
          key: form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Pide el código al vecino cuando recibas los materiales.',
              ),
              const SizedBox(height: 18),
              TextFormField(
                autofocus: true,
                maxLength: 6,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (v) => value = v,
                decoration: const InputDecoration(
                  labelText: 'Código de entrega',
                ),
                validator: (v) =>
                    v?.length == 6 ? null : 'Ingresa los seis dígitos.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Volver'),
          ),
          FilledButton(
            onPressed: () {
              if (form.currentState!.validate()) Navigator.pop(ctx, value);
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (code != null && context.mounted) {
      final ok = await ref.read(pickupsProvider).confirm(p.id, code);
      if (ok) {
        ref.invalidate(noticesProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Entrega confirmada. ¡Gracias por reciclar!'),
            ),
          );
        }
      }
    }
  }

  Future<void> _history(BuildContext context, WidgetRef ref, String id) async {
    try {
      final items = await ref.read(communityActionsProvider).history(id);
      if (!context.mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (ctx) => SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Historia del recojo',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              for (final e in items)
                ListTile(
                  leading: const Icon(
                    Icons.check_circle_outline,
                    color: EcoColors.green,
                  ),
                  title: Text(e['accion'] as String),
                  subtitle: Text(
                    DateFormat(
                      'd MMM · HH:mm',
                      'es_PE',
                    ).format(DateTime.parse(e['creadoEn'] as String).toLocal()),
                  ),
                ),
            ],
          ),
        ),
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No pudimos cargar el historial.')),
        );
      }
    }
  }
}
