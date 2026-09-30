import 'package:sqflite_sqlcipher/sqflite.dart';

import '../../models/rows.dart';
import 'memento_database.dart';

class ContactLocalDataSource {
  static const String _table = 'contacts';

  final MementoDatabase _database;

  const ContactLocalDataSource(this._database);

  Future<ContactRow?> byId(String id) async {
    final db = await _database.instance;
    final rows = await db.query(
      _table,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return ContactRow.fromMap(rows.first);
  }

  Future<List<ContactRow>> all() async {
    final db = await _database.instance;
    final rows = await db.query(
      _table,
      orderBy: 'display_name COLLATE NOCASE ASC',
    );
    return rows.map(ContactRow.fromMap).toList(growable: false);
  }

  Future<List<ContactRow>> birthdaysOn({
    required int month,
    required int day,
  }) async {
    final db = await _database.instance;
    final rows = await db.query(
      _table,
      where: 'birthday_month = ? AND birthday_day = ?',
      whereArgs: [month, day],
      orderBy: 'display_name COLLATE NOCASE ASC',
    );
    return rows.map(ContactRow.fromMap).toList(growable: false);
  }

  Future<void> upsert(ContactRow row) async {
    final db = await _database.instance;
    await db.insert(
      _table,
      row.toColumns(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
