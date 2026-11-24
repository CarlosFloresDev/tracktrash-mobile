import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';
import '../../core/api_failure.dart';
import '../../ui/widgets.dart';

/// Changes the password. The server ends the session afterwards, so the user signs in again.
class ChangePasswordCard extends ConsumerStatefulWidget {
  const ChangePasswordCard({super.key});

  @override
  ConsumerState<ChangePasswordCard> createState() => _ChangePasswordCardState();
}

class _ChangePasswordCardState extends ConsumerState<ChangePasswordCard> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final session = ref.read(sessionProvider);
    setState(() => _saving = true);
    try {
      await ref
          .read(apiProvider)
          .changePassword(session.user!.userId, _current.text, _next.text);
      if (mounted) {
        showSuccess(context, 'Contraseña actualizada. Vuelve a ingresar.');
      }
      await session.signOut();
    } on ApiFailure catch (failure) {
      if (mounted) showFailure(context, failure);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Form(
    key: _formKey,
    child: Column(
      children: [
        TextFormField(
          controller: _current,
          obscureText: true,
          autofillHints: const [AutofillHints.password],
          decoration: const InputDecoration(labelText: 'Contraseña actual'),
          validator: (value) =>
              (value ?? '').isEmpty ? 'Ingresa tu contraseña actual' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _next,
          obscureText: true,
          autofillHints: const [AutofillHints.newPassword],
          decoration: const InputDecoration(
            labelText: 'Nueva contraseña',
            helperText: 'Mínimo 8 caracteres',
          ),
          validator: (value) {
            if ((value ?? '').length < 8) return 'Usa al menos 8 caracteres';
            if (value == _current.text) return 'Debe ser distinta de la actual';
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _confirm,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Repite la nueva contraseña',
          ),
          validator: (value) =>
              value != _next.text ? 'Las contraseñas no coinciden' : null,
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Cambiar contraseña'),
          ),
        ),
      ],
    ),
  );
}
