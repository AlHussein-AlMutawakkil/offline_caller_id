import '../entities/contact_record.dart';

abstract interface class CallerIdRepository {
  Future<List<ContactRecord>> searchByNumber(String number);

  Future<List<ContactRecord>> searchByName(
    String name, {
    String? companyPrefix,
  });

  Future<int> countRecords();
}
