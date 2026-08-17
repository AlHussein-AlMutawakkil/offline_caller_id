import 'package:sqflite/sqflite.dart';

import '../../../../core/constants/database_constants.dart';

class CallerDatabaseDataSource {
  final Database database;

  const CallerDatabaseDataSource(this.database);

  Future<List<Map<String, Object?>>> searchByNumber(String number) {
    return database.query(
      DatabaseConstants.tableName,
      where: '${DatabaseConstants.phoneColumn} LIKE ?',
      whereArgs: ['$number%'],
      limit: DatabaseConstants.maxSearchResults,
    );
  }

  Future<List<Map<String, Object?>>> searchByName(
    String name, {
    String? companyPrefix,
  }) {
    var where = '${DatabaseConstants.namesColumn} LIKE ?';
    final args = <Object?>['$name%'];

    if (companyPrefix != null && companyPrefix.isNotEmpty) {
      where += ' AND ${DatabaseConstants.phoneColumn} LIKE ?';
      args.add('$companyPrefix%');
    }

    return database.query(
      DatabaseConstants.tableName,
      where: where,
      whereArgs: args,
      limit: DatabaseConstants.maxSearchResults,
    );
  }

  Future<int> countRecords() async {
    final result = await database.rawQuery(
      'SELECT COUNT(*) AS count FROM ${DatabaseConstants.tableName}',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
