import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import '../models/telecom_company.dart';

class TelecomCompaniesDatabase {
  static const databaseName = 'telecom_companies.db';
  static const tableName = 'telecom_companies';

  Database? _database;

  Future<Database> get database async {
    final current = _database;
    if (current != null && current.isOpen) return current;

    final directory = await getDatabasesPath();
    _database = await openDatabase(
      path.join(directory, databaseName),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $tableName (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL UNIQUE,
            prefix TEXT NOT NULL,
            is_active INTEGER NOT NULL DEFAULT 1,
            sort_order INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await _seedDefaults(db);
      },
    );
    return _database!;
  }

  Future<void> _seedDefaults(Database db) async {
    const defaults = [
      TelecomCompany(name: 'يمن موبايل', prefix: '77', sortOrder: 1),
      TelecomCompany(name: 'سبأفون', prefix: '71', sortOrder: 2),
      TelecomCompany(name: 'يو', prefix: '73', sortOrder: 3),
      TelecomCompany(name: 'واي', prefix: '70', sortOrder: 4),
    ];
    for (final company in defaults) {
      await db.insert(tableName, company.toMap());
    }
  }

  Future<List<TelecomCompany>> getAll() async {
    final db = await database;
    final rows = await db.query(tableName, orderBy: 'sort_order ASC, name ASC');
    return rows.map(TelecomCompany.fromMap).toList();
  }

  Future<List<TelecomCompany>> getActive() async {
    final db = await database;
    final rows = await db.query(
      tableName,
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'sort_order ASC, name ASC',
    );
    return rows.map(TelecomCompany.fromMap).toList();
  }

  Future<int> insert(TelecomCompany company) async {
    final db = await database;
    return db.insert(tableName, company.toMap());
  }

  Future<int> update(TelecomCompany company) async {
    final db = await database;
    return db.update(
      tableName,
      company.toMap(),
      where: 'id = ?',
      whereArgs: [company.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await database;
    return db.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
