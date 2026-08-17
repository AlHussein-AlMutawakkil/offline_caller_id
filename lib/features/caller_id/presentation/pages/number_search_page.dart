import 'package:flutter/material.dart';

import '../../domain/entities/contact_record.dart';
import '../controllers/caller_id_controller.dart';

class NumberSearchPage extends StatefulWidget {
  final CallerIdController controller;

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
    await widget.controller.searchNumber(_searchController.text);
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
  final CallerIdController controller;

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

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      itemCount: controller.results.length,
      itemBuilder: (context, index) {
        return _ContactCard(record: controller.results[index]);
      },
    );
  }
}

class _ContactCard extends StatelessWidget {
  final ContactRecord record;

  const _ContactCard({required this.record});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person)),
        title: Text(record.namesList.join('، ')),
        subtitle: Text(record.phone),
      ),
    );
  }
}
