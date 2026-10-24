import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/providers.dart';
import '../../core/config.dart';
import '../../ui/eco_design.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.recycling_rounded, color: EcoColors.green),
                      SizedBox(width: 8),
                      Text(
                        'TrackTrash',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w800,
                          color: EcoColors.pine,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  EcoEntrance(
                    child: Image.asset(
                      'assets/images/tacho-vivo.png',
                      height: 260,
                      semanticLabel: 'Tacho Vivo sonríe frente al Misti',
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'AREQUIPA · CONECTA, RECOLECTA, RECICLA',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      color: EcoColors.green,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tu ciudad merece\nun nuevo comienzo.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Separa tus materiales, encuentra opciones cercanas y conecta con quienes les dan una segunda vida.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 26),
                  if (AppConfig.authConfigured) ...[
                    FilledButton(
                      onPressed: () => context.push('/acceso'),
                      child: const Text('Iniciar sesión'),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: () => context.push('/acceso?registro=true'),
                      child: const Text('Crear mi cuenta'),
                    ),
                  ],
                  if (AppConfig.demoMode) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Text(
                        'EXPLORA LA DEMOSTRACIÓN',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: session.busy
                          ? null
                          : () => session.signInDemo('vecino'),
                      icon: const Icon(Icons.home_outlined),
                      label: const Text('Probar como vecino'),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: session.busy
                          ? null
                          : () => session.signInDemo('reciclador'),
                      icon: const Icon(Icons.local_shipping_outlined),
                      label: const Text('Probar como reciclador'),
                    ),
                    TextButton(
                      onPressed: session.busy
                          ? null
                          : () => session.signInDemo('admin'),
                      child: const Text('Explorar como operador'),
                    ),
                    const Text(
                      'Entorno de prueba con ubicaciones y beneficios de demostración.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                  if (!AppConfig.demoMode && !AppConfig.authConfigured)
                    const Text(
                      'El acceso estará disponible al configurar el servicio de autenticación.',
                    ),
                  if (session.busy)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  if (session.error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: Text(
                        session.error!,
                        textAlign: TextAlign.center,
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
