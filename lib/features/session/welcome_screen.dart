import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';
import '../../core/config.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.recycling_rounded,
                    size: 100,
                    color: Color(0xFF087F5B),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'TrackTrash',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Conecta. Recolecta. Recicla.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Dale un nuevo destino\na lo que ya no usas.',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Coordina tus recojos y descubre el valor de cada entrega. Empezamos por una Arequipa más limpia.',
                  ),
                  const SizedBox(height: 28),
                  if (AppConfig.demoMode) ...[
                    const Chip(label: Text('Entorno de demostración')),
                    const SizedBox(height: 12),
                    const Text(
                      'Usa datos de prueba. Los recojos se guardan en el servidor local.',
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: session.busy
                          ? null
                          : () => session.signInDemo('vecino'),
                      icon: const Icon(Icons.home_outlined),
                      label: const Text('Probar como vecino'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: session.busy
                          ? null
                          : () => session.signInDemo('reciclador'),
                      icon: const Icon(Icons.local_shipping_outlined),
                      label: const Text('Probar como reciclador'),
                    ),
                  ] else
                    const Text(
                      'El acceso para usuarios estará disponible al configurar la autenticación del proyecto.',
                    ),
                  if (session.busy)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  if (session.error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        session.error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
