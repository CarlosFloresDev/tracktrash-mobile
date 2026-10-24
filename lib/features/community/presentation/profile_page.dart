import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../app/providers.dart';
import '../../../ui/eco_design.dart';
import '../../../ui/async_content.dart';
import '../domain/community_models.dart';
import 'community_providers.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => ListView(
    padding: const EdgeInsets.all(22),
    children: [
      Text(
        'Tu espacio en TrackTrash.',
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      const SizedBox(height: 10),
      const Text(
        'Mantén tu información al día y decide cómo quieres participar.',
      ),
      const SizedBox(height: 22),
      AsyncContent(
        value: ref.watch(profileProvider),
        onRetry: () => ref.invalidate(profileProvider),
        builder: (profile) => _ProfileForm(profile: profile),
      ),
      const SizedBox(height: 20),
      OutlinedButton.icon(
        onPressed: () => ref.read(sessionProvider).signOut(),
        icon: const Icon(Icons.logout),
        label: const Text('Cerrar sesión'),
      ),
    ],
  );
}

class _ProfileForm extends ConsumerStatefulWidget {
  const _ProfileForm({required this.profile});
  final CommunityProfile profile;
  @override
  ConsumerState<_ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends ConsumerState<_ProfileForm> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name, _phone, _address;
  late bool _alerts;
  double? _lat, _lng;
  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.profile.name);
    _phone = TextEditingController(text: widget.profile.phone);
    _address = TextEditingController(text: widget.profile.address);
    _alerts = widget.profile.alerts;
    _lat = widget.profile.lat;
    _lng = widget.profile.lng;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final actions = ref.watch(communityActionsProvider);
    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const CircleAvatar(
            radius: 34,
            backgroundColor: EcoColors.lime,
            child: Icon(Icons.person_outline, size: 38, color: EcoColors.pine),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _name,
            enabled: !actions.busy,
            maxLength: 100,
            decoration: const InputDecoration(labelText: 'Tu nombre'),
            validator: (v) =>
                (v?.trim().length ?? 0) < 2 ? 'Escribe tu nombre.' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _phone,
            enabled: !actions.busy,
            maxLength: 20,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Teléfono de contacto',
            ),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _address,
            enabled: !actions.busy,
            maxLength: 250,
            decoration: const InputDecoration(
              labelText: 'Dirección de referencia',
            ),
          ),
          OutlinedButton.icon(
            onPressed: actions.busy ? null : _location,
            icon: const Icon(Icons.my_location),
            label: Text(
              _lat == null
                  ? 'Añadir ubicación de referencia'
                  : 'Ubicación guardada · actualizar',
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Avisos de actividad'),
            subtitle: const Text(
              'Guarda tu preferencia para avisos de recojos y reportes.',
            ),
            value: _alerts,
            onChanged: actions.busy ? null : (v) => setState(() => _alerts = v),
          ),
          if (actions.error != null)
            Text(
              actions.error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: actions.busy
                ? null
                : () async {
                    if (!_form.currentState!.validate()) return;
                    final ok = await actions.saveProfile(
                      CommunityProfile(
                        name: _name.text.trim(),
                        phone: _phone.text.trim(),
                        address: _address.text.trim(),
                        alerts: _alerts,
                        lat: _lat,
                        lng: _lng,
                      ),
                    );
                    if (ok && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Perfil actualizado.')),
                      );
                    }
                  },
            child: Text(actions.busy ? 'Guardando…' : 'Guardar cambios'),
          ),
        ],
      ),
    );
  }

  Future<void> _location() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception();
      }
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          timeLimit: Duration(seconds: 10),
        ),
      );
      if (mounted) {
        setState(() {
          _lat = p.latitude;
          _lng = p.longitude;
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se obtuvo tu ubicación. Puedes completar el resto del perfil.',
            ),
          ),
        );
      }
    }
  }
}
