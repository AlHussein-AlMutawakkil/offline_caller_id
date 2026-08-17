import '../../data/datasources/caller_database_datasource.dart';
import '../../data/repositories/caller_id_repository_impl.dart';
import '../../domain/entities/contact_record.dart';
import '../../domain/usecases/search_caller.dart';

class CallerIdController {
  final SearchByNumber searchByNumber;
  final SearchByName searchByName;
  final CountCallerRecords countCallerRecords;

  List<ContactRecord> results = const [];
  bool isLoading = false;
  int totalRecords = 0;
  String? errorMessage;
  int _requestId = 0;

  CallerIdController.fromDataSource(CallerDatabaseDataSource dataSource)
      : this._(
          CallerIdRepositoryImpl(dataSource),
        );

  CallerIdController._(CallerIdRepositoryImpl repository)
      : searchByNumber = SearchByNumber(repository),
        searchByName = SearchByName(repository),
        countCallerRecords = CountCallerRecords(repository);

  Future<void> loadCount() async {
    try {
      totalRecords = await countCallerRecords();
    } catch (error) {
      errorMessage = error.toString();
    }
  }

  Future<void> searchNumber(String query) async {
    final value = query.trim();
    if (value.isEmpty) return;

    final requestId = ++_requestId;
    isLoading = true;
    errorMessage = null;

    try {
      final data = await searchByNumber(value);
      if (requestId == _requestId) results = data;
    } catch (error) {
      if (requestId == _requestId) errorMessage = error.toString();
    } finally {
      if (requestId == _requestId) isLoading = false;
    }
  }

  Future<void> searchName(
    String query, {
    String? companyPrefix,
  }) async {
    final value = query.trim();
    if (value.isEmpty) return;

    final requestId = ++_requestId;
    isLoading = true;
    errorMessage = null;

    try {
      final data = await searchByName(value, companyPrefix: companyPrefix);
      if (requestId == _requestId) results = data;
    } catch (error) {
      if (requestId == _requestId) errorMessage = error.toString();
    } finally {
      if (requestId == _requestId) isLoading = false;
    }
  }
}
