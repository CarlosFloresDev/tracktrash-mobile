/// Enumerations of the backend contract. The API serializes them by name (e.g. `"InProgress"`).
enum UserRole {
  admin('Admin', 'Administrador'),
  generator('Generator', 'Hogar'),
  organization('Organization', 'Organización'),
  gatherer('Gatherer', 'Recolector');

  const UserRole(this.api, this.label);
  final String api;
  final String label;

  static UserRole parse(String value) =>
      values.firstWhere((role) => role.api == value, orElse: () => generator);
}

enum RequestStatus {
  pending('Pending', 'Pendiente'),
  assigned('Assigned', 'Asignada'),
  inProgress('InProgress', 'En camino'),
  completed('Completed', 'Completada'),
  cancelled('Cancelled', 'Cancelada');

  const RequestStatus(this.api, this.label);
  final String api;
  final String label;

  bool get isFinal => this == completed || this == cancelled;
  bool get isActive => !isFinal;

  /// Mirrors `CollectRequestStatusRules` in the backend.
  static const _transitions = {
    pending: [assigned, cancelled],
    assigned: [inProgress, pending, cancelled],
    inProgress: [completed, cancelled],
    completed: <RequestStatus>[],
    cancelled: <RequestStatus>[],
  };

  List<RequestStatus> get next => _transitions[this]!;

  static RequestStatus parse(String value) =>
      values.firstWhere((status) => status.api == value, orElse: () => pending);
}

enum GathererType {
  independent('Independent', 'Independiente'),
  company('Company', 'Empresa'),
  recycler('Recycler', 'Reciclador');

  const GathererType(this.api, this.label);
  final String api;
  final String label;

  static GathererType parse(String value) => values.firstWhere(
    (type) => type.api == value,
    orElse: () => independent,
  );
}

enum VerificationStatus {
  pending('Pending', 'En revisión'),
  verified('Verified', 'Verificado'),
  rejected('Rejected', 'Rechazado');

  const VerificationStatus(this.api, this.label);
  final String api;
  final String label;

  static VerificationStatus parse(String value) => values.firstWhere(
    (status) => status.api == value,
    orElse: () => pending,
  );
}

enum MeasurementUnit {
  kg('Kg', 'kg'),
  unit('Unit', 'unidades'),
  liters('Liters', 'litros');

  const MeasurementUnit(this.api, this.label);
  final String api;
  final String label;

  static MeasurementUnit parse(String value) =>
      values.firstWhere((unit) => unit.api == value, orElse: () => kg);
}

enum ResidueCategory {
  recyclable('Recyclable', 'Reciclable'),
  organic('Organic', 'Orgánico'),
  general('General', 'General');

  const ResidueCategory(this.api, this.label);
  final String api;
  final String label;

  static ResidueCategory parse(String value) => values.firstWhere(
    (category) => category.api == value,
    orElse: () => general,
  );
}

enum OrganizationType {
  educationalInstitution('EducationalInstitution', 'Institución educativa'),
  company('Company', 'Empresa'),
  restaurant('Restaurant', 'Restaurante'),
  foodIndustry('FoodIndustry', 'Industria alimentaria'),
  other('Other', 'Otro');

  const OrganizationType(this.api, this.label);
  final String api;
  final String label;

  static OrganizationType parse(String value) => values.firstWhere(
    (type) => type.api == value,
    orElse: () => other,
  );
}
