import '../datasources/telecom_companies_database.dart';
import '../models/telecom_company.dart';

class TelecomCompanyRepository {
  final TelecomCompaniesDatabase database;

  const TelecomCompanyRepository(this.database);

  Future<List<TelecomCompany>> getAll() => database.getAll();

  Future<List<TelecomCompany>> getActive() => database.getActive();

  Future<void> save(TelecomCompany company) async {
    if (company.id == null) {
      await database.insert(company);
    } else {
      await database.update(company);
    }
  }

  Future<void> delete(int id) => database.delete(id);
}
