import 'package:flutter/material.dart';

import '../../../../app/app_drawer.dart';
import '../../../database_import/data/database_import_service.dart';
import '../../../database_import/presentation/database_import_controller.dart';
import '../../../database_import/presentation/pages/database_management_page.dart';
import '../../../database_import/presentation/widgets/database_import_card.dart';
import '../../../database_import/presentation/widgets/database_ready_banner.dart';
import '../../../settings/presentation/app_settings_controller.dart';
import '../../../settings/presentation/pages/permissions_page.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import '../../../telecom_companies/data/datasources/telecom_companies_database.dart';
import '../../../telecom_companies/data/repositories/telecom_company_repository.dart';
import '../../../telecom_companies/presentation/pages/telecom_companies_page.dart';
import '../../../telecom_companies/presentation/telecom_companies_controller.dart';
import '../../data/datasources/caller_database_datasource.dart';
import '../../data/datasources/database_connection.dart';
import '../controllers/name_search_controller.dart';
import '../controllers/number_search_controller.dart';
import '../controllers/search_controllers_bundle.dart';
import 'name_search_page.dart';
import 'number_search_page.dart';

class HomePage extends StatefulWidget {
  final AppSettingsController settingsController;

  const HomePage({required this.settingsController, super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final DatabaseConnection _databaseConnection;
  late final DatabaseImportController _importController;
  late final TelecomCompaniesController _companiesController;
  late Future<SearchControllersBundle> _searchControllersFuture;

  @override
  void initState() {
    super.initState();
    _databaseConnection = DatabaseConnection();
    _importController = DatabaseImportController(
      DatabaseImportService(
        closeCurrentDatabase: _databaseConnection.close,
      ),
    );
    _companiesController = TelecomCompaniesController(
      TelecomCompanyRepository(TelecomCompaniesDatabase()),
    );
    _searchControllersFuture = _createSearchControllers();
    _importController.initialize();
    _companiesController.load();
  }

  Future<SearchControllersBundle> _createSearchControllers() async {
    final database = await _databaseConnection.database;
    final dataSource = CallerDatabaseDataSource(database);
    final numberController = NumberSearchController.fromDataSource(dataSource);
    final nameController = NameSearchController.fromDataSource(dataSource);
    await numberController.loadCount();
    return SearchControllersBundle(
      number: numberController,
      name: nameController,
    );
  }

  void _refreshSearchControllers() {
    if (!mounted) return;
    setState(() {
      _searchControllersFuture = _createSearchControllers();
    });
  }

  Future<void> _openDrawerItem(String item) async {
    if (item == 'home') return;
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

    if (item == 'permissions') {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PermissionsPage()),
      );
      return;
    }

    if (item == 'settings') {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SettingsPage(controller: widget.settingsController),
        ),
      );
      return;
    }

    if (item == 'companies') {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TelecomCompaniesPage(
            controller: _companiesController,
          ),
        ),
      );
      return;
    }

    if (item == 'database') {
      final controllers = await _searchControllersFuture;
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => DatabaseManagementPage(
            controller: _importController,
            totalRecords: controllers.number.totalRecords,
            onDatabaseChanged: _refreshSearchControllers,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _importController.dispose();
    _companiesController.dispose();
    _databaseConnection.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;
          return DefaultTabController(
            length: 2,
            child: Scaffold(
              drawer: isWide
                ? null
                : AppDrawer(
                    currentItem: 'home',
                    onSelected: _openDrawerItem,
                  ),
            appBar: AppBar(
              title: const Text('كاشف الأرقام أوف لاين'),
              actions: [
                IconButton(
                  onPressed: () => _openDrawerItem('settings'),
                  icon: const Icon(Icons.settings_outlined),
                  tooltip: 'الإعدادات',
                ),
              ],
              bottom: const TabBar(
                tabs: [
                  Tab(text: 'بحث بالاسم', icon: Icon(Icons.person_search)),
                  Tab(text: 'بحث بالرقم', icon: Icon(Icons.dialpad)),
                ],
              ),
            ),
              body: Row(
                children: [
                  if (isWide)
                    SizedBox(
                      width: 280,
                      child: AppDrawer(
                        currentItem: 'home',
                        onSelected: _openDrawerItem,
                      ),
                    ),
                  Expanded(child: _buildSearchContent(isWide)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchContent(bool isWide) {
    return FutureBuilder<SearchControllersBundle>(
      future: _searchControllersFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final controllers = snapshot.data!;
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isWide ? 1100 : 700),
            child: Column(
              children: [
                AnimatedBuilder(
                  animation: Listenable.merge([
                    _importController,
                    widget.settingsController,
                  ]),
                  builder: (context, _) {
                    if (!widget.settingsController.showDatabaseOnHome) {
                      return const SizedBox.shrink();
                    }
                    if (_importController.hasImportedDatabase) {
                      return DatabaseReadyBanner(
                        totalRecords: controllers.number.totalRecords,
                      );
                    }
                    return DatabaseImportCard(
                      controller: _importController,
                      onImported: _refreshSearchControllers,
                    );
                  },
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      NameSearchPage(
                        controller: controllers.name,
                        companiesController: _companiesController,
                      ),
                      NumberSearchPage(controller: controllers.number),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
