import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';
import '../../core/api_failure.dart';
import '../../ui/eco_design.dart';
import '../../ui/widgets.dart';
import 'gatherer_materials.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final _first = TextEditingController(
    text: ref.read(sessionProvider).user!.firstName,
  );
  late final _last = TextEditingController(
    text: ref.read(sessionProvider).user!.lastName,
  );
  late final _phone = TextEditingController(
    text: ref.read(sessionProvider).user!.phone ?? '',
  );
  bool _saving = false;

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final session = ref.read(sessionProvider);
    setState(() => _saving = true);
    try {
      await ref
          .read(apiProvider)
          .updateUser(
            session.user!,
            firstName: _first.text,
            lastName: _last.text,
            phone: _phone.text,
          );
      await session.refresh();
      if (mounted) showSuccess(context, 'Perfil actualizado.');
    } on ApiFailure catch (failure) {
      if (mounted) showFailure(context, failure);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final user = session.user!;
    final gatherer = session.gatherer;
    final organization = session.organization;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: EcoColors.lime,
              child: Text(
                user.initials,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  color: EcoColors.pine,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.fullName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    '${user.role.label} · ${user.email}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
        if (organization != null) ...[
          const SectionTitle('Organización'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InfoRow(
                    icon: Icons.business_outlined,
                    text: organization.businessName,
                  ),
                  InfoRow(
                    icon: Icons.category_outlined,
                    text: organization.type.label,
                  ),
                  if (organization.taxId != null)
                    InfoRow(
                      icon: Icons.badge_outlined,
                      text: 'RUC ${organization.taxId}',
                    ),
                ],
              ),
            ),
          ),
        ],
        if (gatherer != null) ...[
          const SectionTitle('Recolector'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InfoRow(
                    icon: Icons.verified_user_outlined,
                    text: gatherer.verification.label,
                  ),
                  InfoRow(
                    icon: Icons.local_shipping_outlined,
                    text: gatherer.type.label,
                  ),
                  if (gatherer.verificationDocument != null)
                    InfoRow(
                      icon: Icons.badge_outlined,
                      text: gatherer.verificationDocument!,
                    ),
                  if (gatherer.description != null)
                    InfoRow(
                      icon: Icons.notes_rounded,
                      text: gatherer.description!,
                    ),
                ],
              ),
            ),
          ),
          const SectionTitle('Materiales que aceptas'),
          GathererMaterialsCard(gatherer: gatherer),
        ],
        const SectionTitle('Datos personales'),
        Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _first,
                decoration: const InputDecoration(labelText: 'Nombres'),
                validator: (value) =>
                    (value ?? '').trim().isEmpty ? 'Ingresa tu nombre' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _last,
                decoration: const InputDecoration(labelText: 'Apellidos'),
                validator: (value) => (value ?? '').trim().isEmpty
                    ? 'Ingresa tus apellidos'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                maxLength: 20,
                decoration: const InputDecoration(labelText: 'Teléfono'),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Guardar cambios'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: () => ref.read(sessionProvider).signOut(),
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Cerrar sesión'),
        ),
      ],
    );
  }
}
