import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';
import '../../../ui/eco_design.dart';
import '../../../ui/async_content.dart';
import 'community_providers.dart';

class IssuesPage extends ConsumerStatefulWidget {
  const IssuesPage({super.key, this.initialContainerId});
  final String? initialContainerId;
  @override
  ConsumerState<IssuesPage> createState() => _IssuesPageState();
}

class _IssuesPageState extends ConsumerState<IssuesPage> {
  final _description = TextEditingController();
  final _form = GlobalKey<FormState>();
  String? _container;
  String _type = 'Tacho lleno';
  @override
  void initState() {
    super.initState();
    _container = widget.initialContainerId;
  }

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final actions = ref.watch(communityActionsProvider);
    final admin = ref.watch(sessionProvider).session?.role == 'admin';
    return Scaffold(
      appBar: AppBar(
        title: Text(admin ? 'Atención de incidencias' : 'Mis reportes'),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.all(22),
            children: [
              Text(
                'Cuidemos nuestro entorno.',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 10),
              const Text(
                'Describe lo que sucede. Podrás consultar cómo avanza su atención.',
              ),
              const SectionTitle('Crear un reporte'),
              AsyncContent(
                value: ref.watch(mapProvider),
                onRetry: () => ref.invalidate(mapProvider),
                builder: (map) {
                  final bins = map.places
                      .where((p) => p.kind == 'contenedor')
                      .toList();
                  return Form(
                    key: _form,
                    child: Column(
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: bins.any((b) => b.id == _container)
                              ? _container
                              : null,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Contenedor',
                          ),
                          items: bins
                              .map(
                                (b) => DropdownMenuItem(
                                  value: b.id,
                                  child: Text(
                                    b.name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: actions.busy
                              ? null
                              : (v) => _container = v,
                          validator: (v) =>
                              v == null ? 'Selecciona un contenedor.' : null,
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          initialValue: _type,
                          decoration: const InputDecoration(
                            labelText: 'Tipo de problema',
                          ),
                          items:
                              [
                                    'Tacho lleno',
                                    'Malos olores',
                                    'Tacho dañado',
                                    'Otros',
                                  ]
                                  .map(
                                    (t) => DropdownMenuItem(
                                      value: t,
                                      child: Text(t),
                                    ),
                                  )
                                  .toList(),
                          onChanged: actions.busy ? null : (v) => _type = v!,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _description,
                          enabled: !actions.busy,
                          maxLines: 3,
                          maxLength: 1000,
                          decoration: const InputDecoration(
                            labelText: '¿Qué está pasando?',
                          ),
                          validator: (v) => (v?.trim().length ?? 0) < 10
                              ? 'Describe el problema con al menos 10 caracteres.'
                              : null,
                        ),
                        if (actions.error != null)
                          Text(
                            actions.error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: actions.busy
                              ? null
                              : () async {
                                  if (!_form.currentState!.validate()) return;
                                  final ok = await actions.report(
                                    _container!,
                                    _type,
                                    _description.text,
                                  );
                                  if (ok && context.mounted) {
                                    _description.clear();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Recibimos tu reporte. Puedes seguirlo en esta pantalla.',
                                        ),
                                      ),
                                    );
                                  }
                                },
                          icon: const Icon(Icons.send_outlined),
                          label: Text(
                            actions.busy ? 'Enviando…' : 'Enviar reporte',
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SectionTitle('Seguimiento'),
              AsyncContent(
                value: ref.watch(issuesProvider),
                onRetry: () => ref.invalidate(issuesProvider),
                builder: (items) => Column(
                  children: [
                    if (items.isEmpty)
                      const EcoEmpty(
                        title: 'No hay reportes pendientes aquí',
                        message:
                            'Tus incidencias se mostrarán con su estado y resolución.',
                      ),
                    ...items.map(
                      (i) => Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      i.type,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium,
                                    ),
                                  ),
                                  Chip(label: Text(i.status)),
                                ],
                              ),
                              Text(i.description),
                              if (i.resolution != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: Text('Resolución: ${i.resolution}'),
                                ),
                              if (admin && i.status == 'Abierta')
                                TextButton(
                                  onPressed: actions.busy
                                      ? null
                                      : () => actions.attend(i.id),
                                  child: const Text('Tomar atención'),
                                ),
                              if (admin && i.status == 'EnAtencion')
                                TextButton(
                                  onPressed: actions.busy
                                      ? null
                                      : () async {
                                          final text = await askText(
                                            context,
                                            'Registrar resolución',
                                            'Describe cómo se atendió el problema',
                                            minimum: 10,
                                          );
                                          if (text != null) {
                                            await actions.resolve(i.id, text);
                                          }
                                        },
                                  child: const Text('Resolver incidencia'),
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

Future<String?> askText(
  BuildContext context,
  String title,
  String label, {
  int minimum = 5,
}) async {
  var value = '';
  final form = GlobalKey<FormState>();
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Form(
        key: form,
        child: TextFormField(
          autofocus: true,
          maxLength: 300,
          maxLines: 3,
          onChanged: (v) => value = v,
          decoration: InputDecoration(labelText: label),
          validator: (v) => (v?.trim().length ?? 0) < minimum
              ? 'Escribe al menos $minimum caracteres.'
              : null,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Volver'),
        ),
        FilledButton(
          onPressed: () {
            if (form.currentState!.validate()) Navigator.pop(ctx, value.trim());
          },
          child: const Text('Guardar'),
        ),
      ],
    ),
  );
}
