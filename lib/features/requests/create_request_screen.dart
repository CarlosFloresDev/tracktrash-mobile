import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import '../../app/providers.dart';
import '../../core/api_failure.dart';
import '../../data/enums.dart';
import '../../data/models.dart';
import '../../ui/async_content.dart';
import '../../ui/eco_design.dart';
import '../../ui/widgets.dart';
import 'request_actions.dart';

class _MaterialRow {
  int? residueTypeId;
  final quantity = TextEditingController(text: '1');
  MeasurementUnit unit = MeasurementUnit.kg;
}

class CreateRequestScreen extends ConsumerStatefulWidget {
  const CreateRequestScreen({super.key});

  @override
  ConsumerState<CreateRequestScreen> createState() =>
      _CreateRequestScreenState();
}

class _CreateRequestScreenState extends ConsumerState<CreateRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _rows = [_MaterialRow()];
  final _address = TextEditingController();
  final _district = TextEditingController(text: 'Arequipa');
  final _reference = TextEditingController();
  final _notes = TextEditingController();
  bool _useSaved = true;
  DateTime? _date;
  TimeOfDay _time = const TimeOfDay(hour: 9, minute: 0);
  double? _latitude;
  double? _longitude;
  bool _locating = false;
  bool _saving = false;

  @override
  void dispose() {
    for (final row in _rows) {
      row.quantity.dispose();
    }
    _address.dispose();
    _district.dispose();
    _reference.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _locate() async {
    setState(() => _locating = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw const ApiFailure('No tenemos permiso para usar tu ubicación.');
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          timeLimit: Duration(seconds: 10),
        ),
      );
      setState(() {
        _latitude = double.parse(position.latitude.toStringAsFixed(6));
        _longitude = double.parse(position.longitude.toStringAsFixed(6));
      });
    } catch (error) {
      if (mounted) {
        showFailure(
          context,
          error is ApiFailure
              ? error
              : 'No pudimos obtener tu ubicación. Puedes continuar sin ella.',
        );
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now.add(const Duration(days: 1)),
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 180)),
      locale: const Locale('es', 'PE'),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  String get _timeValue =>
      '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}';

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_date == null) {
      showFailure(context, 'Elige la fecha del recojo.');
      return;
    }
    final session = ref.read(sessionProvider);
    final savedId = session.user?.locationId;
    final useSaved = _useSaved && savedId != null;
    setState(() => _saving = true);
    try {
      final id = await ref
          .read(requestActionsProvider)
          .create(
            locationId: useSaved ? savedId : null,
            newLocation: useSaved
                ? null
                : (
                    address: _address.text,
                    district: _district.text,
                    reference: _reference.text,
                    latitude: _latitude,
                    longitude: _longitude,
                  ),
            date: _date!,
            time: _timeValue,
            observations: _notes.text,
            items: [
              for (final row in _rows)
                (
                  residueTypeId: row.residueTypeId!,
                  quantity: double.parse(
                    row.quantity.text.replaceAll(',', '.'),
                  ),
                  unit: row.unit,
                ),
            ],
          );
      if (!mounted) return;
      showSuccess(
        context,
        'Solicitud creada. Revisa las postulaciones de recolectores en el detalle.',
      );
      context.go('/solicitudes/$id');
    } on ApiFailure catch (failure) {
      if (mounted) showFailure(context, failure);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final residues = ref.watch(residueTypesProvider);
    final session = ref.watch(sessionProvider);
    final locations = ref.watch(locationByIdProvider);
    final saved = locations[session.user?.locationId];
    final canUseSaved = saved != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Nueva solicitud')),
      body: SafeArea(
        child: AsyncContent(
          value: residues,
          onRetry: () => ref.invalidate(residueTypesProvider),
          builder: (catalog) {
            final active = catalog
                .where((item) => item.isActive && item.isRecyclable)
                .toList();
            return Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  Text(
                    'Materiales',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Una fila por cada tipo de material.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 14),
                  for (var i = 0; i < _rows.length; i++)
                    _materialCard(i, active),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () =>
                          setState(() => _rows.add(_MaterialRow())),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Agregar otro material'),
                    ),
                  ),
                  const SectionTitle('Dirección de recojo'),
                  if (canUseSaved)
                    RadioGroup<bool>(
                      groupValue: _useSaved,
                      onChanged: (value) =>
                          setState(() => _useSaved = value ?? true),
                      child: Column(
                        children: [
                          RadioListTile<bool>(
                            value: true,
                            title: const Text('Mi dirección registrada'),
                            subtitle: Text(saved.summary),
                          ),
                          const RadioListTile<bool>(
                            value: false,
                            title: Text('Otra dirección'),
                          ),
                        ],
                      ),
                    ),
                  if (!canUseSaved || !_useSaved) ...[
                    TextFormField(
                      controller: _address,
                      decoration: const InputDecoration(labelText: 'Dirección'),
                      textCapitalization: TextCapitalization.words,
                      validator: (value) => (value ?? '').trim().isEmpty
                          ? 'Indica la dirección'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _district,
                      decoration: const InputDecoration(labelText: 'Distrito'),
                      validator: (value) => (value ?? '').trim().isEmpty
                          ? 'Indica el distrito'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _reference,
                      decoration: const InputDecoration(
                        labelText: 'Referencia (opcional)',
                        hintText: 'Frente al parque, portón verde',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: _locating ? null : _locate,
                          icon: _locating
                              ? const SizedBox.square(
                                  dimension: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.my_location_rounded),
                          label: const Text('Usar mi ubicación'),
                        ),
                        if (_latitude != null) ...[
                          const SizedBox(width: 12),
                          const Text(
                            'Coordenadas guardadas',
                            style: TextStyle(color: EcoColors.green),
                          ),
                        ],
                      ],
                    ),
                  ],
                  const SectionTitle('Cuándo'),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickDate,
                          icon: const Icon(
                            Icons.calendar_today_outlined,
                            size: 18,
                          ),
                          label: Text(
                            _date == null ? 'Elegir fecha' : formatDate(_date!),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickTime,
                          icon: const Icon(Icons.schedule_rounded, size: 18),
                          label: Text(_time.format(context)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _notes,
                    maxLines: 3,
                    maxLength: 500,
                    decoration: const InputDecoration(
                      labelText: 'Indicaciones (opcional)',
                      hintText: 'Cómo ubicarte, horarios de portería...',
                    ),
                  ),
                  if (session.organization != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Se registrará a nombre de ${session.organization!.businessName}.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _saving ? null : _submit,
                    child: _saving
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Enviar solicitud'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _materialCard(int index, List<ResidueType> active) {
    final row = _rows[index];
    final selected = active
        .where((item) => item.id == row.residueTypeId)
        .firstOrNull;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                MaterialBadge(
                  kind: materialKind(selected?.name ?? ''),
                  size: 40,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: row.residueTypeId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Material'),
                    items: [
                      for (final item in active)
                        DropdownMenuItem<int>(
                          value: item.id,
                          child: Text(item.name),
                        ),
                    ],
                    onChanged: (value) =>
                        setState(() => row.residueTypeId = value),
                    validator: (value) =>
                        value == null ? 'Elige un material' : null,
                  ),
                ),
                if (_rows.length > 1)
                  IconButton(
                    tooltip: 'Quitar material',
                    onPressed: () => setState(
                      () => _rows.removeAt(index).quantity.dispose(),
                    ),
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: row.quantity,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Cantidad'),
                    validator: (value) {
                      final number = double.tryParse(
                        (value ?? '').replaceAll(',', '.'),
                      );
                      if (number == null) return 'Ingresa una cantidad';
                      if (number < 0.01 || number > 100000) {
                        return 'Entre 0.01 y 100000';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<MeasurementUnit>(
                    initialValue: row.unit,
                    decoration: const InputDecoration(labelText: 'Unidad'),
                    items: [
                      for (final unit in MeasurementUnit.values)
                        DropdownMenuItem(value: unit, child: Text(unit.label)),
                    ],
                    onChanged: (value) =>
                        setState(() => row.unit = value ?? MeasurementUnit.kg),
                  ),
                ),
              ],
            ),
            if (selected?.instructions != null) ...[
              const SizedBox(height: 10),
              Text(
                selected!.instructions!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
