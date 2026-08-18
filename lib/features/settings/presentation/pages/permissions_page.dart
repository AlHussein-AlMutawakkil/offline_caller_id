import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionsPage extends StatefulWidget {
  const PermissionsPage({super.key});

  @override
  State<PermissionsPage> createState() => _PermissionsPageState();
}

class _PermissionsPageState extends State<PermissionsPage> {
  final _permissions = const [
    _PermissionItem(
      permission: Permission.phone,
      title: 'الهاتف وسجل المكالمات',
      description: 'قراءة حالة المكالمة والتعرف على الرقم أثناء الاتصال.',
      icon: Icons.phone_outlined,
    ),
    _PermissionItem(
      permission: Permission.notification,
      title: 'الإشعارات',
      description: 'عرض حالة خدمة التعرف على المتصل والتنبيهات المطلوبة.',
      icon: Icons.notifications_outlined,
    ),
    _PermissionItem(
      permission: Permission.systemAlertWindow,
      title: 'الظهور فوق التطبيقات',
      description: 'عرض النافذة العائمة أثناء استقبال المكالمات.',
      icon: Icons.layers_outlined,
    ),
    _PermissionItem(
      permission: Permission.ignoreBatteryOptimizations,
      title: 'تجاهل تحسين البطارية',
      description: 'المساعدة على استمرار خدمة المراقبة في الخلفية.',
      icon: Icons.battery_saver_outlined,
    ),
  ];

  final Map<Permission, PermissionStatus> _statuses = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshStatuses();
  }

  Future<void> _refreshStatuses() async {
    setState(() => _isLoading = true);
    final values = <Permission, PermissionStatus>{};
    for (final item in _permissions) {
      values[item.permission] = await item.permission.status;
    }
    if (!mounted) return;
    setState(() {
      _statuses
        ..clear()
        ..addAll(values);
      _isLoading = false;
    });
  }

  Future<void> _openPermission(_PermissionItem item) async {
    final current = _statuses[item.permission] ?? PermissionStatus.denied;
    if (current.isPermanentlyDenied || current.isRestricted) {
      await openAppSettings();
    } else {
      await item.permission.request();
    }
    await _refreshStatuses();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الأذونات')),
      body: RefreshIndicator(
        onRefresh: _refreshStatuses,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'اضغط على أي إذن لطلبه. إذا كان الإذن مرفوضًا نهائيًا، سينتقل التطبيق إلى إعدادات Android لتفعيله يدويًا.',
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              ..._permissions.map(
                (item) => _PermissionTile(
                  item: item,
                  status: _statuses[item.permission] ?? PermissionStatus.denied,
                  onTap: () => _openPermission(item),
                ),
              ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => openAppSettings(),
              icon: const Icon(Icons.settings_outlined),
              label: const Text('فتح إعدادات التطبيق بالكامل'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionItem {
  final Permission permission;
  final String title;
  final String description;
  final IconData icon;

  const _PermissionItem({
    required this.permission,
    required this.title,
    required this.description,
    required this.icon,
  });
}

class _PermissionTile extends StatelessWidget {
  final _PermissionItem item;
  final PermissionStatus status;
  final VoidCallback onTap;

  const _PermissionTile({
    required this.item,
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final granted = status.isGranted;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          item.icon,
          color: granted
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.error,
        ),
        title: Text(item.title),
        subtitle: Text('${item.description}\n${_statusText(status)}'),
        isThreeLine: true,
        trailing: Icon(
          granted ? Icons.check_circle : Icons.arrow_forward_ios,
          color: granted
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurfaceVariant,
          size: granted ? 24 : 18,
        ),
      ),
    );
  }

  String _statusText(PermissionStatus value) {
    if (value.isGranted) return 'الحالة: ممنوح';
    if (value.isPermanentlyDenied) return 'الحالة: مرفوض نهائيًا — افتح الإعدادات';
    if (value.isRestricted) return 'الحالة: مقيّد من النظام';
    return 'الحالة: غير ممنوح — اضغط للطلب';
  }
}
