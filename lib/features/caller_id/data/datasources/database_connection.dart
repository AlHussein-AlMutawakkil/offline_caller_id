import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import '../../../../core/constants/database_constants.dart';
import '../../../../core/errors/database_unavailable_exception.dart';

class DatabaseConnection {
  Database? _database;

  Future<Database> get database async {
    final current = _database;
    if (current != null && current.isOpen) return current;

    final databasesPath = await getDatabasesPath();
    final databasePath = path.join(
      databasesPath,
      DatabaseConstants.databaseName,
    );

    final databaseFile = File(databasePath);
    final markerFile = File('$databasePath.ready');
    if (!await databaseFile.exists() || !await markerFile.exists()) {
      throw const DatabaseUnavailableException(
        'لا توجد قاعدة أرقام جاهزة. استورد ملف SQLite من إدارة قاعدة البيانات.',
      );
    }

    try {
      _database = await openDatabase(databasePath, readOnly: true);
    } catch (error) {
      throw DatabaseUnavailableException('تعذر فتح قاعدة الأرقام: $error');
    }

    return _database!;
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
