import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';
import '../../core/api_failure.dart';
import '../../data/models.dart';
import '../../ui/async_content.dart';
import '../../ui/widgets.dart';
import '../requests/request_providers.dart';

/// Lets a gatherer choose the materials they accept. The backend only shows them
/// pending requests made entirely of these materials.
class GathererMaterialsCard extends ConsumerStatefulWidget {
  const GathererMaterialsCard({super.key, required this.gatherer});
  final Gatherer gatherer;

  @override
  ConsumerState<GathererMaterialsCard> createState() =>
      _GathererMaterialsCardState();
}

class _GathererMaterialsCardState extends ConsumerState<GathererMaterialsCard> {
  late Set<int> _selected = _initial();
  bool _saving = false;

  Set<int> _initial() => {
    for (final item in widget.gatherer.supportedResidueTypes) item.id,
  };

  @override
  void didUpdateWidget(GathererMaterialsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gatherer != widget.gatherer) _selected = _initial();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(apiProvider).setMyResidueTypes(_selected.toList()..sort());
      await ref.read(sessionProvider).refresh();
      ref.invalidate(pendingRequestsProvider);
      if (mounted) showSuccess(context, 'Materiales aceptados actualizados.');
    } on ApiFailure catch (failure) {
      if (mounted) showFailure(context, failure);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(residueTypesProvider);
    return AsyncContent(
      value: catalog,
      onRetry: () => ref.invalidate(residueTypesProvider),
      builder: (items) {
        final options = items
            .where((item) => item.isActive && item.isRecyclable)
            .toList();
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Solo verás solicitudes cuyos materiales coincidan con tu selección.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final item in options)
                      FilterChip(
                        label: Text(item.name),
                        selected: _selected.contains(item.id),
                        onSelected: (value) => setState(
                          () => value
                              ? _selected.add(item.id)
                              : _selected.remove(item.id),
                        ),
                      ),
                  ],
                ),
                if (_selected.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      'Selecciona al menos un material.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _saving || _selected.isEmpty ? null : _save,
                  child: _saving
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Guardar materiales'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
