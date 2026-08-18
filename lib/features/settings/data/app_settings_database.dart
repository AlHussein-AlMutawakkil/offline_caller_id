import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

class AppSettingsDatabase {
  static const _databaseName = 'app_settings.db';
  static const _tableName = 'app_settings';
  Database? _database;

  Future<Database> get database async {
    final current = _database;
    if (current != null && current.isOpen) return current;

    final directory = await getDatabasesPath();
    _database = await openDatabase(
      path.join(directory, _databaseName),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )
        ''');
      },
    );
    return _database!;
  }

  Future<String?> read(String key) async {
    final db = await database;
    final rows = await db.query(
      _tableName,
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['value']?.toString();
  }

  Future<void> write(String key, String value) async {
    final db = await database;
    await db.insert(
      _tableName,
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
