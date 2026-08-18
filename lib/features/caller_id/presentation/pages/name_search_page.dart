import 'package:flutter/material.dart';

import '../../../telecom_companies/presentation/telecom_companies_controller.dart';
import '../controllers/name_search_controller.dart';

class NameSearchPage extends StatefulWidget {
  final NameSearchController controller;
  final TelecomCompaniesController companiesController;

  const NameSearchPage({
    required this.controller,
    required this.companiesController,
    super.key,
  });

  @override
  State<NameSearchPage> createState() => _NameSearchPageState();
}

class _NameSearchPageState extends State<NameSearchPage> {
  final _searchController = TextEditingController();
  String? _selectedCompany;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    FocusScope.of(context).unfocus();
    final active = widget.companiesController.activeCompanies;
    final selected = active.where(
      (company) => company.name == _selectedCompany,
    );
    final prefix = selected.isEmpty ? null : selected.first.prefix;
    await widget.controller.search(
      _searchController.text,
      companyPrefix: prefix,
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.companiesController,
      builder: (context, _) {
        final activeCompanies = widget.companiesController.activeCompanies;
        final selectedExists = activeCompanies.any(
          (company) => company.name == _selectedCompany,
        );
        if (!selectedExists) _selectedCompany = null;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 15, 20, 10),
              child: Column(
                children: [
                  DropdownButtonFormField<String?>(
                    value: _selectedCompany,
                    decoration: const InputDecoration(
                      labelText: 'اختر شركة الاتصالات',
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('الكل'),
                      ),
                      ...activeCompanies.map(
                        (company) => DropdownMenuItem<String?>(
                          value: company.name,
                          child: Text(company.name),
                        ),
                      ),
                    ],
                    onChanged: (value) {
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
                      onPressed:
                          widget.controller.isLoading ? null : _search,
                      icon: const Icon(Icons.search),
                      label: const Text('بحث بالاسم'),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: _NameResults(controller: widget.controller)),
          ],
        );
      },
    );
  }
}

class _NameResults extends StatelessWidget {
  final NameSearchController controller;

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
        final names = record.namesList;
        final matchedName = _extractMatchingName(names, controller.lastQuery);
        final hasMultipleNames = names.length > 1;

        return InkWell(
          onTap: hasMultipleNames
              ? () => _showNamesDialog(context, record.phone, names)
              : null,
          child: Card(
            margin: const EdgeInsets.symmetric(vertical: 5),
            child: ListTile(
              leading: Icon(
                hasMultipleNames
                    ? Icons.keyboard_arrow_down
                    : Icons.person,
                color: Colors.grey,
              ),
              title: Text(matchedName, textAlign: TextAlign.center),
              subtitle: Text(record.phone, textAlign: TextAlign.center),
            ),
          ),
        );
      },
    );
  }

  String _extractMatchingName(List<String> names, String query) {
    final normalizedQuery = query.trim().toLowerCase();
    return names.firstWhere(
      (name) => name.toLowerCase().contains(normalizedQuery),
      orElse: () => names.first,
    );
  }

  void _showNamesDialog(
    BuildContext context,
    String phone,
    List<String> names,
  ) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('الأسماء المتعلقة بـ $phone'),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: names.length,
            itemBuilder: (context, index) => ListTile(
              title: Text(names[index], textAlign: TextAlign.right),
            ),
          ),
        ),
      ),
    );
  }
}
