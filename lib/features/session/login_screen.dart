import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';
import '../../ui/eco_design.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, this.register = false});
  final bool register;
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController(), _password = TextEditingController();
  bool _obscure = true;
  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.register ? 'Crear tu cuenta' : 'Bienvenido de nuevo',
        ),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(26),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.eco_outlined,
                    size: 60,
                    color: EcoColors.green,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    widget.register
                        ? 'Una comunidad\nempieza contigo.'
                        : 'Sigamos haciendo\nel cambio.',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 28),
                  TextFormField(
                    controller: _email,
                    enabled: !session.busy,
                    autofillHints: const [AutofillHints.email],
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Correo electrónico',
                    ),
                    validator: (v) =>
                        v != null &&
                            RegExp(
                              r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                            ).hasMatch(v.trim())
                        ? null
                        : 'Ingresa un correo válido.',
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _password,
                    enabled: !session.busy,
                    obscureText: _obscure,
                    autofillHints: widget.register
                        ? const [AutofillHints.newPassword]
                        : const [AutofillHints.password],
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      suffixIcon: IconButton(
                        tooltip: _obscure
                            ? 'Mostrar contraseña'
                            : 'Ocultar contraseña',
                        onPressed: () => setState(() => _obscure = !_obscure),
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                    validator: (v) => (v?.length ?? 0) < 8
                        ? 'Usa al menos ocho caracteres.'
                        : null,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: session.busy
                        ? null
                        : () {
                            if (_form.currentState!.validate()) {
                              session.signIn(
                                _email.text.trim(),
                                _password.text,
                                register: widget.register,
                              );
                            }
                          },
                    child: Text(
                      session.busy
                          ? 'Un momento…'
                          : widget.register
                          ? 'Crear cuenta'
                          : 'Iniciar sesión',
                    ),
                  ),
                  if (!widget.register)
                    TextButton(
                      onPressed: session.busy
                          ? null
                          : () {
                              if (_email.text.trim().contains('@')) {
                                session.recover(_email.text.trim());
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Escribe primero tu correo electrónico.',
                                    ),
                                  ),
                                );
                              }
                            },
                      child: const Text('Olvidé mi contraseña'),
                    ),
                  if (session.error != null)
                    Text(
                      session.error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  if (session.message != null) Text(session.message!),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
