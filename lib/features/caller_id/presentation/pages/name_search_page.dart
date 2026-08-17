import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/contact_record.dart';
import '../controllers/caller_id_controller.dart';

class NameSearchPage extends StatefulWidget {
  final CallerIdController controller;

  const NameSearchPage({required this.controller, super.key});

  @override
  State<NameSearchPage> createState() => _NameSearchPageState();
}

class _NameSearchPageState extends State<NameSearchPage> {
  final _searchController = TextEditingController();
  String _selectedCompany = 'الكل';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    FocusScope.of(context).unfocus();
    final prefix = _selectedCompany == 'الكل'
        ? null
        : AppConstants.companyPrefixes[_selectedCompany];
    await widget.controller.searchName(
      _searchController.text,
      companyPrefix: prefix,
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 15, 20, 10),
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: _selectedCompany,
                decoration: const InputDecoration(
                  labelText: 'اختر شركة الاتصالات',
                ),
                items: AppConstants.companies
                    .map(
                      (company) => DropdownMenuItem(
                        value: company,
                        child: Text(company),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _selectedCompany = value);
                },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _searchController,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  hintText: 'أدخل الاسم هنا',
                  prefixIcon: Icon(Icons.person_search),
                ),
                onSubmitted: (_) => _search(),
              ),
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  onPressed: controller.isLoading ? null : _search,
                  icon: const Icon(Icons.search),
                  label: const Text('بحث بالاسم'),
                ),
              ),
            ],
          ),
        ),
        Expanded(child: _NameResults(controller: controller)),
      ],
    );
  }
}

class _NameResults extends StatelessWidget {
  final CallerIdController controller;

  const _NameResults({required this.controller});

  @override
  Widget build(BuildContext context) {
    if (controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (controller.errorMessage != null) {
      return Center(child: Text(controller.errorMessage!));
    }
    if (controller.results.isEmpty) {
      return const Center(child: Text('لا توجد نتائج لعرضها حاليًا'));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      itemCount: controller.results.length,
      itemBuilder: (context, index) {
        final record = controller.results[index];
        return _NameResultCard(record: record);
      },
    );
  }
}

class _NameResultCard extends StatelessWidget {
  final ContactRecord record;

  const _NameResultCard({required this.record});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: ListTile(
        title: Text(
          record.namesList.join('، '),
          textAlign: TextAlign.center,
        ),
        subtitle: Text(
          record.phone,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
