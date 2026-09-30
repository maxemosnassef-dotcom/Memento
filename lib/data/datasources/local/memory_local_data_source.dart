import 'package:sqflite_sqlcipher/sqflite.dart';

import '../../models/rows.dart';
import 'memento_database.dart';

class MemoryLocalDataSource {
  static const String _table = 'memories';
  static const String _geoTable = 'memory_geo';

  final MementoDatabase _database;

  const MemoryLocalDataSource(this._database);

  Future<MemoryRow?> byId(String id) async {
    final db = await _database.instance;
    final rows = await db.query(
      _table,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _hydrate(rows.first);
  }

  Future<List<MemoryRow>> between(int startUtcMs, int endUtcMs) async {
    final db = await _database.instance;
    final rows = await db.query(
      _table,
      where: 'moment_utc_ms >= ? AND moment_utc_ms < ?',
      whereArgs: [startUtcMs, endUtcMs],
      orderBy: 'moment_utc_ms DESC',
    );
    return _hydrateAll(rows);
  }

  Future<List<MemoryRow>> onCalendarDay({required int month, required int day}) async {
    final db = await _database.instance;
    final rows = await db.query(
      _table,
      where: 'mem_month = ? AND mem_day = ?',
      whereArgs: [month, day],
      orderBy: 'moment_utc_ms DESC',
    );
    return _hydrateAll(rows);
  }

  Future<List<MemoryRow>> withinBoundingBox({
    required double minLat,
    required double maxLat,
    required double minLng,
    required double maxLng,
  }) async {
    final db = await _database.instance;
    final rows = await db.rawQuery('''
      SELECT m.*
      FROM memories m
      INNER JOIN memory_geo g ON g.seq = m.seq
      WHERE g.min_lat <= ? AND g.max_lat >= ?
        AND g.min_lng <= ? AND g.max_lng >= ?
      ORDER BY m.moment_utc_ms DESC
    ''', [maxLat, minLat, maxLng, minLng]);
    return _hydrateAll(rows);
  }

  Future<List<MemoryRow>> taggedWith(Set<String> contactIds) async {
    if (contactIds.isEmpty) return const [];
    final db = await _database.instance;
    final placeholders = List.filled(contactIds.length, '?').join(', ');
    final rows = await db.rawQuery('''
      SELECT DISTINCT m.*
      FROM memories m
      INNER JOIN memory_contacts mc ON mc.memory_id = m.id
      WHERE mc.contact_id IN ($placeholders)
      ORDER BY m.moment_utc_ms DESC
    ''', contactIds.toList());
    return _hydrateAll(rows);
  }

  Future<List<MemoryRow>> geoAnchored({required int limit}) async {
    final db = await _database.instance;
    final rows = await db.query(
      _table,
      where: 'latitude IS NOT NULL AND longitude IS NOT NULL',
      orderBy: 'moment_utc_ms DESC',
      limit: limit,
    );
    return _hydrateAll(rows);
  }

  Future<void> upsert(MemoryRow row) async {
    final db = await _database.instance;
    await db.transaction((txn) async {
      final existing = await txn.query(
        _table,
        columns: ['seq'],
        where: 'id = ?',
        whereArgs: [row.id],
        limit: 1,
      );

      int seq;
      if (existing.isEmpty) {
        final insertedSeq =
            await txn.insert(_table, row.toColumns());
        seq = insertedSeq;
      } else {
        seq = existing.first['seq']! as int;
        await txn.update(
          _table,
          row.toColumns(),
          where: 'seq = ?',
          whereArgs: [seq],
        );
      }

      await txn.delete(_geoTable, where: 'seq = ?', whereArgs: [seq]);
      if (row.isGeoAnchored) {
        await txn.insert(_geoTable, {
          'seq': seq,
          'min_lat': row.latitude!,
          'max_lat': row.latitude!,
          'min_lng': row.longitude!,
          'max_lng': row.longitude!,
        });
      }

      await txn.delete(
        'photos',
        where: 'memory_id = ?',
        whereArgs: [row.id],
      );
      for (final photo in row.photos) {
        await txn.insert('photos', photo.toColumns(),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }

      await txn.delete(
        'memory_contacts',
        where: 'memory_id = ?',
        whereArgs: [row.id],
      );
      for (final contactId in row.contactIds) {
        await txn.insert(
          'memory_contacts',
          {'memory_id': row.id, 'contact_id': contactId},
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
    });
  }

  Future<void> delete(String id) async {
    final db = await _database.instance;
    await db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  Future<MemoryRow> _hydrate(Map<String, Object?> base) async {
    final db = await _database.instance;
    final memoryId = base['id']! as String;

    final photoRows = await db.query(
      'photos',
      where: 'memory_id = ?',
      whereArgs: [memoryId],
    );
    final linkRows = await db.query(
      'memory_contacts',
      columns: ['contact_id'],
      where: 'memory_id = ?',
      whereArgs: [memoryId],
    );

    final row = MemoryRow.fromMap(base);
    return row.copyWith(
      photos: photoRows.map(PhotoRow.fromMap).toList(growable: false),
      contactIds:
          linkRows.map((r) => r['contact_id']! as String).toList(growable: false),
    );
  }

  Future<List<MemoryRow>> _hydrateAll(List<Map<String, Object?>> bases) async =>
      [for (final base in bases) await _hydrate(base)];
}
