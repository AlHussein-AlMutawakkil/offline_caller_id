import 'dart:io';

import 'package:flutter/foundation.dart';

import '../data/database_import_service.dart';

class DatabaseImportController extends ChangeNotifier {
  final DatabaseImportService service;

  DatabaseImportProgress? progress;
  File? selectedFile;
  int? selectedFileSize;
  String statusMessage = 'لم يتم استيراد قاعدة بيانات بعد';
  bool hasImportedDatabase = false;
  bool isImporting = false;

  DatabaseImportController(this.service);

  Future<void> initialize() async {
    try {
      hasImportedDatabase = await service.hasImportedDatabase();
      if (hasImportedDatabase) statusMessage = 'قاعدة البيانات جاهزة';
    } catch (_) {
      hasImportedDatabase = false;
    }
    notifyListeners();
  }

  Future<void> deleteImportedDatabase() async {
    if (isImporting) return;
    await service.deleteImportedDatabase();
    selectedFile = null;
    selectedFileSize = null;
    progress = null;
    hasImportedDatabase = false;
    statusMessage = 'لم يتم استيراد قاعدة بيانات بعد';
    notifyListeners();
  }

  Future<bool> selectAndImport() async {
    if (isImporting) return false;

    isImporting = true;
    statusMessage = 'جاري فتح مدير الملفات...';
    notifyListeners();

    try {
      final file = await service.pickDatabaseFile();
      if (file == null) {
        statusMessage = 'تم إلغاء اختيار الملف';
        return false;
      }

      selectedFile = file;
      selectedFileSize = await file.length();
      statusMessage = 'جاري بدء نسخ قاعدة البيانات...';
      notifyListeners();

      await for (final update in service.importFile(file)) {
        progress = update;
        statusMessage = update.message;
        notifyListeners();
      }

      hasImportedDatabase = true;
      statusMessage = 'قاعدة البيانات جاهزة';
      return true;
    } catch (error) {
      statusMessage = error.toString();
      return false;
    } finally {
      isImporting = false;
      notifyListeners();
    }
  }

  String formatSize(int? bytes) {
    if (bytes == null) return '-';
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}
