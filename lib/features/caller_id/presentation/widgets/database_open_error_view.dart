import 'package:flutter/material.dart';

/// أسلوب العرض: حالة تشغيل واضحة بالعربية؛ هذا الـ Widget يمنع حبس المستخدم
/// في مؤشر تحميل عند تعذر فتح قاعدة الأرقام المستوردة.
class DatabaseOpenErrorView extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;
  final VoidCallback onManageDatabase;

  const DatabaseOpenErrorView({
    required this.error,
    required this.onRetry,
    required this.onManageDatabase,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.storage_outlined,
                    size: 42,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'تعذر فتح قاعدة الأرقام',
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'قد تكون القاعدة غير مكتملة أو تم استبدالها أثناء إيقاف التطبيق. يمكنك إعادة المحاولة أو فتح إدارة قاعدة البيانات لاستيراد ملف صالح.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    error.toString(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: [
                      FilledButton.icon(
                        onPressed: onRetry,
                        icon: const Icon(Icons.refresh),
                        label: const Text('إعادة المحاولة'),
                      ),
                      OutlinedButton.icon(
                        onPressed: onManageDatabase,
                        icon: const Icon(Icons.folder_open_outlined),
                        label: const Text('إدارة قاعدة البيانات'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
