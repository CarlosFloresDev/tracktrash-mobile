import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../app/providers.dart';
import '../../core/api_failure.dart';
import '../../data/enums.dart';
import '../../data/models.dart';
import '../../ui/async_content.dart';
import '../../ui/eco_design.dart';
import '../../ui/widgets.dart';
import 'request_actions.dart';
import 'request_providers.dart';

class RequestDetailScreen extends ConsumerWidget {
  const RequestDetailScreen({super.key, required this.requestId});
  final int requestId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final full = ref.watch(requestFullProvider(requestId));
    return Scaffold(
      appBar: AppBar(title: Text('Solicitud #$requestId')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref
              ..invalidate(requestFullProvider(requestId))
              ..invalidate(requestHistoryProvider(requestId));
            await ref.read(requestFullProvider(requestId).future);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
            children: [
              AsyncContent(
                value: full,
                onRetry: () => ref.invalidate(requestFullProvider(requestId)),
                builder: (data) => _Body(data: data),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.data});
  final CollectRequestFull data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final user = session.user!;
    final gatherer = session.gatherer;
    final residues = ref.watch(residueByIdProvider);
    final request = data.request;
    final service = data.service;
    final isOwner = request.userId == user.userId;
    final isServiceGatherer =
        service != null &&
        gatherer != null &&
        service.gathererId == gatherer.gathererId;
    final materials = service == null
        ? const AsyncData<List<RecoveredMaterial>>([])
        : ref.watch(serviceMaterialsProvider(service.id));
    final recorded = materials.value ?? const <RecoveredMaterial>[];
    final grade =
        service != null && service.status == RequestStatus.completed && isOwner
        ? ref.watch(gradeProvider((serviceId: service.id, userId: user.userId)))
        : const AsyncData<Grade?>(null);

    final canApply =
        user.role == UserRole.gatherer &&
        request.status == RequestStatus.pending &&
        service == null &&
        (gatherer?.canTakeRequests ?? false);
    final application = canApply
        ? ref
              .watch(myApplicationsProvider)
              .value
              ?.where((item) => item.collectRequestId == request.id)
              .firstOrNull
        : null;
    final managesApplications =
        (isOwner || user.role == UserRole.admin) &&
        request.status == RequestStatus.pending;
    final blocked =
        user.role == UserRole.gatherer && !(gatherer?.canTakeRequests ?? false);
    final canRate =
        isOwner &&
        service?.status == RequestStatus.completed &&
        grade.hasValue &&
        grade.value == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            StatusChip(request.status),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Pedida el ${formatTimestamp(request.requestedAt)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InfoRow(
                  icon: Icons.event_outlined,
                  text:
                      '${formatDate(request.scheduledDate)}, ${request.timeLabel}',
                ),
                InfoRow(
                  icon: Icons.place_outlined,
                  text: data.location.summary,
                ),
                if (data.location.reference != null)
                  InfoRow(
                    icon: Icons.signpost_outlined,
                    text: data.location.reference!,
                  ),
                if (!isOwner)
                  InfoRow(
                    icon: Icons.person_outline_rounded,
                    text:
                        ref
                            .watch(requesterProfileProvider(request.id))
                            .value
                            ?.displayName ??
                        'Solicitante',
                  ),
                if (request.observations != null)
                  InfoRow(
                    icon: Icons.notes_rounded,
                    text: request.observations!,
                  ),
                if (data.location.hasCoordinates) ...[
                  const SizedBox(height: 12),
                  _MiniMap(location: data.location),
                ],
              ],
            ),
          ),
        ),
        const SectionTitle('Materiales estimados'),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            child: data.details.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'Esta solicitud no tiene materiales registrados.',
                    ),
                  )
                : Column(
                    children: [
                      for (final item in data.details)
                        MaterialLine(
                          residue: residues[item.residueTypeId],
                          quantity: item.quantity,
                          unit: item.unit,
                        ),
                    ],
                  ),
          ),
        ),
        if (service != null) ...[
          SectionTitle(
            'Material recuperado',
            trailing:
                isServiceGatherer && service.status == RequestStatus.inProgress
                ? TextButton.icon(
                    onPressed: () => _recordMaterial(context, ref),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Registrar'),
                  )
                : null,
          ),
          SizedBox(
            width: double.infinity,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 8,
                ),
                child: recorded.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: Text('Aún no se registra material recuperado.'),
                      )
                    : Column(
                        children: [
                          for (final item in recorded)
                            MaterialLine(
                              residue: residues[item.residueTypeId],
                              quantity: item.quantity,
                              unit: item.unit,
                            ),
                        ],
                      ),
              ),
            ),
          ),
          const SectionTitle('Recolector'),
          _GathererCard(service: service),
        ],
        if (managesApplications) ...[
          const SectionTitle('Postulaciones'),
          _ApplicationsCard(requestId: request.id),
          const SectionTitle('Recolectores compatibles'),
          _CompatibleGatherersCard(requestId: request.id),
        ],
        const SectionTitle('Acciones'),
        if (user.role == UserRole.admin &&
            request.status == RequestStatus.pending &&
            service == null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: FilledButton.icon(
              onPressed: () => _assign(context, ref),
              icon: const Icon(Icons.assignment_ind_outlined),
              label: const Text('Asignar recolector'),
            ),
          ),
        if (blocked)
          const _Notice(
            'Tu cuenta aún no está verificada. Podrás postular a recojos cuando el equipo apruebe tu documento.',
          ),
        if (canApply && application != null)
          _Notice(
            'Ya te postulaste a este recojo (${application.status.label.toLowerCase()}). El solicitante elegirá al recolector.',
          ),
        if (canApply && application == null)
          FilledButton.icon(
            onPressed: () => _run(
              context,
              () => ref.read(requestActionsProvider).apply(request.id),
              'Postulación enviada. Te avisaremos si te eligen.',
            ),
            icon: const Icon(Icons.local_shipping_outlined),
            label: const Text('Postularme a este recojo'),
          ),
        if (isServiceGatherer && service.status == RequestStatus.assigned)
          FilledButton.icon(
            onPressed: () => _run(
              context,
              () => ref
                  .read(requestActionsProvider)
                  .changeService(data, RequestStatus.inProgress),
              'Recojo iniciado.',
            ),
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Iniciar recojo'),
          ),
        if (isServiceGatherer &&
            service.status == RequestStatus.inProgress) ...[
          FilledButton.icon(
            onPressed: recorded.isEmpty
                ? null
                : () => _run(
                    context,
                    () => ref
                        .read(requestActionsProvider)
                        .changeService(data, RequestStatus.completed),
                    'Recojo finalizado.',
                  ),
            icon: const Icon(Icons.check_circle_outline_rounded),
            label: const Text('Finalizar recojo'),
          ),
          if (recorded.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                'Registra al menos un material recuperado para finalizar.',
              ),
            ),
        ],
        if (isServiceGatherer && service.status.isActive) ...[
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () => _confirm(
              context,
              title: 'Soltar recojo',
              message:
                  'La solicitud volverá a quedar disponible para otros recolectores.',
              action: 'Soltar recojo',
              run: (reason) => ref
                  .read(requestActionsProvider)
                  .changeService(data, RequestStatus.cancelled, reason: reason),
              success: 'Soltaste el recojo.',
            ),
            child: const Text('Soltar este recojo'),
          ),
        ],
        if (canRate)
          FilledButton.icon(
            onPressed: () => _rate(context, ref),
            icon: const Icon(Icons.star_rounded),
            label: const Text('Calificar servicio'),
          ),
        if (grade.value != null) _GradeCard(grade: grade.value!),
        if ((isOwner || user.role == UserRole.admin) &&
            request.status.isActive) ...[
          const SizedBox(height: 10),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => _confirm(
              context,
              title: 'Cancelar solicitud',
              message: '¿Seguro que quieres cancelar este recojo?',
              action: 'Cancelar solicitud',
              run: (reason) =>
                  ref.read(requestActionsProvider).cancel(data, reason: reason),
              success: 'Solicitud cancelada.',
            ),
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('Cancelar solicitud'),
          ),
        ],
        if (request.status.isFinal && grade.value == null && !canRate)
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              'Esta solicitud ya terminó. No hay acciones pendientes.',
            ),
          ),
        const SectionTitle('Historial'),
        _HistoryCard(requestId: request.id),
      ],
    );
  }

  Future<void> _run(
    BuildContext context,
    Future<void> Function() action,
    String success,
  ) async {
    try {
      await action();
      if (context.mounted) showSuccess(context, success);
    } on ApiFailure catch (failure) {
      if (context.mounted) showFailure(context, failure);
    }
  }

  Future<void> _confirm(
    BuildContext context, {
    required String title,
    required String message,
    required String action,
    required Future<void> Function(String? reason) run,
    required String success,
  }) async {
    final reason = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 12),
            TextField(
              controller: reason,
              maxLength: 300,
              decoration: const InputDecoration(labelText: 'Motivo (opcional)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: const Text('Volver'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: Text(action),
          ),
        ],
      ),
    );
    final text = reason.text.trim();
    reason.dispose();
    if (confirmed != true || !context.mounted) return;
    await _run(context, () => run(text.isEmpty ? null : text), success);
  }

  Future<void> _assign(BuildContext context, WidgetRef ref) async {
    final commission = TextEditingController(text: '10');
    Gatherer? chosen;
    final picked = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheet) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          MediaQuery.viewInsetsOf(sheet).bottom + 24,
        ),
        child: Consumer(
          builder: (sheet, ref, _) {
            final gatherers = ref.watch(
              compatibleGatherersProvider(data.request.id),
            );
            return StatefulBuilder(
              builder: (sheet, setState) => Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Asignar recolector',
                    style: Theme.of(sheet).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Solo aparecen recolectores verificados que aceptan todos los materiales.',
                  ),
                  const SizedBox(height: 12),
                  AsyncContent(
                    value: gatherers,
                    onRetry: () => ref.invalidate(
                      compatibleGatherersProvider(data.request.id),
                    ),
                    builder: (items) => items.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              'No hay recolectores compatibles todavía.',
                            ),
                          )
                        : RadioGroup<int>(
                            groupValue: chosen?.gathererId,
                            onChanged: (id) => setState(
                              () => chosen = items.firstWhere(
                                (g) => g.gathererId == id,
                              ),
                            ),
                            child: Column(
                              children: [
                                for (final g in items)
                                  RadioListTile<int>(
                                    contentPadding: EdgeInsets.zero,
                                    value: g.gathererId,
                                    title: Text(
                                      g.fullName.isEmpty
                                          ? 'Recolector #${g.gathererId}'
                                          : g.fullName,
                                    ),
                                    subtitle: Text(g.type.label),
                                  ),
                              ],
                            ),
                          ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: commission,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Comisión (%)',
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: chosen == null
                        ? null
                        : () => Navigator.pop(sheet, true),
                    child: const Text('Asignar'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
    final percent = double.tryParse(commission.text.replaceAll(',', '.')) ?? 10;
    commission.dispose();
    if (picked != true || chosen == null || !context.mounted) return;
    await _run(
      context,
      () => ref
          .read(requestActionsProvider)
          .assign(data.request.id, chosen!, percent.clamp(0, 100).toDouble()),
      'Recolector asignado.',
    );
  }

  Future<void> _recordMaterial(BuildContext context, WidgetRef ref) async {
    final catalog =
        ref
            .read(residueTypesProvider)
            .value
            ?.where((item) => item.isActive)
            .toList() ??
        const [];
    final quantity = TextEditingController();
    int? residueId;
    var unit = MeasurementUnit.kg;
    final formKey = GlobalKey<FormState>();
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheet) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          MediaQuery.viewInsetsOf(sheet).bottom + 24,
        ),
        child: StatefulBuilder(
          builder: (sheet, setState) => Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Registrar material recuperado',
                  style: Theme.of(sheet).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  initialValue: residueId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Material'),
                  items: [
                    for (final item in catalog)
                      DropdownMenuItem(value: item.id, child: Text(item.name)),
                  ],
                  onChanged: (value) => setState(() => residueId = value),
                  validator: (value) =>
                      value == null ? 'Elige un material' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: quantity,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Cantidad real',
                        ),
                        validator: (value) {
                          final number = double.tryParse(
                            (value ?? '').replaceAll(',', '.'),
                          );
                          if (number == null ||
                              number < 0.01 ||
                              number > 100000) {
                            return 'Entre 0.01 y 100000';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<MeasurementUnit>(
                        initialValue: unit,
                        decoration: const InputDecoration(labelText: 'Unidad'),
                        items: [
                          for (final item in MeasurementUnit.values)
                            DropdownMenuItem(
                              value: item,
                              child: Text(item.label),
                            ),
                        ],
                        onChanged: (value) =>
                            setState(() => unit = value ?? MeasurementUnit.kg),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      Navigator.pop(sheet, true);
                    }
                  },
                  child: const Text('Guardar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    final amount = double.tryParse(quantity.text.replaceAll(',', '.'));
    quantity.dispose();
    if (saved != true ||
        residueId == null ||
        amount == null ||
        !context.mounted) {
      return;
    }
    await _run(
      context,
      () => ref
          .read(requestActionsProvider)
          .recordMaterial(
            data,
            residueTypeId: residueId!,
            quantity: amount,
            unit: unit,
          ),
      'Material registrado.',
    );
  }

  Future<void> _rate(BuildContext context, WidgetRef ref) async {
    final comment = TextEditingController();
    var score = 0;
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheet) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          MediaQuery.viewInsetsOf(sheet).bottom + 24,
        ),
        child: StatefulBuilder(
          builder: (sheet, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Califica el servicio',
                style: Theme.of(sheet).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 1; i <= 5; i++)
                    IconButton(
                      tooltip: '$i ${i == 1 ? 'estrella' : 'estrellas'}',
                      onPressed: () => setState(() => score = i),
                      iconSize: 38,
                      icon: Icon(
                        i <= score
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: EcoColors.green,
                      ),
                    ),
                ],
              ),
              TextField(
                controller: comment,
                maxLength: 500,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Comentario (opcional)',
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: score == 0 ? null : () => Navigator.pop(sheet, true),
                child: const Text('Enviar'),
              ),
            ],
          ),
        ),
      ),
    );
    final text = comment.text;
    comment.dispose();
    if (saved != true || !context.mounted) return;
    await _run(
      context,
      () => ref
          .read(requestActionsProvider)
          .rate(data, score: score, comment: text),
      'Gracias por tu calificación.',
    );
  }
}

class _MiniMap extends StatelessWidget {
  const _MiniMap({required this.location});
  final Location location;

  @override
  Widget build(BuildContext context) {
    final point = LatLng(location.latitude!, location.longitude!);
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: 170,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: point,
            initialZoom: 15,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.none,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'pe.tracktrash.mobile',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: point,
                  width: 44,
                  height: 44,
                  child: const Icon(
                    Icons.location_on_rounded,
                    size: 40,
                    color: EcoColors.green,
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
    );
  }
}

class _GathererCard extends ConsumerWidget {
  const _GathererCard({required this.service});
  final PickupService service;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final own = session.gatherer;
    // Gatherers cannot read other gatherer profiles; everyone else asks the API.
    final gatherer = own?.gathererId == service.gathererId
        ? own
        : session.user?.role == UserRole.gatherer
        ? null
        : ref.watch(gathererByIdProvider(service.gathererId)).value;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              gatherer == null || gatherer.fullName.isEmpty
                  ? 'Recolector #${service.gathererId}'
                  : gatherer.fullName,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: EcoColors.pine,
                fontSize: 16,
              ),
            ),
            if (gatherer != null)
              Text(
                '${gatherer.type.label}${gatherer.description == null ? '' : '. ${gatherer.description}'}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            const SizedBox(height: 8),
            StatusChip(service.status),
            const SizedBox(height: 8),
            InfoRow(
              icon: Icons.assignment_ind_outlined,
              text: 'Asignado ${formatTimestamp(service.assignedAt)}',
            ),
            if (service.startedAt != null)
              InfoRow(
                icon: Icons.play_circle_outline_rounded,
                text: 'Inició ${formatTimestamp(service.startedAt!)}',
              ),
            if (service.completedAt != null)
              InfoRow(
                icon: Icons.check_circle_outline_rounded,
                text: 'Terminó ${formatTimestamp(service.completedAt!)}',
              ),
          ],
        ),
      ),
    );
  }
}

/// Applications received by a pending request; accepting one assigns that gatherer.
class _ApplicationsCard extends ConsumerStatefulWidget {
  const _ApplicationsCard({required this.requestId});
  final int requestId;

  @override
  ConsumerState<_ApplicationsCard> createState() => _ApplicationsCardState();
}

class _ApplicationsCardState extends ConsumerState<_ApplicationsCard> {
  bool _busy = false;

  Future<void> _decide(Future<void> Function() action, String success) async {
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) showSuccess(context, success);
    } on ApiFailure catch (failure) {
      if (mounted) showFailure(context, failure);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final applications = ref.watch(applicationsProvider(widget.requestId));
    final actions = ref.read(requestActionsProvider);
    return AsyncContent(
      value: applications,
      onRetry: () => ref.invalidate(applicationsProvider(widget.requestId)),
      builder: (items) => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: items.isEmpty
              ? const Text(
                  'Aún no hay postulaciones. Los recolectores compatibles verán tu solicitud.',
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final item in items)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.fullName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: EcoColors.pine,
                              ),
                            ),
                            Text(
                              '${item.status.label} · ${item.verification.label}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            if (item.description != null)
                              Text(item.description!),
                            if (item.status == ApplicationStatus.pending) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: FilledButton(
                                      onPressed: _busy
                                          ? null
                                          : () => _decide(
                                              () => actions.accept(item),
                                              'Recolector asignado.',
                                            ),
                                      child: const Text('Aceptar'),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: _busy
                                          ? null
                                          : () => _decide(
                                              () => actions.reject(item),
                                              'Postulación rechazada.',
                                            ),
                                      child: const Text('Rechazar'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
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

/// Verified gatherers that accept every material of the request.
class _CompatibleGatherersCard extends ConsumerWidget {
  const _CompatibleGatherersCard({required this.requestId});
  final int requestId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gatherers = ref.watch(compatibleGatherersProvider(requestId));
    return AsyncContent(
      value: gatherers,
      onRetry: () => ref.invalidate(compatibleGatherersProvider(requestId)),
      builder: (items) => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: items.isEmpty
              ? const Text(
                  'Aún no hay recolectores verificados que acepten todos estos materiales.',
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final item in items)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.fullName.isEmpty
                                  ? 'Recolector #${item.gathererId}'
                                  : item.fullName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: EcoColors.pine,
                              ),
                            ),
                            Text(
                              '${item.type.label} · Acepta: ${item.supportedResidueTypes.map((type) => type.name).join(', ')}',
                              style: Theme.of(context).textTheme.bodyMedium,
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

class _GradeCard extends StatelessWidget {
  const _GradeCard({required this.grade});
  final Grade grade;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tu calificación',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: EcoColors.pine,
            ),
          ),
          const SizedBox(height: 6),
          RatingStars(value: grade.score.toDouble()),
          if (grade.comment != null) ...[
            const SizedBox(height: 6),
            Text(grade.comment!),
          ],
        ],
      ),
    ),
  );
}

class _Notice extends StatelessWidget {
  const _Notice(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFFDF5DC),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Text(text, style: const TextStyle(color: Color(0xFFA16207))),
  );
}

class _HistoryCard extends ConsumerWidget {
  const _HistoryCard({required this.requestId});
  final int requestId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(requestHistoryProvider(requestId));
    return AsyncContent(
      value: history,
      onRetry: () => ref.invalidate(requestHistoryProvider(requestId)),
      builder: (items) => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: items.isEmpty
              ? const Text('Sin movimientos todavía.')
              : Column(
                  children: [
                    for (final (index, item) in items.indexed)
                      _HistoryRow(item: item, last: index == items.length - 1),
                  ],
                ),
        ),
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.item, required this.last});
  final RequestHistory item;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final title = item.previousStatus == null
        ? 'Solicitud ${item.newStatus.label.toLowerCase()}'
        : '${item.previousStatus!.label} a ${item.newStatus.label}';
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              const SizedBox(height: 4),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: last ? EcoColors.green : const Color(0xFF58B98A),
                  shape: BoxShape.circle,
                ),
              ),
              if (!last)
                Expanded(
                  child: Container(width: 2, color: const Color(0xFFDCF1E5)),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: EcoColors.pine,
                    ),
                  ),
                  if (item.observations != null)
                    Text(
                      item.observations!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  Text(
                    formatTimestamp(item.createdAt),
                    style: const TextStyle(
                      fontSize: 12,
                      color: EcoColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
