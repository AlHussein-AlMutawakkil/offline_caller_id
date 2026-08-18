import 'package:flutter/foundation.dart';

import '../../data/datasources/caller_database_datasource.dart';
import '../../data/repositories/caller_id_repository_impl.dart';
import '../../domain/entities/contact_record.dart';
import '../../domain/usecases/search_caller.dart';

class NumberSearchController extends ChangeNotifier {
  final SearchByNumber _searchByNumber;
  final CountCallerRecords _countCallerRecords;

  List<ContactRecord> results = const [];
  bool isLoading = false;
  int totalRecords = 0;
  String? errorMessage;
  int _requestId = 0;

  NumberSearchController.fromDataSource(CallerDatabaseDataSource dataSource)
      : this._(CallerIdRepositoryImpl(dataSource));

  NumberSearchController._(CallerIdRepositoryImpl repository)
      : _searchByNumber = SearchByNumber(repository),
        _countCallerRecords = CountCallerRecords(repository);

  Future<void> loadCount() async {
    try {
      totalRecords = await _countCallerRecords();
    } catch (error) {
      errorMessage = error.toString();
    } finally {
      notifyListeners();
    }
  }

  Future<void> search(String query) async {
    final value = query.trim();
    if (value.isEmpty) return;

    final requestId = ++_requestId;
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final data = await _searchByNumber(value);
      if (requestId == _requestId) results = data;
    } catch (error) {
      if (requestId == _requestId) errorMessage = error.toString();
    } finally {
      if (requestId == _requestId) isLoading = false;
      if (requestId == _requestId) notifyListeners();
    }
  }
}
