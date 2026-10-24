import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../ui/eco_design.dart';
import '../../../ui/async_content.dart';
import 'community_providers.dart';

class NoticesPage extends ConsumerWidget {
  const NoticesPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: const Text('Tus novedades')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: const EdgeInsets.all(22),
          children: [
            const Text('Aquí seguimos cada paso de tus entregas y reportes.'),
            const SizedBox(height: 18),
            AsyncContent(
              value: ref.watch(noticesProvider),
              onRetry: () => ref.invalidate(noticesProvider),
              builder: (items) => Column(
                children: [
                  if (items.isEmpty)
                    const EcoEmpty(
                      title: 'Estás al día',
                      message:
                          'Los cambios de tus recojos y reportes aparecerán aquí.',
                      icon: Icons.notifications_none,
                    ),
                  ...items.map(
                    (n) => Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(18),
                        leading: CircleAvatar(
                          backgroundColor: n.read
                              ? const Color(0xFFF0F2EB)
                              : EcoColors.lime,
                          child: Icon(
                            n.read ? Icons.done : Icons.notifications_none,
                            color: EcoColors.pine,
                          ),
                        ),
                        title: Text(n.title),
                        subtitle: Text(
                          '${n.message}\n${DateFormat('d MMM · HH:mm', 'es_PE').format(n.at.toLocal())}',
                        ),
                        onTap: n.read
                            ? null
                            : () async {
                                await ref
                                    .read(communityActionsProvider)
                                    .readNotice(n.id);
                              },
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
