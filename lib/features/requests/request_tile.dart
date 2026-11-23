import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/providers.dart';
import '../../data/models.dart';
import '../../ui/eco_design.dart';
import '../../ui/widgets.dart';
import 'request_providers.dart';

class RequestTile extends ConsumerWidget {
  const RequestTile({super.key, required this.request, this.location});
  final CollectRequest request;

  /// When the caller already has the location (for example from `/full`), it avoids the catalog lookup.
  final Location? location;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final place =
        location ?? ref.watch(locationByIdProvider)[request.locationId];
    final residues = ref.watch(residueByIdProvider);
    final details =
        ref.watch(detailsByRequestProvider).value?[request.id] ?? const [];
    final first = details.isEmpty
        ? null
        : residues[details.first.residueTypeId];
    final kg = details
        .where((item) => item.unit.api == 'Kg')
        .fold<double>(0, (sum, item) => sum + item.quantity);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => context.push('/solicitudes/${request.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              MaterialBadge(kind: materialKind(first?.name ?? '')),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Solicitud #${request.id}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: EcoColors.pine,
                          ),
                        ),
                        const SizedBox(width: 8),
                        StatusChip(request.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${formatDate(request.scheduledDate)}, ${request.timeLabel}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (place != null)
                      Text(
                        place.summary,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    if (details.isNotEmpty)
                      Text(
                        '${details.length} ${details.length == 1 ? 'material' : 'materiales'}${kg > 0 ? ' · ${formatKg(kg)} estimados' : ''}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: EcoColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}
