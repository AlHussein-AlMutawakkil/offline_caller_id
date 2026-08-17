import 'dart:io';

import 'package:flutter/material.dart';

import '../../../database_import/data/database_import_service.dart';
import '../../../database_import/presentation/database_import_controller.dart';
import '../../../caller_id/data/datasources/database_connection.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final DatabaseConnection _databaseConnection;
  late final DatabaseImportController _importController;

  File? _selectedFile;
  int? _selectedFileSize;
  String _statusMessage = 'لم يتم استيراد قاعدة بيانات بعد';

  @override
  void initState() {
    super.initState();
    _databaseConnection = DatabaseConnection();
    _importController = DatabaseImportController(
      DatabaseImportService(
        closeCurrentDatabase: _databaseConnection.close,
      ),
    );
  }

  @override
  void dispose() {
    _databaseConnection.close();
    super.dispose();
  }

  Future<void> _selectAndImportDatabase() async {
    if (_importController.isImporting) return;

    final file = await _importController.pickFile();
    if (file == null) return;

    final fileSize = await file.length();
    if (!mounted) return;

    setState(() {
      _selectedFile = file;
      _selectedFileSize = fileSize;
      _statusMessage = 'جاري تجهيز الاستيراد...';
    });

    try {
      await for (final update in _importController.importFile(file)) {
        if (!mounted) return;
        setState(() {
          _statusMessage = update.message;
        });
      }

      if (!mounted) return;
      setState(() {
        _statusMessage = 'تم استيراد قاعدة البيانات بنجاح';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _statusMessage = error.toString();
      });
    }
  }

  String _formatSize(int? bytes) {
    if (bytes == null) return '-';
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final progress = _importController.progress?.percentage;
    final isImporting = _importController.isImporting;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('كاشف الأرقام أوف لاين'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'قاعدة بيانات الأرقام',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(_statusMessage),
                      if (_selectedFile != null) ...[
                        const SizedBox(height: 8),
                        Text('الملف: ${_selectedFile!.path.split(Platform.pathSeparator).last}'),
                        Text('الحجم: ${_formatSize(_selectedFileSize)}'),
                      ],
                      if (progress != null && isImporting) ...[
                        const SizedBox(height: 16),
                        LinearProgressIndicator(value: progress),
                        const SizedBox(height: 6),
                        Text('${(progress * 100).toStringAsFixed(0)}%'),
                      ],
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: isImporting ? null : _selectAndImportDatabase,
                        icon: const Icon(Icons.folder_open),
                        label: Text(
                          isImporting ? 'جاري الاستيراد...' : 'اختيار قاعدة البيانات',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
