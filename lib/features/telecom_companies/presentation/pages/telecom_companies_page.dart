import 'package:flutter/material.dart';

import '../../data/models/telecom_company.dart';
import '../telecom_companies_controller.dart';

class TelecomCompaniesPage extends StatelessWidget {
  final TelecomCompaniesController controller;

  const TelecomCompaniesPage({required this.controller, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('شركات الاتصالات')),
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          if (controller.isLoading && controller.companies.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'إدارة الشركات المستخدمة في فلتر البحث بالاسم',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              if (controller.companies.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('لا توجد شركات مضافة حاليًا'),
                  ),
                )
              else
                ...controller.companies.map(
                  (company) => _CompanyTile(
                    company: company,
                    onToggle: () => controller.toggle(company),
                    onEdit: () => _showCompanyDialog(context, company),
                    onDelete: () => _confirmDelete(context, company),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCompanyDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('إضافة شركة'),
      ),
    );
  }

  Future<void> _showCompanyDialog(
    BuildContext context, [
    TelecomCompany? company,
  ]) async {
    final nameController = TextEditingController(text: company?.name ?? '');
    final prefixController =
        TextEditingController(text: company?.prefix ?? '');

    final result = await showDialog<TelecomCompany>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(company == null ? 'إضافة شركة' : 'تعديل شركة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'اسم الشركة'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: prefixController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'مقدمة الرقم'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              final prefix = prefixController.text.trim();
              if (name.isEmpty || prefix.isEmpty) return;
              Navigator.pop(
                context,
                TelecomCompany(
                  id: company?.id,
                  name: name,
                  prefix: prefix,
                  isActive: company?.isActive ?? true,
                  sortOrder: company?.sortOrder ?? 0,
                ),
              );
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );

    nameController.dispose();
    prefixController.dispose();
    if (result != null) await controller.save(result);
  }

  Future<void> _confirmDelete(
    BuildContext context,
    TelecomCompany company,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الشركة'),
        content: Text('هل تريد حذف ${company.name}؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed == true) await controller.delete(company);
  }
}

class _CompanyTile extends StatelessWidget {
  final TelecomCompany company;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CompanyTile({
    required this.company,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Switch(value: company.isActive, onChanged: (_) => onToggle()),
        title: Text(company.name),
        subtitle: Text('مقدمة الرقم: ${company.prefix}'),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') onEdit();
            if (value == 'delete') onDelete();
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'edit', child: Text('تعديل')),
            PopupMenuItem(value: 'delete', child: Text('حذف')),
          ],
        ),
      ),
    );
  }
}
