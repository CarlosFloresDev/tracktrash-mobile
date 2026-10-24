import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../app/providers.dart';
import '../../../core/config.dart';
import '../domain/pickup.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) ref.read(pickupsProvider).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider).session;
    if (session == null) return const SizedBox.shrink();
    final model = ref.watch(pickupsProvider);
    final state = model.state;
    final recycler = session.isRecycler;
    return Scaffold(
      appBar: AppBar(
        title: const Text('TrackTrash'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: state.loading || state.saving
                ? null
                : () => model.load(),
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: () => ref.read(sessionProvider).signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: RefreshIndicator(
            onRefresh: () => model.load(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                if (AppConfig.demoMode)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text('DEMOSTRACIÓN · DATOS DE PRUEBA'),
                  ),
                Text(
                  recycler
                      ? 'Cada recojo cuenta.'
                      : 'Tu próximo cambio\nempieza aquí.',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  recycler
                      ? 'Acepta una solicitud y coordina la entrega con el vecino.'
                      : 'Separa tus materiales. Nosotros te ayudamos a coordinar su recojo.',
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF075E46),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.eco_outlined,
                        color: Color(0xFFBDEBAD),
                        size: 42,
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              recycler
                                  ? 'Reciclar nos conecta'
                                  : '${state.points} puntos',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            Text(
                              recycler
                                  ? 'Confirma cada entrega con el código del vecino.'
                                  : '20 puntos por cada entrega confirmada.',
                              style: const TextStyle(color: Color(0xFFDCF3E6)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (!recycler)
                  FilledButton.icon(
                    key: const Key('new-pickup'),
                    onPressed: state.saving
                        ? null
                        : () => context.push('/solicitar'),
                    icon: const Icon(Icons.add),
                    label: const Text('Solicitar un recojo'),
                  ),
                if (state.error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: MaterialBanner(
                      content: Text(
                        '${state.error!}\nLa información visible puede estar desactualizada.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: state.loading ? null : () => model.load(),
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),
                Text(
                  recycler ? 'Solicitudes de recojo' : 'Mis recojos',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                if (state.loading || state.saving)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: LinearProgressIndicator(),
                  ),
                if (state.items.isEmpty && !state.loading)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.inventory_2_outlined,
                            size: 48,
                            color: Color(0xFF087F5B),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            recycler
                                ? 'Todavía no hay solicitudes disponibles.'
                                : 'Tu primera entrega está por comenzar.',
                          ),
                          const SizedBox(height: 8),
                          Text(
                            recycler
                                ? 'Actualiza para consultar nuevos recojos.'
                                : 'Solicita un recojo de papel, plástico, vidrio o metal.',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ...state.items.map(
                  (pickup) => PickupCard(
                    pickup: pickup,
                    recycler: recycler,
                    busy: state.saving || state.loading,
                    onAccept: () async {
                      final ok = await model.accept(pickup.id);
                      if (ok && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Solicitud aceptada. Ya puedes ver la dirección.',
                            ),
                          ),
                        );
                      }
                    },
                    onConfirm: () => _confirm(pickup.id),
                  ),
                ),
                if (state.hasMore)
                  TextButton(
                    onPressed: state.loading || state.saving
                        ? null
                        : () => model.load(more: true),
                    child: const Text('Ver más recojos'),
                  ),
                if (!recycler) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Antes de entregar',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  ...RecyclableMaterial.values.map(
                    (m) => Card(
                      child: ListTile(
                        leading: const Icon(
                          Icons.recycling,
                          color: Color(0xFF087F5B),
                        ),
                        title: Text(m.label),
                        subtitle: Text(m.tip),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirm(String id) async {
    var enteredCode = '';
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
                'Pide al vecino el código de seis dígitos y confirma cuando recibas los materiales.',
              ),
              const SizedBox(height: 16),
              TextFormField(
                onChanged: (value) => enteredCode = value,
                autofocus: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
              if (form.currentState!.validate()) {
                Navigator.pop(ctx, enteredCode);
              }
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (code != null) {
      final ok = await ref.read(pickupsProvider).confirm(id, code);
      if (ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Entrega confirmada. ¡Gracias por reciclar!'),
          ),
        );
      }
    }
  }
}

class PickupCard extends StatelessWidget {
  const PickupCard({
    super.key,
    required this.pickup,
    required this.recycler,
    required this.busy,
    required this.onAccept,
    required this.onConfirm,
  });
  final Pickup pickup;
  final bool recycler;
  final bool busy;
  final VoidCallback onAccept;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final color = switch (pickup.status) {
      'Confirmada' => const Color(0xFF087F5B),
      'Aceptada' => const Color(0xFF1D55A0),
      _ => const Color(0xFF875D0D),
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  pickup.materialLabel,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Chip(
                  avatar: Icon(
                    pickup.status == 'Confirmada'
                        ? Icons.check_circle_outline
                        : Icons.schedule,
                    size: 18,
                    color: color,
                  ),
                  label: Text(pickup.status, style: TextStyle(color: color)),
                ),
              ],
            ),
            Text('${pickup.estimatedKg.toStringAsFixed(2)} kg estimados'),
            const SizedBox(height: 8),
            Text(
              DateFormat(
                'EEE d MMM · HH:mm',
                'es_PE',
              ).format(pickup.scheduledAt),
            ),
            const SizedBox(height: 8),
            Text(
              pickup.address ?? 'La dirección se muestra al aceptar el recojo.',
            ),
            if (pickup.code != null && pickup.status != 'Confirmada') ...[
              const Divider(height: 28),
              const Text(
                'Comparte este código solo al entregar tus materiales.',
              ),
              SelectableText(
                pickup.code!,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  letterSpacing: 5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            if (recycler && pickup.status == 'Pendiente')
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: FilledButton(
                  onPressed: busy ? null : onAccept,
                  child: const Text('Aceptar recojo'),
                ),
              ),
            if (recycler && pickup.status == 'Aceptada')
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: FilledButton(
                  onPressed: busy ? null : onConfirm,
                  child: const Text('Confirmar con código'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
