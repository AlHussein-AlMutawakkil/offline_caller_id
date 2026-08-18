import 'name_search_controller.dart';
import 'number_search_controller.dart';

class SearchControllersBundle {
  final NumberSearchController number;
  final NameSearchController name;

  const SearchControllersBundle({
    required this.number,
    required this.name,
  });
}
