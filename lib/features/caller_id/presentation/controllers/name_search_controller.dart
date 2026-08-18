import '../../data/datasources/caller_database_datasource.dart';
import '../../data/repositories/caller_id_repository_impl.dart';
import '../../domain/entities/contact_record.dart';
import '../../domain/usecases/search_caller.dart';

class NameSearchController {
  final SearchByName _searchByName;

  List<ContactRecord> results = const [];
  bool isLoading = false;
  String lastQuery = '';
  String? errorMessage;
  int _requestId = 0;

  NameSearchController.fromDataSource(CallerDatabaseDataSource dataSource)
      : this._(CallerIdRepositoryImpl(dataSource));

  NameSearchController._(CallerIdRepositoryImpl repository)
      : _searchByName = SearchByName(repository);

  Future<void> search(
    String query, {
    String? companyPrefix,
  }) async {
    final value = query.trim();
    if (value.isEmpty) return;

    final requestId = ++_requestId;
    lastQuery = value;
    isLoading = true;
    errorMessage = null;

    try {
      final data = await _searchByName(
        value,
        companyPrefix: companyPrefix,
      );
      if (requestId == _requestId) results = data;
    } catch (error) {
      if (requestId == _requestId) errorMessage = error.toString();
    } finally {
      if (requestId == _requestId) isLoading = false;
    }
  }
}
