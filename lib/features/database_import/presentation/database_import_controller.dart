import 'dart:io';

import '../data/database_import_service.dart';

class DatabaseImportController {
  final DatabaseImportService service;

  DatabaseImportProgress? progress;
  bool isImporting = false;
  String? selectedFileName;
  String? errorMessage;

  DatabaseImportController(this.service);

  Future<File?> pickFile() {
    return service.pickDatabaseFile();
  }

  Stream<DatabaseImportProgress> importFile(File file) async* {
    isImporting = true;
    errorMessage = null;
    selectedFileName = file.path.split(Platform.pathSeparator).last;

    try {
      await for (final update in service.importFile(file)) {
        progress = update;
        yield update;
      }
    } catch (error) {
      errorMessage = error.toString();
      rethrow;
    } finally {
      isImporting = false;
    }
  }
}
