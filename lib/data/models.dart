import 'package:flutter/foundation.dart';
import 'enums.dart';

typedef Json = Map<String, dynamic>;

double _double(Object? value) => (value as num).toDouble();
double? _doubleOrNull(Object? value) => (value as num?)?.toDouble();
DateTime _timestamp(Object? value) => DateTime.parse(value! as String).toLocal();
DateTime? _timestampOrNull(Object? value) =>
    value == null ? null : _timestamp(value);

@immutable
class User {
  const User({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
    required this.isActive,
    this.phone,
    this.locationId,
  });

  final int userId;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final UserRole role;
  final int? locationId;
  final bool isActive;

  String get fullName => '$firstName $lastName'.trim();
  String get initials =>
      '${firstName.isEmpty ? '' : firstName[0]}${lastName.isEmpty ? '' : lastName[0]}'
          .toUpperCase();

  factory User.fromJson(Json json) => User(
    userId: json['userId'] as int,
    firstName: json['firstName'] as String,
    lastName: json['lastName'] as String,
    email: json['email'] as String,
    phone: json['phone'] as String?,
    role: UserRole.parse(json['roleId'] as String),
    locationId: json['locationId'] as int?,
    isActive: json['isActive'] as bool,
  );
}

@immutable
class Location {
  const Location({
    required this.locationId,
    required this.address,
    required this.district,
    this.reference,
    this.latitude,
    this.longitude,
  });

  final int locationId;
  final String address;
  final String district;
  final String? reference;
  final double? latitude;
  final double? longitude;

  bool get hasCoordinates => latitude != null && longitude != null;
  String get summary => '$address, $district';

  factory Location.fromJson(Json json) => Location(
    locationId: json['locationId'] as int,
    address: json['address'] as String,
    district: json['district'] as String,
    reference: json['reference'] as String?,
    latitude: _doubleOrNull(json['latitude']),
    longitude: _doubleOrNull(json['longitude']),
  );
}

@immutable
class CollectRequest {
  const CollectRequest({
    required this.id,
    required this.userId,
    required this.locationId,
    required this.requestedAt,
    required this.scheduledDate,
    required this.scheduledTime,
    required this.status,
    this.organizationId,
    this.observations,
  });

  final int id;
  final int userId;
  final int? organizationId;
  final int locationId;
  final DateTime requestedAt;
  final DateTime scheduledDate;
  final String scheduledTime;
  final RequestStatus status;
  final String? observations;

  String get timeLabel => scheduledTime.length >= 5
      ? scheduledTime.substring(0, 5)
      : scheduledTime;

  factory CollectRequest.fromJson(Json json) => CollectRequest(
    id: json['collectRequestId'] as int,
    userId: json['userId'] as int,
    organizationId: json['organizationId'] as int?,
    locationId: json['locationId'] as int,
    requestedAt: _timestamp(json['requestedAt']),
    scheduledDate: DateTime.parse(json['scheduledDate'] as String),
    scheduledTime: json['scheduledTime'] as String,
    status: RequestStatus.parse(json['statusId'] as String),
    observations: json['observations'] as String?,
  );
}

@immutable
class RequestDetail {
  const RequestDetail({
    required this.id,
    required this.collectRequestId,
    required this.residueTypeId,
    required this.quantity,
    required this.unit,
  });

  final int id;
  final int collectRequestId;
  final int residueTypeId;
  final double quantity;
  final MeasurementUnit unit;

  factory RequestDetail.fromJson(Json json) => RequestDetail(
    id: json['requestDetailId'] as int,
    collectRequestId: json['collectRequestId'] as int,
    residueTypeId: json['residueTypeId'] as int,
    quantity: _double(json['estimatedQuantity']),
    unit: MeasurementUnit.parse(json['unitId'] as String),
  );
}

@immutable
class PickupService {
  const PickupService({
    required this.id,
    required this.collectRequestId,
    required this.gathererId,
    required this.assignedAt,
    required this.status,
    this.startedAt,
    this.completedAt,
  });

  final int id;
  final int collectRequestId;
  final int gathererId;
  final DateTime assignedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final RequestStatus status;

  factory PickupService.fromJson(Json json) => PickupService(
    id: json['pickupServiceId'] as int,
    collectRequestId: json['collectRequestId'] as int,
    gathererId: json['gathererId'] as int,
    assignedAt: _timestamp(json['assignedAt']),
    startedAt: _timestampOrNull(json['startedAt']),
    completedAt: _timestampOrNull(json['completedAt']),
    status: RequestStatus.parse(json['statusId'] as String),
  );
}

@immutable
class CollectRequestFull {
  const CollectRequestFull({
    required this.request,
    required this.location,
    required this.details,
    this.service,
  });

  final CollectRequest request;
  final Location location;
  final List<RequestDetail> details;
  final PickupService? service;

  factory CollectRequestFull.fromJson(Json json) => CollectRequestFull(
    request: CollectRequest.fromJson(json['request'] as Json),
    location: Location.fromJson(json['location'] as Json),
    details: [
      for (final item in json['details'] as List)
        RequestDetail.fromJson(item as Json),
    ],
    service: json['pickupService'] == null
        ? null
        : PickupService.fromJson(json['pickupService'] as Json),
  );
}

@immutable
class RequestHistory {
  const RequestHistory({
    required this.id,
    required this.newStatus,
    required this.createdAt,
    this.previousStatus,
    this.observations,
  });

  final int id;
  final RequestStatus? previousStatus;
  final RequestStatus newStatus;
  final String? observations;
  final DateTime createdAt;

  factory RequestHistory.fromJson(Json json) => RequestHistory(
    id: json['requestHistoryId'] as int,
    previousStatus: json['previousStatusId'] == null
        ? null
        : RequestStatus.parse(json['previousStatusId'] as String),
    newStatus: RequestStatus.parse(json['newStatusId'] as String),
    observations: json['observations'] as String?,
    createdAt: _timestamp(json['createdAt']),
  );
}

@immutable
class Gatherer {
  const Gatherer({
    required this.gathererId,
    required this.userId,
    required this.type,
    required this.verification,
    required this.isActive,
    this.description,
    this.verificationDocument,
  });

  final int gathererId;
  final int userId;
  final GathererType type;
  final String? description;
  final String? verificationDocument;
  final VerificationStatus verification;
  final bool isActive;

  bool get canTakeRequests =>
      verification == VerificationStatus.verified && isActive;

  factory Gatherer.fromJson(Json json) => Gatherer(
    gathererId: json['gathererId'] as int,
    userId: json['userId'] as int,
    type: GathererType.parse(json['gathererTypeId'] as String),
    description: json['description'] as String?,
    verificationDocument: json['verificationDocument'] as String?,
    verification: VerificationStatus.parse(
      json['verificationStatusId'] as String,
    ),
    isActive: json['isActive'] as bool,
  );
}

@immutable
class Organization {
  const Organization({
    required this.organizationId,
    required this.userId,
    required this.businessName,
    required this.type,
    this.taxId,
  });

  final int organizationId;
  final int userId;
  final String businessName;
  final String? taxId;
  final OrganizationType type;

  factory Organization.fromJson(Json json) => Organization(
    organizationId: json['organizationId'] as int,
    userId: json['userId'] as int,
    businessName: json['businessName'] as String,
    taxId: json['taxId'] as String?,
    type: OrganizationType.parse(json['organizationTypeId'] as String),
  );
}

@immutable
class ResidueType {
  const ResidueType({
    required this.id,
    required this.name,
    required this.category,
    required this.isRecyclable,
    required this.isActive,
    this.description,
    this.instructions,
  });

  final int id;
  final String name;
  final ResidueCategory category;
  final String? description;
  final bool isRecyclable;
  final String? instructions;
  final bool isActive;

  factory ResidueType.fromJson(Json json) => ResidueType(
    id: json['residueTypeId'] as int,
    name: json['name'] as String,
    category: ResidueCategory.parse(json['residueCategoryId'] as String),
    description: json['description'] as String?,
    isRecyclable: json['isRecyclable'] as bool,
    instructions: json['classificationInstructions'] as String?,
    isActive: json['isActive'] as bool,
  );
}

@immutable
class CollectionPoint {
  const CollectionPoint({
    required this.id,
    required this.name,
    required this.locationId,
    required this.isActive,
    this.managerName,
    this.phone,
    this.openingHours,
    this.description,
  });

  final int id;
  final String name;
  final String? managerName;
  final String? phone;
  final int locationId;
  final String? openingHours;
  final String? description;
  final bool isActive;

  factory CollectionPoint.fromJson(Json json) => CollectionPoint(
    id: json['collectionPointId'] as int,
    name: json['name'] as String,
    managerName: json['managerName'] as String?,
    phone: json['phone'] as String?,
    locationId: json['locationId'] as int,
    openingHours: json['openingHours'] as String?,
    description: json['description'] as String?,
    isActive: json['isActive'] as bool,
  );
}

@immutable
class RecoveredMaterial {
  const RecoveredMaterial({
    required this.id,
    required this.pickupServiceId,
    required this.residueTypeId,
    required this.quantity,
    required this.unit,
  });

  final int id;
  final int pickupServiceId;
  final int residueTypeId;
  final double quantity;
  final MeasurementUnit unit;

  factory RecoveredMaterial.fromJson(Json json) => RecoveredMaterial(
    id: json['recoveredMaterialId'] as int,
    pickupServiceId: json['pickupServiceId'] as int,
    residueTypeId: json['residueTypeId'] as int,
    quantity: _double(json['quantity']),
    unit: MeasurementUnit.parse(json['unitId'] as String),
  );
}

@immutable
class Grade {
  const Grade({
    required this.id,
    required this.pickupServiceId,
    required this.userId,
    required this.score,
    this.comment,
  });

  final int id;
  final int pickupServiceId;
  final int userId;
  final int score;
  final String? comment;

  factory Grade.fromJson(Json json) => Grade(
    id: json['gradeId'] as int,
    pickupServiceId: json['pickupServiceId'] as int,
    userId: json['userId'] as int,
    score: json['score'] as int,
    comment: json['comment'] as String?,
  );
}

@immutable
class GathererRating {
  const GathererRating({
    required this.gathererId,
    required this.averageScore,
    required this.totalGrades,
  });

  final int? gathererId;
  final double averageScore;
  final int totalGrades;

  factory GathererRating.fromJson(Json json) => GathererRating(
    gathererId: json['gathererId'] as int?,
    averageScore: _double(json['averageScore']),
    totalGrades: (json['totalGrades'] as num).toInt(),
  );
}

@immutable
class GeneralIndicators {
  const GeneralIndicators({
    required this.recoveredKilograms,
    required this.completedServices,
    required this.verifiedGatherers,
    required this.totalRequests,
  });

  final double recoveredKilograms;
  final int completedServices;
  final int verifiedGatherers;
  final int totalRequests;

  factory GeneralIndicators.fromJson(Json json) => GeneralIndicators(
    recoveredKilograms: _double(json['recoveredKilograms']),
    completedServices: (json['completedServices'] as num).toInt(),
    verifiedGatherers: (json['verifiedGatherers'] as num).toInt(),
    totalRequests: (json['totalRequests'] as num).toInt(),
  );
}
