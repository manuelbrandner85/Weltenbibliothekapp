import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Centralized SQLite database for offline data (sync queue, articles, chat cache).
class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  Database? _db;

  Future<Database> get db async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final path = join(await getDatabasesPath(), 'weltenbibliothek_cache.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS offline_actions (
            id         TEXT PRIMARY KEY,
            type       TEXT NOT NULL,
            data       TEXT NOT NULL,
            timestamp  TEXT NOT NULL,
            retry_count INTEGER DEFAULT 0,
            user_id    TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS offline_articles (
            id       TEXT PRIMARY KEY,
            content  TEXT NOT NULL,
            saved_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS chat_messages (
            id         TEXT PRIMARY KEY,
            room_id    TEXT NOT NULL,
            data       TEXT NOT NULL,
            created_at INTEGER NOT NULL
          )
        ''');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_cm_room ON chat_messages(room_id)');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS chat_rooms (
            room_id TEXT PRIMARY KEY,
            data    TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS chat_presence (
            user_id TEXT NOT NULL,
            room_id TEXT NOT NULL,
            data    TEXT NOT NULL,
            PRIMARY KEY (user_id, room_id)
          )
        ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS chat_pending_sync (
            id   TEXT PRIMARY KEY,
            data TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS kv_store (
            key   TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
