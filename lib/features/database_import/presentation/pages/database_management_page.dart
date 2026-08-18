import 'package:flutter/material.dart';

import '../database_import_controller.dart';

class DatabaseManagementPage extends StatelessWidget {
  final DatabaseImportController controller;
  final int totalRecords;
  final VoidCallback onDatabaseChanged;

  const DatabaseManagementPage({
    required this.controller,
    required this.totalRecords,
    required this.onDatabaseChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إدارة قاعدة البيانات')),
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final progress = controller.progress?.percentage;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _StatusCard(
                isReady: controller.hasImportedDatabase,
                totalRecords: totalRecords,
                statusMessage: controller.statusMessage,
                selectedFileName: controller.selectedFile?.path.split('/').last,
                selectedFileSize: controller.formatSize(
                  controller.selectedFileSize,
                ),
              ),
              if (progress != null && controller.isImporting) ...[
                const SizedBox(height: 12),
                LinearProgressIndicator(value: progress),
                const SizedBox(height: 6),
                Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: controller.isImporting
                    ? null
                    : () async {
                        final imported = await controller.selectAndImport();
                        if (imported) onDatabaseChanged();
                      },
                icon: const Icon(Icons.add_to_photos_outlined),
                label: Text(
                  controller.isImporting
                      ? 'جاري استيراد قاعدة البيانات...'
                      : 'إضافة أو استبدال قاعدة بيانات',
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: controller.isImporting ||
                        !controller.hasImportedDatabase
                    ? null
                    : () async {
                        await controller.deleteImportedDatabase();
                        onDatabaseChanged();
                      },
                icon: const Icon(Icons.delete_outline),
                label: const Text('حذف قاعدة الأرقام الحالية'),
              ),
              const SizedBox(height: 24),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'يمكنك اختيار ملف SQLite مباشر بامتداد .db أو .sqlite أو .sqlite3. أثناء الاستيراد يتم تعطيل الزر لمنع بدء عمليتين متزامنتين.',
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final bool isReady;
  final int totalRecords;
  final String statusMessage;
  final String? selectedFileName;
  final String selectedFileSize;

  const _StatusCard({
    required this.isReady,
    required this.totalRecords,
    required this.statusMessage,
    required this.selectedFileName,
    required this.selectedFileSize,
  });

  @override
  Widget build(BuildContext context) {
    final color = isReady
        ? Theme.of(context).colorScheme.primaryContainer
        : Theme.of(context).colorScheme.surface;
    return Card(
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isReady ? 'قاعدة البيانات جاهزة' : 'لا توجد قاعدة مستوردة',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text('عدد السجلات: $totalRecords'),
            Text(statusMessage),
            if (selectedFileName != null) ...[
              const SizedBox(height: 4),
              Text('الملف: $selectedFileName — $selectedFileSize'),
            ],
          ],
        ),
      ),
    );
  }
}
