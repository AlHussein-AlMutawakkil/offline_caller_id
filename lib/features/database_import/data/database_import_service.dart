import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import '../../../core/constants/database_constants.dart';
import '../../../core/errors/database_import_exception.dart';

class DatabaseImportProgress {
  final int copiedBytes;
  final int totalBytes;
  final String message;

  const DatabaseImportProgress({
    required this.copiedBytes,
    required this.totalBytes,
    required this.message,
  });

  double get percentage => totalBytes == 0 ? 0 : copiedBytes / totalBytes;
}

class DatabaseImportService {
  final Future<void> Function() closeCurrentDatabase;

  const DatabaseImportService({required this.closeCurrentDatabase});

  Future<File?> pickDatabaseFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      withData: false,
    );

    final selectedPath = result?.files.single.path;
    if (selectedPath == null || selectedPath.isEmpty) return null;

    final fileName = path.basename(selectedPath).toLowerCase();
    final extension = path.extension(fileName);
    const supportedExtensions = {'.db', '.sqlite', '.sqlite3'};
    final isSupported = supportedExtensions.contains(extension) ||
        fileName.contains('contactsdb');

    if (!isSupported) {
      throw const DatabaseImportException(
        'اختر ملف SQLite بامتداد .db أو .sqlite أو .sqlite3.',
      );
    }

    return File(selectedPath);
  }

  Future<void> deleteImportedDatabase() async {
    await closeCurrentDatabase();
    final databaseDirectory = await getDatabasesPath();
    final fileNames = [
      DatabaseConstants.databaseName,
      '${DatabaseConstants.databaseName}.ready',
      '${DatabaseConstants.databaseName}.backup',
      '${DatabaseConstants.databaseName}.importing',
    ];
    for (final fileName in fileNames) {
      final file = File(path.join(databaseDirectory, fileName));
      if (await file.exists()) await file.delete();
    }
  }

  Future<bool> hasImportedDatabase() async {
    final databaseDirectory = await getDatabasesPath();
    final databaseFile = File(
      path.join(databaseDirectory, DatabaseConstants.databaseName),
    );
    final markerFile = File(
      path.join(
        databaseDirectory,
        '${DatabaseConstants.databaseName}.ready',
      ),
    );

    return await databaseFile.exists() && await markerFile.exists();
  }

  Stream<DatabaseImportProgress> importFile(File sourceFile) async* {
    if (!await sourceFile.exists()) {
      throw const DatabaseImportException('ملف قاعدة البيانات غير موجود.');
    }

    final sourceLength = await sourceFile.length();
    if (sourceLength == 0) {
      throw const DatabaseImportException('ملف قاعدة البيانات فارغ.');
    }

    final databasesDirectory = await getDatabasesPath();
    final temporaryPath = path.join(
      databasesDirectory,
      '${DatabaseConstants.databaseName}.importing',
    );
    final targetPath = path.join(
      databasesDirectory,
      DatabaseConstants.databaseName,
    );
    final backupPath = path.join(
      databasesDirectory,
      '${DatabaseConstants.databaseName}.backup',
    );
    final markerPath = path.join(
      databasesDirectory,
      '${DatabaseConstants.databaseName}.ready',
    );

    final temporaryFile = File(temporaryPath);
    final targetFile = File(targetPath);
    final backupFile = File(backupPath);
    final markerFile = File(markerPath);

    await temporaryFile.parent.create(recursive: true);
    if (await temporaryFile.exists()) await temporaryFile.delete();

    yield DatabaseImportProgress(
      copiedBytes: 0,
      totalBytes: sourceLength,
      message: 'جاري نسخ قاعدة البيانات...',
    );

    try {
      yield* _copyWithProgress(
        sourceFile: sourceFile,
        destinationFile: temporaryFile,
        totalBytes: sourceLength,
      );

      yield DatabaseImportProgress(
        copiedBytes: sourceLength,
        totalBytes: sourceLength,
        message: 'تم النسخ، جاري التحقق من القاعدة...',
      );

      await _validateDatabase(temporaryPath);
      await closeCurrentDatabase();

      if (await backupFile.exists()) await backupFile.delete();
      if (await targetFile.exists()) await targetFile.rename(backupPath);
      await temporaryFile.rename(targetPath);
      await markerFile.writeAsString(DateTime.now().toIso8601String());

      yield DatabaseImportProgress(
        copiedBytes: sourceLength,
        totalBytes: sourceLength,
        message: 'تم استيراد قاعدة البيانات بنجاح.',
      );
    } catch (error) {
      if (await temporaryFile.exists()) await temporaryFile.delete();
      throw DatabaseImportException('فشل استيراد قاعدة البيانات: $error');
    }
  }

  Stream<DatabaseImportProgress> _copyWithProgress({
    required File sourceFile,
    required File destinationFile,
    required int totalBytes,
  }) async* {
    final input = await sourceFile.open();
    final output = await destinationFile.open(mode: FileMode.write);
    var copiedBytes = 0;
    var lastUpdate = DateTime.now().millisecondsSinceEpoch;
    const maxChunkSize = 5 * 1024 * 1024;

    try {
      while (copiedBytes < totalBytes) {
        final remaining = totalBytes - copiedBytes;
        final chunkSize = remaining < maxChunkSize ? remaining : maxChunkSize;
        final chunk = await input.read(chunkSize);
        if (chunk.isEmpty) break;

        await output.writeFrom(chunk);
        copiedBytes += chunk.length;

        final now = DateTime.now().millisecondsSinceEpoch;
        if (now - lastUpdate >= 250 || copiedBytes == totalBytes) {
          lastUpdate = now;
          yield DatabaseImportProgress(
            copiedBytes: copiedBytes,
            totalBytes: totalBytes,
            message: 'جاري نسخ قاعدة البيانات...',
          );
        }
      }
    } finally {
      await input.close();
      await output.close();
    }
  }

  Future<void> _validateDatabase(String databasePath) async {
    Database? database;
    try {
      database = await openDatabase(databasePath, readOnly: true);
      final tables = await database.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
        [DatabaseConstants.tableName],
      );
      if (tables.isEmpty) {
        throw const DatabaseImportException(
          'القاعدة لا تحتوي على جدول الأرقام المطلوب.',
        );
      }

      final columns = await database.rawQuery(
        'PRAGMA table_info(${DatabaseConstants.tableName})',
      );
      final names = columns
          .map((column) => column['name']?.toString())
          .whereType<String>()
          .toSet();
      final required = {
        DatabaseConstants.phoneColumn,
        DatabaseConstants.namesColumn,
      };
      if (!required.every(names.contains)) {
        throw const DatabaseImportException(
          'مخطط قاعدة البيانات غير متوافق مع التطبيق.',
        );
      }
    } finally {
      await database?.close();
    }
  }
}
