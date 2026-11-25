import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';
import '../../core/api_failure.dart';
import '../../data/enums.dart';
import '../../data/models.dart';
import '../../ui/async_content.dart';
import '../../ui/eco_design.dart';
import '../../ui/filters.dart';
import '../../ui/widgets.dart';
import '../requests/request_providers.dart';

/// Every gatherer, for verification and activation. Admin only.
final adminGatherersProvider = FutureProvider.autoDispose<List<Gatherer>>((
  ref,
) async {
  final items = await ref.watch(apiProvider).gatherers();
  int rank(Gatherer g) => switch (g.verification) {
    VerificationStatus.pending => 0,
    VerificationStatus.verified => 1,
    VerificationStatus.rejected => 2,
  };
  return [...items]..sort((a, b) => rank(a).compareTo(rank(b)));
});

/// Every account. Admin only.
final adminUsersProvider = FutureProvider.autoDispose<List<User>>((ref) async {
  final items = await ref.watch(apiProvider).users();
  return [...items]..sort((a, b) => b.userId.compareTo(a.userId));
});

/// Runs an admin action, reports the result and refreshes the affected lists.
Future<void> _run(
  BuildContext context,
  WidgetRef ref,
  Future<void> Function() action,
  String success,
) async {
  try {
    await action();
    ref
      ..invalidate(adminGatherersProvider)
      ..invalidate(adminUsersProvider)
      ..invalidate(residueTypesProvider)
      ..invalidate(generalIndicatorsProvider);
    if (context.mounted) showSuccess(context, success);
  } on ApiFailure catch (failure) {
    if (context.mounted) showFailure(context, failure);
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader(this.title, this.subtitle);
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 4),
        Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
      ],
    ),
  );
}

class _Tag extends StatelessWidget {
  const _Tag(this.text, {required this.color, required this.background});
  final String text;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      text,
      style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
    ),
  );
}

_Tag _verificationTag(VerificationStatus status) => switch (status) {
  VerificationStatus.verified => _Tag(
    status.label,
    color: EcoColors.pine,
    background: const Color(0xFFDCF1E5),
  ),
  VerificationStatus.pending => _Tag(
    status.label,
    color: const Color(0xFFA16207),
    background: const Color(0xFFFDF5DC),
  ),
  VerificationStatus.rejected => _Tag(
    status.label,
    color: const Color(0xFFB42318),
    background: const Color(0xFFFDECEA),
  ),
};

/// Gatherer review: verify or reject documents, activate or deactivate accounts.
class AdminGatherersPage extends ConsumerStatefulWidget {
  const AdminGatherersPage({super.key});

  @override
  ConsumerState<AdminGatherersPage> createState() => _AdminGatherersPageState();
}

class _AdminGatherersPageState extends ConsumerState<AdminGatherersPage> {
  String _query = '';
  VerificationStatus? _status;
  int _page = 1;

  void _resetFilters() {
    setState(() {
      _query = '';
      _status = null;
      _page = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final gatherers = ref.watch(adminGatherersProvider);
    final api = ref.read(apiProvider);
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(adminGatherersProvider);
        await ref.read(adminGatherersProvider.future);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        children: [
          const _PageHeader(
            'Recolectores',
            'Revisa documentos y decide quién puede postular a recojos.',
          ),
          AsyncContent(
            value: gatherers,
            onRetry: () => ref.invalidate(adminGatherersProvider),
            builder: (items) {
              if (items.isEmpty) {
                return const EcoEmpty(
                  title: 'Aún no hay recolectores',
                  message: 'Aparecerán aquí cuando se registren.',
                  icon: Icons.local_shipping_outlined,
                );
              }
              final filtered = items.where((g) {
                final matchesStatus =
                    _status == null || g.verification == _status;
                final matchesSearch = matchesQuery(_query, [
                  g.fullName,
                  g.verificationDocument,
                  g.description,
                ]);
                return matchesStatus && matchesSearch;
              }).toList();
              final pageCount = (filtered.length / kPageSize).ceil();
              final page = pageCount == 0
                  ? 1
                  : _page.clamp(1, pageCount).toInt();
              final visible = pageOf(filtered, page);
              final activeFilters = _query.isNotEmpty || _status != null;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  SearchField(
                    value: _query,
                    hint: 'Buscar por nombre o documento',
                    onChanged: (value) => setState(() {
                      _query = value;
                      _page = 1;
                    }),
                  ),
                  const SizedBox(height: 12),
                  FilterChipsRow<VerificationStatus>(
                    options: [
                      ChipOption(null, 'Todos', count: items.length),
                      for (final status in VerificationStatus.values)
                        ChipOption(
                          status,
                          status.label,
                          count: items
                              .where((g) => g.verification == status)
                              .length,
                        ),
                    ],
                    selected: _status,
                    onSelected: (value) => setState(() {
                      _status = value;
                      _page = 1;
                    }),
                  ),
                  if (filtered.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    FilterSummary(
                      shown: filtered.length,
                      total: items.length,
                      active: activeFilters,
                      onReset: _resetFilters,
                    ),
                    for (final g in visible)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      g.fullName.isEmpty
                                          ? 'Recolector #${g.gathererId}'
                                          : g.fullName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: EcoColors.pine,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  _verificationTag(g.verification),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${g.type.label}${g.isActive ? '' : ' · Desactivado'}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              if (g.verificationDocument != null)
                                InfoRow(
                                  icon: Icons.badge_outlined,
                                  text: g.verificationDocument!,
                                ),
                              if (g.description != null)
                                InfoRow(
                                  icon: Icons.notes_rounded,
                                  text: g.description!,
                                ),
                              if (g.supportedResidueTypes.isNotEmpty)
                                InfoRow(
                                  icon: Icons.recycling_rounded,
                                  text: g.supportedResidueTypes
                                      .map((r) => r.name)
                                      .join(', '),
                                ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  if (g.verification !=
                                      VerificationStatus.verified)
                                    FilledButton(
                                      onPressed: () => _run(
                                        context,
                                        ref,
                                        () => api.updateGatherer(
                                          g,
                                          verification:
                                              VerificationStatus.verified,
                                        ),
                                        'Recolector verificado.',
                                      ),
                                      child: const Text('Verificar'),
                                    ),
                                  if (g.verification !=
                                      VerificationStatus.rejected)
                                    OutlinedButton(
                                      onPressed: () => _run(
                                        context,
                                        ref,
                                        () => api.updateGatherer(
                                          g,
                                          verification:
                                              VerificationStatus.rejected,
                                        ),
                                        'Recolector rechazado.',
                                      ),
                                      child: const Text('Rechazar'),
                                    ),
                                  TextButton(
                                    onPressed: () => _run(
                                      context,
                                      ref,
                                      () => api.updateGatherer(
                                        g,
                                        isActive: !g.isActive,
                                      ),
                                      g.isActive
                                          ? 'Recolector desactivado.'
                                          : 'Recolector activado.',
                                    ),
                                    child: Text(
                                      g.isActive ? 'Desactivar' : 'Activar',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    PaginationBar(
                      page: page,
                      pageCount: pageCount,
                      total: filtered.length,
                      onChanged: (value) => setState(() => _page = value),
                    ),
                  ] else
                    EcoEmpty(
                      title: 'Sin resultados',
                      message:
                          'Prueba con otras palabras o limpia los filtros.',
                      icon: Icons.search_off_rounded,
                      action: TextButton(
                        onPressed: _resetFilters,
                        child: const Text('Limpiar filtros'),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Accounts: search, role and activation. Admin only.
class AdminUsersPage extends ConsumerStatefulWidget {
  const AdminUsersPage({super.key});

  @override
  ConsumerState<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends ConsumerState<AdminUsersPage> {
  String _query = '';
  UserRole? _role;
  int _page = 1;

  void _resetFilters() {
    setState(() {
      _query = '';
      _role = null;
      _page = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final users = ref.watch(adminUsersProvider);
    final me = ref.watch(sessionProvider).user!;
    final api = ref.read(apiProvider);
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(adminUsersProvider);
        await ref.read(adminUsersProvider.future);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        children: [
          const _PageHeader(
            'Usuarios',
            'Cuentas registradas. Desactiva las que no deban ingresar.',
          ),
          SearchField(
            value: _query,
            hint: 'Buscar por nombre o correo',
            onChanged: (value) => setState(() {
              _query = value;
              _page = 1;
            }),
          ),
          const SizedBox(height: 12),
          AsyncContent(
            value: users,
            onRetry: () => ref.invalidate(adminUsersProvider),
            builder: (items) {
              final visible = items
                  .where(
                    (u) =>
                        (_role == null || u.role == _role) &&
                        matchesQuery(_query, [u.fullName, u.email]),
                  )
                  .toList();
              final pageCount = (visible.length / kPageSize).ceil();
              final page = pageCount == 0
                  ? 1
                  : _page.clamp(1, pageCount).toInt();
              final pageItems = pageOf(visible, page);
              return Column(
                children: [
                  FilterChipsRow<UserRole>(
                    options: [
                      ChipOption(null, 'Todos', count: items.length),
                      for (final role in UserRole.values)
                        ChipOption(
                          role,
                          role.label,
                          count: items.where((u) => u.role == role).length,
                        ),
                    ],
                    selected: _role,
                    onSelected: (value) => setState(() {
                      _role = value;
                      _page = 1;
                    }),
                  ),
                  if (visible.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    FilterSummary(
                      shown: visible.length,
                      total: items.length,
                      active: _query.isNotEmpty || _role != null,
                      onReset: _resetFilters,
                    ),
                    for (final u in pageItems)
                      Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.fromLTRB(
                            16,
                            6,
                            8,
                            6,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: u.isActive
                                ? EcoColors.lime
                                : const Color(0xFFE7E5E4),
                            child: Text(
                              u.initials,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: EcoColors.pine,
                              ),
                            ),
                          ),
                          title: Text(
                            u.fullName,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            '${u.role.label} · ${u.email}${u.isActive ? '' : ' · Inactivo'}',
                          ),
                          trailing: u.userId == me.userId
                              ? null
                              : Switch(
                                  value: u.isActive,
                                  onChanged: (value) => _run(
                                    context,
                                    ref,
                                    () => api.updateUser(
                                      u,
                                      firstName: u.firstName,
                                      lastName: u.lastName,
                                      phone: u.phone,
                                      isActive: value,
                                    ),
                                    value
                                        ? 'Cuenta activada.'
                                        : 'Cuenta desactivada.',
                                  ),
                                ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    PaginationBar(
                      page: page,
                      pageCount: pageCount,
                      total: visible.length,
                      onChanged: (value) => setState(() => _page = value),
                    ),
                  ] else
                    EcoEmpty(
                      title: 'Sin resultados',
                      message:
                          'Prueba con otras palabras o limpia los filtros.',
                      icon: Icons.person_search_outlined,
                      action: TextButton(
                        onPressed: _resetFilters,
                        child: const Text('Limpiar filtros'),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Material catalog: create, edit and activate residue types. Admin only.
class AdminCatalogScreen extends ConsumerStatefulWidget {
  const AdminCatalogScreen({super.key});

  @override
  ConsumerState<AdminCatalogScreen> createState() => _AdminCatalogScreenState();
}

class _AdminCatalogScreenState extends ConsumerState<AdminCatalogScreen> {
  String _query = '';
  ResidueCategory? _category;
  int _page = 1;

  void _resetFilters() {
    setState(() {
      _query = '';
      _category = null;
      _page = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(residueTypesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Catálogo de materiales')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(context, ref, null),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nuevo material'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(residueTypesProvider);
            await ref.read(residueTypesProvider.future);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            children: [
              SearchField(
                value: _query,
                hint: 'Buscar material',
                onChanged: (value) => setState(() {
                  _query = value;
                  _page = 1;
                }),
              ),
              const SizedBox(height: 12),
              AsyncContent(
                value: catalog,
                onRetry: () => ref.invalidate(residueTypesProvider),
                builder: (items) {
                  final filtered = items.where((item) {
                    final matchesCategory =
                        _category == null || item.category == _category;
                    final matchesSearch = matchesQuery(_query, [
                      item.name,
                      item.description,
                      item.instructions,
                    ]);
                    return matchesCategory && matchesSearch;
                  }).toList();
                  final pageCount = (filtered.length / kPageSize).ceil();
                  final page = pageCount == 0
                      ? 1
                      : _page.clamp(1, pageCount).toInt();
                  final visible = pageOf(filtered, page);
                  final activeFilters = _query.isNotEmpty || _category != null;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FilterChipsRow<ResidueCategory>(
                        options: [
                          const ChipOption(null, 'Todas'),
                          for (final category in ResidueCategory.values)
                            ChipOption(category, category.label),
                        ],
                        selected: _category,
                        onSelected: (value) => setState(() {
                          _category = value;
                          _page = 1;
                        }),
                      ),
                      if (filtered.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        FilterSummary(
                          shown: filtered.length,
                          total: items.length,
                          active: activeFilters,
                          onReset: _resetFilters,
                        ),
                        for (final item in visible)
                          Card(
                            child: ListTile(
                              onTap: () => _edit(context, ref, item),
                              leading: MaterialBadge(
                                kind: materialKind(item.name),
                                size: 40,
                              ),
                              title: Text(
                                item.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: Text(
                                '${item.category.label}${item.isRecyclable ? '' : ' · No reciclable'}${item.isActive ? '' : ' · Inactivo'}',
                              ),
                              trailing: const Icon(Icons.edit_outlined),
                            ),
                          ),
                        const SizedBox(height: 8),
                        PaginationBar(
                          page: page,
                          pageCount: pageCount,
                          total: filtered.length,
                          onChanged: (value) => setState(() => _page = value),
                        ),
                      ] else
                        EcoEmpty(
                          title: 'Sin resultados',
                          message:
                              'Prueba con otras palabras o limpia los filtros.',
                          icon: Icons.search_off_rounded,
                          action: TextButton(
                            onPressed: _resetFilters,
                            child: const Text('Limpiar filtros'),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    ResidueType? item,
  ) async {
    final name = TextEditingController(text: item?.name ?? '');
    final description = TextEditingController(text: item?.description ?? '');
    final instructions = TextEditingController(text: item?.instructions ?? '');
    var category = item?.category ?? ResidueCategory.recyclable;
    var recyclable = item?.isRecyclable ?? true;
    var active = item?.isActive ?? true;
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
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    item == null ? 'Nuevo material' : 'Editar material',
                    style: Theme.of(sheet).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: name,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                    validator: (value) => (value ?? '').trim().isEmpty
                        ? 'Ingresa un nombre'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<ResidueCategory>(
                    initialValue: category,
                    decoration: const InputDecoration(labelText: 'Categoría'),
                    items: [
                      for (final c in ResidueCategory.values)
                        DropdownMenuItem(value: c, child: Text(c.label)),
                    ],
                    onChanged: (value) =>
                        setState(() => category = value ?? category),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: description,
                    decoration: const InputDecoration(
                      labelText: 'Descripción (opcional)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: instructions,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Cómo separarlo (opcional)',
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Reciclable'),
                    value: recyclable,
                    onChanged: (value) => setState(() => recyclable = value),
                  ),
                  if (item != null)
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Activo en el catálogo'),
                      value: active,
                      onChanged: (value) => setState(() => active = value),
                    ),
                  const SizedBox(height: 8),
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
      ),
    );
    final values = (
      name: name.text,
      description: description.text,
      instructions: instructions.text,
    );
    name.dispose();
    description.dispose();
    instructions.dispose();
    if (saved != true || !context.mounted) return;
    await _run(
      context,
      ref,
      () => ref
          .read(apiProvider)
          .saveResidueType(
            id: item?.id,
            name: values.name,
            category: category,
            isRecyclable: recyclable,
            isActive: active,
            description: values.description,
            instructions: values.instructions,
          ),
      item == null ? 'Material creado.' : 'Material actualizado.',
    );
  }
}
