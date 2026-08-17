import '../../domain/entities/contact_record.dart';
import '../../domain/repositories/caller_id_repository.dart';
import '../datasources/caller_database_datasource.dart';

class CallerIdRepositoryImpl implements CallerIdRepository {
  final CallerDatabaseDataSource dataSource;

  const CallerIdRepositoryImpl(this.dataSource);

  @override
  Future<List<ContactRecord>> searchByNumber(String number) async {
    final rows = await dataSource.searchByNumber(number);
    return rows.map(_mapRow).toList(growable: false);
  }

  @override
  Future<List<ContactRecord>> searchByName(
    String name, {
    String? companyPrefix,
  }) async {
    final rows = await dataSource.searchByName(
      name,
      companyPrefix: companyPrefix,
    );
    return rows.map(_mapRow).toList(growable: false);
  }

  @override
  Future<int> countRecords() => dataSource.countRecords();

  ContactRecord _mapRow(Map<String, Object?> row) {
    return ContactRecord(
      phone: row['phone']?.toString().trim() ?? '',
      names: row['names']?.toString().trim() ?? 'بدون اسم',
      company: row['company']?.toString().trim(),
    );
  }
}
