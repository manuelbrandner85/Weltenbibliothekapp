// Web-Stub für AppDatabase — sqflite läuft nicht auf Web.
// Alle Datenbankoperationen sind No-Ops.

import '../../stubs/sqflite_stub.dart';

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  final Database _db = Database();

  Future<Database> get db async => _db;

  Future<void> close() async {}
}
