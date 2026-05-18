// Web-Stub für das health Package (Android/iOS only).
// Alle Methoden geben leere/false-Ergebnisse — auf Web gibt es keine
// HealthKit/Health-Connect-Integration.

enum HealthDataType {
  HEART_RATE,
  HEART_RATE_VARIABILITY_SDNN,
  RESTING_HEART_RATE,
}

enum HealthDataAccess { READ, WRITE }

class HealthValue {
  const HealthValue();
}

class NumericHealthValue extends HealthValue {
  final num numericValue;
  const NumericHealthValue(this.numericValue) : super();
}

class HealthDataPoint {
  final HealthValue value;
  final HealthDataType type;
  final DateTime dateFrom;
  final DateTime dateTo;
  final String sourceName;
  final String sourceId;
  HealthDataPoint({
    required this.value,
    required this.type,
    DateTime? dateFrom,
    DateTime? dateTo,
    this.sourceName = '',
    this.sourceId = '',
  })  : dateFrom = dateFrom ?? DateTime.now(),
        dateTo = dateTo ?? DateTime.now();
}

/// Mirror of health 13.x enum — kept as numeric values so the
/// stub side stays trivially comparable.
enum HealthConnectSdkStatus {
  sdkUnavailable,
  sdkUnavailableProviderUpdateRequired,
  sdkAvailable,
}

class Health {
  Future<void> configure() async {}

  Future<bool?> hasPermissions(
    List<HealthDataType> types, {
    List<HealthDataAccess>? permissions,
  }) async =>
      false;

  Future<bool> requestAuthorization(
    List<HealthDataType> types, {
    List<HealthDataAccess>? permissions,
  }) async =>
      false;

  Future<List<HealthDataPoint>> getHealthDataFromTypes({
    required List<HealthDataType> types,
    required DateTime startTime,
    required DateTime endTime,
  }) async =>
      [];

  Future<HealthConnectSdkStatus> getHealthConnectSdkStatus() async =>
      HealthConnectSdkStatus.sdkUnavailable;

  Future<void> installHealthConnect() async {}
}
