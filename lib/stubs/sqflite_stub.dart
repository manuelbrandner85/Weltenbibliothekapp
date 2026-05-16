// Web-Stub für sqflite (Android/iOS/macOS only).
// ConflictAlgorithm wird in den Service-Dateien als Enum-Wert benötigt,
// hat aber auf Web keine Funktion (alle DB-Operationen sind No-Ops).

enum ConflictAlgorithm { rollback, abort, fail, ignore, replace }
