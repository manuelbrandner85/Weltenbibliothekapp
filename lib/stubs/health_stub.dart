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
  const HealthDataPoint({required this.value, required this.type});
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
}
