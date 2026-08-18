import 'dart:io';

import 'package:flutter/material.dart';

import '../database_import_controller.dart';

class DatabaseImportCard extends StatelessWidget {
  final DatabaseImportController controller;
  final VoidCallback onImported;

  const DatabaseImportCard({
    required this.controller,
    required this.onImported,
    super.key,
  });

  Future<void> _import() async {
    final imported = await controller.selectAndImport();
    if (imported) onImported();
  }

  @override
  Widget build(BuildContext context) {
    final selectedFile = controller.selectedFile;
    final progress = controller.progress?.percentage;

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'عدد السجلات الحالية: يحتاج إلى قاعدة',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(controller.statusMessage),
            if (selectedFile != null) ...[
              Text(
                'الملف: ${selectedFile.path.split(Platform.pathSeparator).last}',
              ),
              Text('الحجم: ${controller.formatSize(controller.selectedFileSize)}'),
            ],
            if (progress != null && controller.isImporting) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(value: progress),
              const SizedBox(height: 4),
              Text('${(progress * 100).toStringAsFixed(0)}%'),
            ],
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: controller.isImporting ? null : _import,
              icon: const Icon(Icons.folder_open),
              label: Text(
                controller.isImporting
                    ? 'جاري الاستيراد...'
                    : 'اختيار قاعدة البيانات',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
