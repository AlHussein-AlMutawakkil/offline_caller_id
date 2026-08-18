import 'package:flutter/material.dart';

class AppDrawer extends StatelessWidget {
  final String currentItem;
  final ValueChanged<String> onSelected;

  const AppDrawer({
    required this.currentItem,
    required this.onSelected,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 280,
      child: SafeArea(
        child: Column(
          children: [
            const _Header(),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _item(
                    context,
                    id: 'home',
                    title: 'الرئيسية والبحث',
                    icon: Icons.home_outlined,
                  ),
                  _item(
                    context,
                    id: 'database',
                    title: 'إدارة قاعدة البيانات',
                    icon: Icons.storage_outlined,
                  ),
                  _item(
                    context,
                    id: 'companies',
                    title: 'شركات الاتصالات',
                    icon: Icons.business_outlined,
                  ),
                  _item(
                    context,
                    id: 'permissions',
                    title: 'الأذونات',
                    icon: Icons.security_outlined,
                  ),
                  _item(
                    context,
                    id: 'settings',
                    title: 'الإعدادات',
                    icon: Icons.settings_outlined,
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'كاشف الأرقام أوف لاين',
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _item(
    BuildContext context, {
    required String id,
    required String title,
    required IconData icon,
  }) {
    return ListTile(
      selected: currentItem == id,
      leading: Icon(icon),
      title: Text(title),
      onTap: () => onSelected(id),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Icon(
              Icons.contact_phone_outlined,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'كاشف الأرقام أوف لاين',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
