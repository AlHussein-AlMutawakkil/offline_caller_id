import 'package:flutter/material.dart';

import '../database_import_controller.dart';

class DatabaseManagementPage extends StatefulWidget {
  final DatabaseImportController controller;
  final int totalRecords;
  final Future<int> Function() onDatabaseChanged;

  const DatabaseManagementPage({
    required this.controller,
    required this.totalRecords,
    required this.onDatabaseChanged,
    super.key,
  });

  @override
  State<DatabaseManagementPage> createState() => _DatabaseManagementPageState();
}

class _DatabaseManagementPageState extends State<DatabaseManagementPage> {
  late int _totalRecords;

  @override
  void initState() {
    super.initState();
    _totalRecords = widget.totalRecords;
  }

  Future<void> _afterImport() async {
    final count = await widget.onDatabaseChanged();
    if (mounted) setState(() => _totalRecords = count);
  }

  Future<void> _afterDelete() async {
    try {
      await widget.onDatabaseChanged();
    } catch (_) {
      // بعد الحذف لا توجد قاعدة لفتحها؛ نعرض الصفر بدل رسالة خطأ.
    }
    if (mounted) setState(() => _totalRecords = 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إدارة قاعدة البيانات')),
      body: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) {
          final progress = widget.controller.progress?.percentage;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _StatusCard(
                isReady: widget.controller.hasImportedDatabase,
                totalRecords: _totalRecords,
                statusMessage: widget.controller.statusMessage,
                selectedFileName:
                    widget.controller.selectedFile?.path.split('/').last,
                selectedFileSize: widget.controller.formatSize(
                  widget.controller.selectedFileSize,
                ),
              ),
              if (progress != null && widget.controller.isImporting) ...[
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
                onPressed: widget.controller.isImporting
                    ? null
                    : () async {
                        final imported =
                            await widget.controller.selectAndImport();
                        if (imported) await _afterImport();
                      },
                icon: const Icon(Icons.add_to_photos_outlined),
                label: Text(
                  widget.controller.isImporting
                      ? 'جاري استيراد قاعدة البيانات...'
                      : 'إضافة أو استبدال قاعدة بيانات',
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: widget.controller.isImporting ||
                        !widget.controller.hasImportedDatabase
                    ? null
                    : () async {
                        await widget.controller.deleteImportedDatabase();
                        await _afterDelete();
                      },
                icon: const Icon(Icons.delete_outline),
                label: const Text('حذف قاعدة الأرقام الحالية'),
              ),
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: widget.controller.isImporting
                    ? null
                    : widget.controller.clearTemporaryFiles,
                icon: const Icon(Icons.cleaning_services_outlined),
                label: const Text('تنظيف الملفات المؤقتة للاستيراد'),
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
