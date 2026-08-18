import 'package:sqflite/sqflite.dart';

import '../../../../core/constants/database_constants.dart';
import '../../../../core/utils/phone_normalizer.dart';
import 'database_connection.dart';

class CallerDatabaseDataSource {
  final Future<Database> Function() _getDatabase;

  /// يستخدم في الخدمات التي تملك اتصالها المستقل.
  CallerDatabaseDataSource(Database database)
      : _getDatabase = (() async => database);

  /// يستخدم في واجهة البحث؛ يعيد فتح الاتصال إذا أُغلق أثناء الاستيراد.
  CallerDatabaseDataSource.fromConnection(DatabaseConnection connection)
      : _getDatabase = (() => connection.database);

  Future<List<Map<String, Object?>>> searchByNumber(String number) async {
    final normalized = PhoneNormalizer.normalize(number);
    if (normalized.isEmpty) return Future.value(const []);

    return _withOpenDatabase(
      (database) => database.query(
        DatabaseConstants.tableName,
        where: '${DatabaseConstants.phoneColumn} LIKE ?',
        whereArgs: ['$normalized%'],
        limit: DatabaseConstants.maxSearchResults,
      ),
    );
  }

  Future<List<Map<String, Object?>>> searchByName(
    String name, {
    String? companyPrefix,
  }) async {
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

    return _withOpenDatabase(
      (database) => database.query(
        DatabaseConstants.tableName,
        where: where,
        whereArgs: args,
        limit: DatabaseConstants.maxSearchResults,
      ),
    );
  }

  Future<int> countRecords() async {
    return _withOpenDatabase((database) async {
      try {
        final result = await database.rawQuery(
          'SELECT IFNULL(MAX(rowid), 0) AS count '
          'FROM ${DatabaseConstants.tableName}',
        );
        return Sqflite.firstIntValue(result) ?? 0;
      } on DatabaseException {
        // قواعد SQLite من نوع WITHOUT ROWID نادرة هنا؛ نستخدم العد الكامل كـ fallback.
        final result = await database.rawQuery(
          'SELECT COUNT(*) AS count FROM ${DatabaseConstants.tableName}',
        );
        return Sqflite.firstIntValue(result) ?? 0;
      }
    });
  }

  Future<T> _withOpenDatabase<T>(Future<T> Function(Database) operation) async {
    try {
      return await operation(await _getDatabase());
    } on DatabaseException catch (error) {
      if (!error.toString().contains('database_closed')) rethrow;
      return operation(await _getDatabase());
    }
  }
}
