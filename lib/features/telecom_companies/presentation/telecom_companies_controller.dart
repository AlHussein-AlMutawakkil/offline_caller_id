import 'package:flutter/foundation.dart';

import '../data/models/telecom_company.dart';
import '../data/repositories/telecom_company_repository.dart';

class TelecomCompaniesController extends ChangeNotifier {
  final TelecomCompanyRepository repository;

  List<TelecomCompany> companies = const [];
  bool isLoading = false;
  String? errorMessage;

  TelecomCompaniesController(this.repository);

  List<TelecomCompany> get activeCompanies =>
      companies.where((company) => company.isActive).toList();

  Future<void> load() async {
    isLoading = true;
    notifyListeners();
    try {
      companies = await repository.getAll();
      errorMessage = null;
    } catch (error) {
      errorMessage = error.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> save(TelecomCompany company) async {
    await repository.save(company);
    await load();
  }

  Future<void> toggle(TelecomCompany company) async {
    await save(company.copyWith(isActive: !company.isActive));
  }

  Future<void> delete(TelecomCompany company) async {
    if (company.id == null) return;
    await repository.delete(company.id!);
    await load();
  }

  @override
  void dispose() {
    repository.database.close();
    super.dispose();
  }
}
