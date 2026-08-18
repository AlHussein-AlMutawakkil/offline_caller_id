import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/constants/database_constants.dart';
import '../../../core/errors/database_import_exception.dart';

class DatabaseImportProgress {
  final int copiedBytes;
  final int totalBytes;
  final String message;
  final double? progressOverride;

  const DatabaseImportProgress({
    required this.copiedBytes,
    required this.totalBytes,
    required this.message,
    this.progressOverride,
  });

  double get percentage {
    final value = progressOverride ??
        (totalBytes == 0 ? 0 : copiedBytes / totalBytes);
    return value.clamp(0.0, 1.0).toDouble();
  }
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

  /// ينظف النسخة التي قد ينشئها file_picker في Cache على Android.
  /// يستدعى فقط بعد انتهاء استخدام الملف المختار بالكامل.
  Future<void> clearPickerTemporaryFiles(File? selectedFile) async {
    try {
      await FilePicker.platform.clearTemporaryFiles();
    } catch (_) {
      // تنظيف Cache لا يجب أن يحول استيرادًا ناجحًا إلى فشل.
    }

    // بعض أجهزة Android تبقي الملف المنسوخ في Cache رغم استدعاء الإضافة.
    // نحذف فقط المسار الواقع داخل Cache التطبيق، وليس الملف الأصلي المختار.
    if (selectedFile == null || !await selectedFile.exists()) return;
    try {
      final cacheDirectory = await getTemporaryDirectory();
      final isCachedCopy = path.isWithin(
        cacheDirectory.path,
        selectedFile.path,
      );
      if (isCachedCopy) await selectedFile.delete();
    } catch (_) {
      // لا نؤثر في نتيجة الاستيراد إن تعذر تنظيف Cache.
    }
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

  /// يستعيد آخر قاعدة سليمة عند توقف التطبيق وسط عملية الاستبدال.
  Future<void> recoverInterruptedImport() async {
    final directory = await getDatabasesPath();
    final targetFile = File(path.join(directory, DatabaseConstants.databaseName));
    final markerFile = File('${targetFile.path}.ready');
    final backupFile = File('${targetFile.path}.backup');
    final temporaryFile = File('${targetFile.path}.importing');

    if (await temporaryFile.exists()) await temporaryFile.delete();

    if (!await targetFile.exists() && await backupFile.exists()) {
      await backupFile.rename(targetFile.path);
    }

    if (!await targetFile.exists()) {
      if (await markerFile.exists()) await markerFile.delete();
      return;
    }

    try {
      await _validateDatabase(targetFile.path);
      if (!await markerFile.exists()) {
        await markerFile.writeAsString(DateTime.now().toIso8601String());
      }
      if (await backupFile.exists()) await backupFile.delete();
    } catch (_) {
      if (await backupFile.exists()) {
        await targetFile.delete();
        await backupFile.rename(targetFile.path);
        await markerFile.writeAsString(DateTime.now().toIso8601String());
      } else if (await markerFile.exists()) {
        await markerFile.delete();
      }
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
      progressOverride: 0,
    );

    var stage = 'نسخ الملف إلى مساحة التطبيق';
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
        progressOverride: 0.84,
      );
      await Future<void>.delayed(const Duration(milliseconds: 16));

      stage = 'التحقق من مخطط قاعدة البيانات';
      yield DatabaseImportProgress(
        copiedBytes: sourceLength,
        totalBytes: sourceLength,
        message: 'جاري التحقق من مخطط قاعدة البيانات...',
        progressOverride: 0.88,
      );
      await Future<void>.delayed(const Duration(milliseconds: 16));
      await _validateDatabase(temporaryPath);
      stage = 'تثبيت قاعدة البيانات';
      yield DatabaseImportProgress(
        copiedBytes: sourceLength,
        totalBytes: sourceLength,
        message: 'تم التحقق، جاري تثبيت القاعدة داخل بيانات التطبيق...',
        progressOverride: 0.94,
      );
      await closeCurrentDatabase();

      if (await backupFile.exists()) await backupFile.delete();
      var originalMovedToBackup = false;
      try {
        if (await targetFile.exists()) {
          await targetFile.rename(backupPath);
          originalMovedToBackup = true;
        }
        if (await markerFile.exists()) await markerFile.delete();
        await temporaryFile.rename(targetPath);
        await markerFile.writeAsString(DateTime.now().toIso8601String());
        if (await backupFile.exists()) await backupFile.delete();
      } catch (error) {
        if (await targetFile.exists() && originalMovedToBackup) {
          await targetFile.delete();
        }
        if (originalMovedToBackup && await backupFile.exists()) {
          await backupFile.rename(targetPath);
          await markerFile.writeAsString(DateTime.now().toIso8601String());
        }
        rethrow;
      }

      yield DatabaseImportProgress(
        copiedBytes: sourceLength,
        totalBytes: sourceLength,
        message: 'تم استيراد قاعدة البيانات بنجاح.',
        progressOverride: 1,
      );
    } catch (error) {
      if (await temporaryFile.exists()) await temporaryFile.delete();
      throw DatabaseImportException(
        'فشل الاستيراد في مرحلة «$stage»: $error',
      );
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
            progressOverride: 0.8 * copiedBytes / totalBytes,
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
      await _validateSchema(database);
    } finally {
      await database?.close();
    }
  }

  Future<void> _validateSchema(Database database) async {
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
  }
}
