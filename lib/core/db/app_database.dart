/// Plattform-Router für die lokale SQLite-Datenbank.
/// • Mobile (Android/iOS/macOS): sqflite (app_database_io.dart)
/// • Web: No-Op-Stub — kein SQLite auf Web (app_database_web.dart)
library;

export 'app_database_io.dart' if (dart.library.html) 'app_database_web.dart';
