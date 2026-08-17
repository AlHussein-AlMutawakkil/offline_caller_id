import 'dart:io';

import 'package:flutter/material.dart';

import '../../../database_import/data/database_import_service.dart';
import '../../../database_import/presentation/database_import_controller.dart';
import '../../data/datasources/caller_database_datasource.dart';
import '../../data/datasources/database_connection.dart';
import '../controllers/caller_id_controller.dart';
import 'name_search_page.dart';
import 'number_search_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late final DatabaseConnection _databaseConnection;
  late final DatabaseImportController _importController;
  late Future<CallerIdController> _callerControllerFuture;

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
    _callerControllerFuture = _createCallerController();
  }

  Future<CallerIdController> _createCallerController() async {
    final database = await _databaseConnection.database;
    final controller = CallerIdController.fromDataSource(
      CallerDatabaseDataSource(database),
    );
    await controller.loadCount();
    return controller;
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
        setState(() => _statusMessage = update.message);
      }

      if (!mounted) return;
      setState(() {
        _statusMessage = 'تم استيراد قاعدة البيانات بنجاح';
        _callerControllerFuture = _createCallerController();
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _statusMessage = error.toString());
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
    return Directionality(
      textDirection: TextDirection.rtl,
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('كاشف الأرقام أوف لاين'),
            bottom: const TabBar(
              tabs: [
                Tab(text: 'بحث بالاسم', icon: Icon(Icons.person_search)),
                Tab(text: 'بحث بالرقم', icon: Icon(Icons.dialpad)),
              ],
            ),
          ),
          body: FutureBuilder<CallerIdController>(
            future: _callerControllerFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final controller = snapshot.data!;
              return Column(
                children: [
                  _ImportCard(
                    statusMessage: _statusMessage,
                    selectedFile: _selectedFile,
                    selectedFileSize: _selectedFileSize,
                    progress: _importController.progress?.percentage,
                    isImporting: _importController.isImporting,
                    totalRecords: controller.totalRecords,
                    onImport: _selectAndImportDatabase,
                    formatSize: _formatSize,
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        NameSearchPage(controller: controller),
                        NumberSearchPage(controller: controller),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ImportCard extends StatelessWidget {
  final String statusMessage;
  final File? selectedFile;
  final int? selectedFileSize;
  final double? progress;
  final bool isImporting;
  final int totalRecords;
  final VoidCallback onImport;
  final String Function(int?) formatSize;

  const _ImportCard({
    required this.statusMessage,
    required this.selectedFile,
    required this.selectedFileSize,
    required this.progress,
    required this.isImporting,
    required this.totalRecords,
    required this.onImport,
    required this.formatSize,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'عدد السجلات: $totalRecords',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(statusMessage),
            if (selectedFile != null) ...[
              Text('الملف: ${selectedFile!.path.split(Platform.pathSeparator).last}'),
              Text('الحجم: ${formatSize(selectedFileSize)}'),
            ],
            if (progress != null && isImporting) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(value: progress),
              const SizedBox(height: 4),
              Text('${(progress! * 100).toStringAsFixed(0)}%'),
            ],
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: isImporting ? null : onImport,
              icon: const Icon(Icons.folder_open),
              label: Text(
                isImporting ? 'جاري الاستيراد...' : 'اختيار قاعدة البيانات',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
