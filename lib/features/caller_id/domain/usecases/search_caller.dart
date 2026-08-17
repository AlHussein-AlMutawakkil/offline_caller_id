import '../entities/contact_record.dart';
import '../repositories/caller_id_repository.dart';

class SearchByNumber {
  final CallerIdRepository repository;

  const SearchByNumber(this.repository);

  Future<List<ContactRecord>> call(String number) {
    return repository.searchByNumber(number.trim());
  }
}

class SearchByName {
  final CallerIdRepository repository;

  const SearchByName(this.repository);

  Future<List<ContactRecord>> call(
    String name, {
    String? companyPrefix,
  }) {
    return repository.searchByName(
      name.trim(),
      companyPrefix: companyPrefix,
    );
  }
}

class CountCallerRecords {
  final CallerIdRepository repository;

  const CountCallerRecords(this.repository);

  Future<int> call() => repository.countRecords();
}
