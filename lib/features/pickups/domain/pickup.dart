import 'package:flutter/foundation.dart';

enum RecyclableMaterial {
  paper(
    'PapelCarton',
    'Papel y cartón',
    'Limpios, secos y sin restos de comida.',
  ),
  plastic(
    'Plastico',
    'Plástico',
    'Envases limpios; consulta cuáles acepta tu reciclador.',
  ),
  glass('Vidrio', 'Vidrio', 'Envases separados. Avisa si hay piezas rotas.'),
  metal('Metal', 'Metal', 'Latas limpias y sin residuos peligrosos.');

  const RecyclableMaterial(this.apiValue, this.label, this.tip);
  final String apiValue;
  final String label;
  final String tip;
}

@immutable
class Pickup {
  const Pickup({
    required this.id,
    required this.material,
    required this.estimatedKg,
    required this.scheduledAt,
    required this.status,
    this.address,
    this.code,
  });
  final String id;
  final String material;
  final double estimatedKg;
  final DateTime scheduledAt;
  final String status;
  final String? address;
  final String? code;

  String get materialLabel =>
      RecyclableMaterial.values
          .where((m) => m.apiValue == material)
          .map((m) => m.label)
          .firstOrNull ??
      material;

  factory Pickup.fromJson(Map<String, dynamic> json) => Pickup(
    id: json['id'] as String,
    material: json['material'] as String,
    estimatedKg: (json['cantidadEstimadaKg'] as num).toDouble(),
    scheduledAt: DateTime.parse(json['programadaPara'] as String).toLocal(),
    status: json['estado'] as String,
    address: json['direccion'] as String?,
    code: json['codigoConfirmacion'] as String?,
  );
}

@immutable
class PickupDraft {
  const PickupDraft({
    required this.key,
    required this.material,
    required this.kg,
    required this.address,
    required this.scheduledAt,
  });
  final String key;
  final RecyclableMaterial material;
  final double kg;
  final String address;
  final DateTime scheduledAt;

  Map<String, dynamic> toJson() => {
    'claveSolicitud': key,
    'material': material.apiValue,
    'cantidadEstimadaKg': kg,
    'direccion': address.trim(),
    'programadaPara': scheduledAt.toUtc().toIso8601String(),
  };
}
