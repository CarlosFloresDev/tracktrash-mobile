import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../app/providers.dart';
import '../domain/pickup.dart';

class CreatePickupScreen extends ConsumerStatefulWidget {
  const CreatePickupScreen({super.key});
  @override
  ConsumerState<CreatePickupScreen> createState() => _CreatePickupScreenState();
}

class _CreatePickupScreenState extends ConsumerState<CreatePickupScreen> {
  final _form = GlobalKey<FormState>();
  final _kg = TextEditingController();
  final _address = TextEditingController();
  RecyclableMaterial _material = RecyclableMaterial.paper;
  DateTime _scheduledAt = DateTime.now().add(const Duration(days: 1));
  String _requestKey = const Uuid().v4();

  void _edited() => _requestKey = const Uuid().v4();

  @override
  void dispose() {
    _kg.dispose();
    _address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final model = ref.watch(pickupsProvider);
    final state = model.state;
    return PopScope(
      canPop: !state.saving,
      child: Scaffold(
        appBar: AppBar(title: const Text('Solicitar un recojo')),
        body: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Lo que separas\ntiene una nueva oportunidad.',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Indica el material y coordina una fecha. La cantidad es una estimación.',
                    ),
                    const SizedBox(height: 28),
                    DropdownButtonFormField<RecyclableMaterial>(
                      initialValue: _material,
                      decoration: const InputDecoration(labelText: 'Material'),
                      items: RecyclableMaterial.values
                          .map(
                            (m) => DropdownMenuItem(
                              value: m,
                              child: Text(m.label),
                            ),
                          )
                          .toList(),
                      onChanged: state.saving
                          ? null
                          : (m) {
                              _edited();
                              setState(() => _material = m!);
                            },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const Key('pickup-kg'),
                      controller: _kg,
                      enabled: !state.saving,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: (_) => _edited(),
                      decoration: const InputDecoration(
                        labelText: 'Cantidad estimada',
                        suffixText: 'kg',
                      ),
                      validator: (v) {
                        final kg = double.tryParse(
                          (v ?? '').replaceAll(',', '.'),
                        );
                        return kg != null && kg.isFinite && kg > 0 && kg <= 500
                            ? null
                            : 'Ingresa un peso mayor a 0 y hasta 500 kg.';
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const Key('pickup-address'),
                      controller: _address,
                      enabled: !state.saving,
                      maxLength: 250,
                      onChanged: (_) => _edited(),
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Dirección y referencia',
                      ),
                      validator: (v) => (v?.trim().length ?? 0) >= 8
                          ? null
                          : 'Escribe una dirección con al menos 8 caracteres.',
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: state.saving ? null : _selectDate,
                      icon: const Icon(Icons.event_outlined),
                      label: Text(
                        DateFormat(
                          'd MMM yyyy · HH:mm',
                          'es_PE',
                        ).format(_scheduledAt),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'La dirección solo se comparte con el reciclador que acepte tu solicitud.',
                    ),
                    if (state.error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                          state.error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    const SizedBox(height: 28),
                    FilledButton.icon(
                      key: const Key('submit-pickup'),
                      onPressed: state.saving || state.loading ? null : _submit,
                      icon: state.saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check),
                      label: Text(
                        state.saving ? 'Enviando…' : 'Confirmar solicitud',
                      ),
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

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledAt,
      firstDate: now,
      lastDate: now.add(const Duration(days: 29)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledAt),
    );
    if (time == null || !mounted) return;
    _edited();
    setState(
      () => _scheduledAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      ),
    );
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    if (!_scheduledAt.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Elige una fecha y hora futuras.')),
      );
      return;
    }
    final ok = await ref
        .read(pickupsProvider)
        .create(
          PickupDraft(
            key: _requestKey,
            material: _material,
            kg: double.parse(_kg.text.replaceAll(',', '.')),
            address: _address.text,
            scheduledAt: _scheduledAt,
          ),
        );
    if (ok && mounted) {
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Solicitud registrada. Puedes consultar su estado en Mis recojos.',
          ),
        ),
      );
    }
  }
}
