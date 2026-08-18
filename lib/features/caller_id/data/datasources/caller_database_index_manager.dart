import 'package:sqflite/sqflite.dart';

import '../../../../core/constants/database_constants.dart';

/// أسلوب البيانات: تجهيز الفهارس مرة واحدة أثناء الاستيراد، لا عند كل تشغيل.
abstract final class CallerDatabaseIndexManager {
  static Future<void> ensureSearchIndexes(Database database) async {
    await database.execute('''
      CREATE INDEX IF NOT EXISTS idx_${DatabaseConstants.tableName}_phone
      ON ${DatabaseConstants.tableName} (${DatabaseConstants.phoneColumn})
    ''');
    await database.execute('''
      CREATE INDEX IF NOT EXISTS idx_${DatabaseConstants.tableName}_names
      ON ${DatabaseConstants.tableName} (${DatabaseConstants.namesColumn})
    ''');
  }
}
