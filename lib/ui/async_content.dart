import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_failure.dart';
import 'eco_design.dart';

class AsyncContent<T> extends StatelessWidget {
  const AsyncContent({
    super.key,
    required this.value,
    required this.builder,
    required this.onRetry,
  });
  final AsyncValue<T> value;
  final Widget Function(T) builder;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => value.when(
    data: builder,
    loading: () => const Padding(
      padding: EdgeInsets.all(36),
      child: Center(child: CircularProgressIndicator()),
    ),
    error: (e, _) => EcoEmpty(
      title: 'No pudimos cargar esta sección',
      message: e is ApiFailure
          ? e.message
          : 'Revisa tu conexión y vuelve a intentarlo.',
      icon: Icons.cloud_off_outlined,
      action: OutlinedButton(
        onPressed: onRetry,
        child: const Text('Reintentar'),
      ),
    ),
  );
}
