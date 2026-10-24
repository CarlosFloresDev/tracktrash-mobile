import 'package:flutter/foundation.dart';

@immutable
class MapPlace {
  const MapPlace({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    required this.kind,
    this.status = '',
    this.percent,
    this.address = '',
    this.materials = const [],
    this.demo = false,
    this.source = '',
    this.updatedAt,
  });
  final String id, name, kind, status, address, source;
  final double lat, lng;
  final int? percent;
  final List<String> materials;
  final bool demo;
  final DateTime? updatedAt;
  factory MapPlace.fromJson(Map<String, dynamic> j, String kind) => MapPlace(
    id: j['id'] as String,
    name: j['nombre'] as String,
    lat: (j['latitud'] as num).toDouble(),
    lng: (j['longitud'] as num).toDouble(),
    kind: kind,
    status: j['estado'] as String? ?? '',
    percent: j['porcentaje'] as int?,
    address: j['direccion'] as String? ?? '',
    source: j['fuente'] as String? ?? '',
    materials: List<String>.from(j['materiales'] as List? ?? []),
    demo: j['demostracion'] as bool? ?? false,
    updatedAt: DateTime.tryParse(j['actualizadoEn'] as String? ?? ''),
  );
}

@immutable
class CommunityMap {
  const CommunityMap(this.places, {this.cached = false});
  final List<MapPlace> places;
  final bool cached;
  factory CommunityMap.fromJson(
    Map<String, dynamic> j, {
    bool cached = false,
  }) => CommunityMap(
    List.unmodifiable([
      for (final x in j['contenedores'] as List)
        MapPlace.fromJson(x as Map<String, dynamic>, 'contenedor'),
      for (final x in j['asociaciones'] as List)
        MapPlace.fromJson(x as Map<String, dynamic>, 'asociacion'),
      for (final x in j['puntosAcopio'] as List)
        MapPlace.fromJson(x as Map<String, dynamic>, 'acopio'),
    ]),
    cached: cached,
  );
}

@immutable
class CommunityProfile {
  const CommunityProfile({
    required this.name,
    required this.phone,
    required this.address,
    required this.alerts,
    this.lat,
    this.lng,
    this.streak = 0,
    this.bestStreak = 0,
  });
  final String name, phone, address;
  final bool alerts;
  final double? lat, lng;
  final int streak, bestStreak;
  factory CommunityProfile.fromJson(Map<String, dynamic> j) => CommunityProfile(
    name: j['nombre'] as String,
    phone: j['telefono'] as String,
    address: j['direccion'] as String,
    alerts: j['recibirAvisos'] as bool,
    lat: (j['latitud'] as num?)?.toDouble(),
    lng: (j['longitud'] as num?)?.toDouble(),
    streak: j['rachaActual'] as int? ?? 0,
    bestStreak: j['rachaMaxima'] as int? ?? 0,
  );
  Map<String, dynamic> toJson() => {
    'nombre': name,
    'telefono': phone,
    'direccion': address,
    'recibirAvisos': alerts,
    'latitud': lat,
    'longitud': lng,
  };
}

@immutable
class CommunityIssue {
  const CommunityIssue(
    this.id,
    this.containerId,
    this.type,
    this.description,
    this.status,
    this.resolution,
  );
  final String id, containerId, type, description, status;
  final String? resolution;
  factory CommunityIssue.fromJson(Map<String, dynamic> j) => CommunityIssue(
    j['id'] as String,
    j['contenedorId'] as String,
    j['tipo'] as String,
    j['descripcion'] as String,
    j['estado'] as String,
    j['resolucion'] as String?,
  );
}

@immutable
class CommunityNotice {
  const CommunityNotice(this.id, this.title, this.message, this.read, this.at);
  final String id, title, message;
  final bool read;
  final DateTime at;
  factory CommunityNotice.fromJson(Map<String, dynamic> j) => CommunityNotice(
    j['id'] as String,
    j['titulo'] as String,
    j['mensaje'] as String,
    j['leida'] as bool,
    DateTime.parse(j['creadaEn'] as String),
  );
}

@immutable
class Reward {
  const Reward(
    this.id,
    this.name,
    this.description,
    this.cost,
    this.stock,
    this.demo,
  );
  final String id, name, description;
  final int cost, stock;
  final bool demo;
  factory Reward.fromJson(Map<String, dynamic> j) => Reward(
    j['id'] as String,
    j['nombre'] as String,
    j['descripcion'] as String,
    j['costoPuntos'] as int,
    j['stock'] as int,
    j['demostracion'] as bool,
  );
}

@immutable
class Redemption {
  const Redemption(this.id, this.code, this.cost);
  final String id, code;
  final int cost;
  factory Redemption.fromJson(Map<String, dynamic> j) => Redemption(
    j['id'] as String,
    j['codigo'] as String,
    j['puntosUsados'] as int,
  );
}

@immutable
class OperationMetrics {
  const OperationMetrics(
    this.bins,
    this.full,
    this.issues,
    this.pickups,
    this.estimatedKg,
  );
  final int bins, full, issues, pickups;
  final double estimatedKg;
  factory OperationMetrics.fromJson(Map<String, dynamic> j) => OperationMetrics(
    j['contenedores'] as int,
    j['saturados'] as int,
    j['incidenciasAbiertas'] as int,
    j['recojosConfirmados'] as int,
    (j['kgEstimadosConfirmados'] as num).toDouble(),
  );
}
