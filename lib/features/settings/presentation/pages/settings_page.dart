import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../app_settings_controller.dart';

class SettingsPage extends StatelessWidget {
  final AppSettingsController controller;

  const SettingsPage({required this.controller, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SectionCard(
                title: 'المظهر والثيم',
                icon: Icons.palette_outlined,
                child: DropdownButtonFormField<ThemeMode>(
                  value: controller.themeMode,
                  decoration: const InputDecoration(
                    labelText: 'وضع التطبيق',
                    prefixIcon: Icon(Icons.brightness_6_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: ThemeMode.system,
                      child: Text('افتراضي حسب الجهاز'),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.light,
                      child: Text('نهاري'),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.dark,
                      child: Text('ليلي'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) controller.setThemeMode(value);
                  },
                ),
              ),
              _SectionCard(
                title: 'الظهور وسلوك الواجهة',
                icon: Icons.visibility_outlined,
                child: Column(
                  children: [
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('إظهار حالة القاعدة في الرئيسية'),
                      subtitle: const Text(
                        'إظهار بطاقة حالة قاعدة الأرقام أعلى شاشة البحث.',
                      ),
                      value: controller.showDatabaseOnHome,
                      onChanged: controller.setShowDatabaseOnHome,
                    ),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('تشغيل التعرف على المتصل'),
                      subtitle: const Text(
                        'يتطلب صلاحيات الهاتف وسجل المكالمات.',
                      ),
                      value: controller.callerIdentificationEnabled,
                      onChanged: controller.setCallerIdentificationEnabled,
                    ),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('تشغيل النافذة العائمة'),
                      subtitle: const Text(
                        'إظهار بطاقة الرقم فوق التطبيقات أثناء المكالمة.',
                      ),
                      value: controller.overlayEnabled,
                      onChanged: controller.setOverlayEnabled,
                    ),
                  ],
                ),
              ),
              _PermissionsCard(),
              const _AboutCard(),
            ],
          );
        },
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _PermissionsCard extends StatefulWidget {
  @override
  State<_PermissionsCard> createState() => _PermissionsCardState();
}

class _PermissionsCardState extends State<_PermissionsCard> {
  PermissionStatus _phoneStatus = PermissionStatus.denied;
  PermissionStatus _overlayStatus = PermissionStatus.denied;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final phoneStatus = await Permission.phone.status;
    final overlayStatus = await Permission.systemAlertWindow.status;
    if (!mounted) return;
    setState(() {
      _phoneStatus = phoneStatus;
      _overlayStatus = overlayStatus;
    });
  }

  Future<void> _requestPhone() async {
    await Permission.phone.request();
    await _load();
  }

  Future<void> _requestOverlay() async {
    await Permission.systemAlertWindow.request();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          const ListTile(
            leading: Icon(Icons.security_outlined),
            title: Text('الصلاحيات'),
            subtitle: Text('تحكم في الصلاحيات المطلوبة لخدمات التطبيق.'),
          ),
          ListTile(
            title: const Text('الهاتف وسجل المكالمات'),
            subtitle: Text(_statusText(_phoneStatus)),
            trailing: OutlinedButton(
              onPressed: _requestPhone,
              child: const Text('طلب الصلاحية'),
            ),
          ),
          ListTile(
            title: const Text('الظهور فوق التطبيقات'),
            subtitle: Text(_statusText(_overlayStatus)),
            trailing: OutlinedButton(
              onPressed: _requestOverlay,
              child: const Text('طلب الصلاحية'),
            ),
          ),
          ListTile(
            title: const Text('فتح إعدادات التطبيق'),
            trailing: const Icon(Icons.open_in_new),
            onTap: () => openAppSettings(),
          ),
        ],
      ),
    );
  }

  String _statusText(PermissionStatus status) {
    if (status.isGranted) return 'الصلاحية ممنوحة';
    if (status.isPermanentlyDenied) return 'مرفوضة نهائيًا — افتح الإعدادات';
    return 'الصلاحية غير ممنوحة';
  }
}

class _AboutCard extends StatelessWidget {
  const _AboutCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: ListTile(
        leading: Icon(Icons.info_outline),
        title: Text('عن التطبيق'),
        subtitle: Text('كاشف الأرقام أوف لاين — قاعدة SQLite محلية دون إنترنت.'),
      ),
    );
  }
}
