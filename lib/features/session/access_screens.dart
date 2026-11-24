import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/providers.dart';
import '../../core/api_failure.dart';
import '../../data/enums.dart';
import '../../ui/eco_design.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
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
                  child: EcoFloat(
                    child: Image.asset(
                      'assets/images/tacho-vivo.png',
                      height: 260,
                      semanticLabel: 'Tacho Vivo sonríe frente al Misti',
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'AREQUIPA · PIDE, RECOGE, RECICLA',
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
                  'Tus residuos reciclables,\nrecogidos y medidos.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 14),
                const Text(
                  'Pide el recojo, sigue su estado y mira cuántos kilos se recuperaron.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 26),
                FilledButton(
                  onPressed: () => context.push('/acceso'),
                  child: const Text('Iniciar sesión'),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () => context.push('/registro'),
                  child: const Text('Crear mi cuenta'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(sessionProvider).signIn(_email.text, _password.text);
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Ingresa a tu cuenta',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text('Sigue tus recojos y registra lo recuperado.'),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: 'Correo'),
                      validator: (value) =>
                          RegExp(
                            r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                          ).hasMatch((value ?? '').trim())
                          ? null
                          : 'Ingresa un correo válido',
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _password,
                      obscureText: true,
                      autofillHints: const [AutofillHints.password],
                      decoration: const InputDecoration(
                        labelText: 'Contraseña',
                      ),
                      validator: (value) => (value ?? '').isEmpty
                          ? 'Ingresa tu contraseña'
                          : null,
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    if (session.error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          session.error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: session.busy ? null : _submit,
                      child: session.busy
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Ingresar'),
                    ),
                    TextButton(
                      onPressed: () => context.pushReplacement('/registro'),
                      child: const Text('¿Aún no tienes cuenta? Regístrate'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  static const _districts = [
    'Arequipa',
    'Cayma',
    'Cerro Colorado',
    'Yanahuara',
    'Sachaca',
    'Socabaya',
    'Paucarpata',
    'Miraflores',
    'José Luis Bustamante y Rivero',
    'Characato',
    'Mariano Melgar',
    'Alto Selva Alegre',
    'Hunter',
    'Tiabaya',
  ];

  final _formKey = GlobalKey<FormState>();
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _address = TextEditingController();
  final _business = TextEditingController();
  final _taxId = TextEditingController();
  final _document = TextEditingController();
  final _description = TextEditingController();
  UserRole _role = UserRole.generator;
  String _district = 'Arequipa';
  OrganizationType _organizationType = OrganizationType.other;
  GathererType _gathererType = GathererType.independent;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    for (final controller in [
      _first,
      _last,
      _email,
      _phone,
      _password,
      _address,
      _business,
      _taxId,
      _document,
      _description,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final api = ref.read(apiProvider);
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      // Sign-up is anonymous; the address and the role profile need the new account's token.
      final userId = await api.createUser(
        firstName: _first.text,
        lastName: _last.text,
        email: _email.text,
        password: _password.text,
        role: _role,
        phone: _phone.text,
      );
      final session = ref.read(sessionProvider);
      if (!await session.signIn(_email.text, _password.text)) {
        if (mounted) context.go('/acceso');
        return;
      }
      int? locationId;
      if (_role != UserRole.gatherer) {
        locationId = await api.createLocation(
          address: _address.text,
          district: _district,
        );
        await api.updateUser(
          session.user!,
          firstName: _first.text,
          lastName: _last.text,
          phone: _phone.text,
          locationId: locationId,
        );
      }
      if (_role == UserRole.organization) {
        await api.createOrganization(
          userId: userId,
          businessName: _business.text,
          type: _organizationType,
          taxId: _taxId.text,
          locationId: locationId,
        );
      }
      if (_role == UserRole.gatherer) {
        await api.createGatherer(
          userId: userId,
          type: _gathererType,
          description: _description.text.trim().isEmpty
              ? null
              : _description.text.trim(),
          document: _document.text.trim().isEmpty
              ? null
              : _document.text.trim(),
        );
      }
      await session.refresh();
    } on ApiFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Crea tu cuenta',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 16),
                  SegmentedButton<UserRole>(
                    segments: const [
                      ButtonSegment(
                        value: UserRole.generator,
                        label: Text('Hogar'),
                        icon: Icon(Icons.home_outlined),
                      ),
                      ButtonSegment(
                        value: UserRole.organization,
                        label: Text('Org.'),
                        icon: Icon(Icons.business_outlined),
                      ),
                      ButtonSegment(
                        value: UserRole.gatherer,
                        label: Text('Recolector'),
                        icon: Icon(Icons.local_shipping_outlined),
                      ),
                    ],
                    selected: {_role},
                    onSelectionChanged: (value) =>
                        setState(() => _role = value.first),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _field(
                          _first,
                          'Nombres',
                          required: 'Ingresa tu nombre',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _field(
                          _last,
                          'Apellidos',
                          required: 'Ingresa tus apellidos',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Correo'),
                    validator: (value) =>
                        RegExp(
                          r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                        ).hasMatch((value ?? '').trim())
                        ? null
                        : 'Ingresa un correo válido',
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    maxLength: 20,
                    decoration: const InputDecoration(
                      labelText: 'Teléfono (opcional)',
                    ),
                  ),
                  TextFormField(
                    controller: _password,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Contraseña',
                      helperText: 'Mínimo 8 caracteres',
                    ),
                    validator: (value) => (value ?? '').length < 8
                        ? 'Usa al menos 8 caracteres'
                        : null,
                  ),
                  if (_role != UserRole.gatherer) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _district,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Distrito'),
                      items: [
                        for (final item in _districts)
                          DropdownMenuItem(value: item, child: Text(item)),
                      ],
                      onChanged: (value) =>
                          setState(() => _district = value ?? 'Arequipa'),
                    ),
                    const SizedBox(height: 12),
                    _field(
                      _address,
                      'Dirección',
                      required: 'Indica tu dirección',
                    ),
                  ],
                  if (_role == UserRole.organization) ...[
                    const SizedBox(height: 12),
                    _field(
                      _business,
                      'Razón social',
                      required: 'Ingresa la razón social',
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _taxId,
                      keyboardType: TextInputType.number,
                      maxLength: 11,
                      decoration: const InputDecoration(
                        labelText: 'RUC (opcional)',
                      ),
                      validator: (value) {
                        final text = (value ?? '').trim();
                        return text.isEmpty || text.length == 11
                            ? null
                            : 'El RUC tiene 11 dígitos';
                      },
                    ),
                    DropdownButtonFormField<OrganizationType>(
                      initialValue: _organizationType,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de organización',
                      ),
                      items: [
                        for (final item in OrganizationType.values)
                          DropdownMenuItem(
                            value: item,
                            child: Text(item.label),
                          ),
                      ],
                      onChanged: (value) => setState(
                        () =>
                            _organizationType = value ?? OrganizationType.other,
                      ),
                    ),
                  ],
                  if (_role == UserRole.gatherer) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<GathererType>(
                      initialValue: _gathererType,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de recolector',
                      ),
                      items: [
                        for (final item in GathererType.values)
                          DropdownMenuItem(
                            value: item,
                            child: Text(item.label),
                          ),
                      ],
                      onChanged: (value) => setState(
                        () => _gathererType = value ?? GathererType.independent,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _document,
                      maxLength: 50,
                      decoration: const InputDecoration(
                        labelText: 'Documento de verificación',
                        helperText: 'DNI o RUC. El equipo lo revisará.',
                      ),
                    ),
                    TextFormField(
                      controller: _description,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Cuéntanos qué recoges y dónde',
                      ),
                    ),
                  ],
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _saving ? null : _submit,
                    child: _saving
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Crear cuenta'),
                  ),
                  TextButton(
                    onPressed: () => context.pushReplacement('/acceso'),
                    child: const Text('¿Ya tienes cuenta? Ingresa'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _field(
    TextEditingController controller,
    String label, {
    required String required,
  }) => TextFormField(
    controller: controller,
    textCapitalization: TextCapitalization.words,
    decoration: InputDecoration(labelText: label),
    validator: (value) => (value ?? '').trim().isEmpty ? required : null,
  );
}
