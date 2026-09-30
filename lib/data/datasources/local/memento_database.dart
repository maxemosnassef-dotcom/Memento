import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

import '../../../core/security/key_vault.dart';

class MementoDatabase {
  static const String _databaseName = 'memento_vault.db';
  static const int _schemaVersion = 1;

  final KeyVault _keyVault;
  Database? _handle;

  MementoDatabase(this._keyVault);

  Future<Database> get instance async {
    final existing = _handle;
    if (existing != null && existing.isOpen) return existing;

    final documents = await getApplicationDocumentsDirectory();
    final handle = await openDatabase(
      p.join(documents.path, _databaseName),
      password: await _keyVault.databasePassphrase(),
      version: _schemaVersion,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    _handle = handle;
    return handle;
  }

  Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();

    batch.execute('''
      CREATE TABLE memories (
        seq INTEGER PRIMARY KEY AUTOINCREMENT,
        id TEXT NOT NULL UNIQUE,
        title TEXT NOT NULL,
        journal TEXT,
        moment_utc_ms INTEGER NOT NULL,
        latitude REAL,
        longitude REAL,
        geohash TEXT,
        mem_month INTEGER GENERATED ALWAYS AS (
          CAST(strftime('%m', moment_utc_ms / 1000, 'unixepoch') AS INTEGER)
        ) STORED,
        mem_day INTEGER GENERATED ALWAYS AS (
          CAST(strftime('%d', moment_utc_ms / 1000, 'unixepoch') AS INTEGER)
        ) STORED,
        created_at_utc_ms INTEGER NOT NULL,
        updated_at_utc_ms INTEGER NOT NULL
      )
    ''');

    batch.execute(
      'CREATE INDEX idx_memories_moment ON memories(moment_utc_ms)',
    );
    batch.execute(
      'CREATE INDEX idx_memories_calendar ON memories(mem_month, mem_day)',
    );
    batch.execute(
      'CREATE INDEX idx_memories_geohash ON memories(geohash)',
    );

    batch.execute('''
      CREATE VIRTUAL TABLE memory_geo USING rtree(
        seq,
        min_lat, max_lat,
        min_lng, max_lng
      )
    ''');

    batch.execute('''
      CREATE TABLE contacts (
        id TEXT PRIMARY KEY,
        display_name TEXT NOT NULL,
        birthday_month INTEGER,
        birthday_day INTEGER,
        CHECK ((birthday_month IS NULL) = (birthday_day IS NULL))
      )
    ''');

    batch.execute(
      'CREATE INDEX idx_contacts_birthday ON contacts(birthday_month, birthday_day)',
    );

    batch.execute('''
      CREATE TABLE photos (
        id TEXT PRIMARY KEY,
        memory_id TEXT NOT NULL REFERENCES memories(id) ON DELETE CASCADE,
        kind TEXT NOT NULL CHECK (kind IN ('encrypted_local', 'cloud')),
        sandbox_path TEXT,
        remote_url TEXT,
        sha256 TEXT NOT NULL
      )
    ''');

    batch.execute('CREATE INDEX idx_photos_memory ON photos(memory_id)');

    batch.execute('''
      CREATE TABLE memory_contacts (
        memory_id TEXT NOT NULL REFERENCES memories(id) ON DELETE CASCADE,
        contact_id TEXT NOT NULL REFERENCES contacts(id) ON DELETE CASCADE,
        PRIMARY KEY (memory_id, contact_id)
      )
    ''');

    batch.execute(
      'CREATE INDEX idx_memory_contacts_contact ON memory_contacts(contact_id)',
    );

    batch.execute('''
      CREATE TABLE geofence_log (
        region_id TEXT NOT NULL,
        fired_at_utc_ms INTEGER NOT NULL,
        transition TEXT NOT NULL,
        PRIMARY KEY (region_id, fired_at_utc_ms)
      )
    ''');

    await batch.commit(noResult: true);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {}

  Future<void> close() async {
    final existing = _handle;
    if (existing != null && existing.isOpen) {
      await existing.close();
    }
    _handle = null;
  }
}
