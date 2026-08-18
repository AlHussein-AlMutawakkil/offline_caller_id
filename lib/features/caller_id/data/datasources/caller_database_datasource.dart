import 'package:sqflite/sqflite.dart';

import '../../../../core/constants/database_constants.dart';
import '../../../../core/utils/phone_normalizer.dart';

class CallerDatabaseDataSource {
  final Database database;

  const CallerDatabaseDataSource(this.database);

  Future<List<Map<String, Object?>>> searchByNumber(String number) {
    final normalized = PhoneNormalizer.normalize(number);
    if (normalized.isEmpty) return Future.value(const []);

    return database.query(
      DatabaseConstants.tableName,
      where: '${DatabaseConstants.phoneColumn} LIKE ?',
      whereArgs: ['$normalized%'],
      limit: DatabaseConstants.maxSearchResults,
    );
  }

  Future<List<Map<String, Object?>>> searchByName(
    String name, {
    String? companyPrefix,
  }) {
    final normalizedName = name.trim();
    if (normalizedName.isEmpty) return Future.value(const []);

    var where = '${DatabaseConstants.namesColumn} LIKE ?';
    final args = <Object?>['$normalizedName%'];

    final normalizedPrefix = companyPrefix == null
        ? ''
        : PhoneNormalizer.normalize(companyPrefix);
    if (normalizedPrefix.isNotEmpty) {
      where += ' AND ${DatabaseConstants.phoneColumn} LIKE ?';
      args.add('$normalizedPrefix%');
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
