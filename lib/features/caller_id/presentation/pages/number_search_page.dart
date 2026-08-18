import 'package:flutter/material.dart';

import '../controllers/number_search_controller.dart';

class NumberSearchPage extends StatefulWidget {
  final NumberSearchController controller;

  const NumberSearchPage({required this.controller, super.key});

  @override
  State<NumberSearchPage> createState() => _NumberSearchPageState();
}

class _NumberSearchPageState extends State<NumberSearchPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    FocusScope.of(context).unfocus();
    await widget.controller.search(_searchController.text);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                keyboardType: TextInputType.phone,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  hintText: 'أدخل الرقم المراد البحث عنه',
                  prefixIcon: Icon(Icons.dialpad),
                ),
                onSubmitted: (_) => _search(),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  onPressed: controller.isLoading ? null : _search,
                  icon: const Icon(Icons.search),
                  label: const Text('بحث بالرقم'),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(child: _ResultsList(controller: controller)),
      ],
    );
  }
}

class _ResultsList extends StatelessWidget {
  final NumberSearchController controller;

  const _ResultsList({required this.controller});

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

    final items = <_NumberResult>[];
    for (final record in controller.results) {
      final names = record.namesList;
      if (names.isEmpty) {
        items.add(_NumberResult(name: 'بدون اسم', phone: record.phone));
      } else {
        for (final name in names) {
          items.add(_NumberResult(name: name, phone: record.phone));
        }
      }
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _ContactCard(item: items[index]);
      },
    );
  }
}

class _NumberResult {
  final String name;
  final String phone;

  const _NumberResult({required this.name, required this.phone});
}

class _ContactCard extends StatelessWidget {
  final _NumberResult item;

  const _ContactCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person)),
        title: Text(item.name),
        subtitle: Text(item.phone),
      ),
    );
  }
}
