class ContactRecord {
  final String phone;
  final String names;
  final String? company;

  const ContactRecord({
    required this.phone,
    required this.names,
    this.company,
  });

  List<String> get namesList => names
      .split(RegExp(r'[,،|]'))
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toList(growable: false);
}
