import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import '../../../../core/constants/database_constants.dart';

class DatabaseConnection {
  Database? _database;

  Future<Database> get database async {
    final current = _database;
    if (current != null && current.isOpen) {
      return current;
    }

    final databasesPath = await getDatabasesPath();
    final databasePath = path.join(
      databasesPath,
      DatabaseConstants.databaseName,
    );

    _database = await openDatabase(
      databasePath,
      version: DatabaseConstants.databaseVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS ${DatabaseConstants.tableName} (
            ${DatabaseConstants.idColumn} INTEGER PRIMARY KEY AUTOINCREMENT,
            ${DatabaseConstants.phoneColumn} TEXT NOT NULL,
            ${DatabaseConstants.namesColumn} TEXT NOT NULL,
            ${DatabaseConstants.companyColumn} TEXT
          )
        ''');
      },
    );

    return _database!;
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
