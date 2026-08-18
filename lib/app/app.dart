import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../features/caller_id/presentation/pages/home_page.dart';
import '../features/settings/data/app_settings_database.dart';
import '../features/settings/presentation/app_settings_controller.dart';
import 'app_theme.dart';

/// أسلوب العرض: RTL عام للتطبيق كله؛ لا يعتمد على الصفحة الرئيسية وحدها.
class OfflineCallerIdApp extends StatefulWidget {
  const OfflineCallerIdApp({super.key});

  @override
  State<OfflineCallerIdApp> createState() => _OfflineCallerIdAppState();
}

class _OfflineCallerIdAppState extends State<OfflineCallerIdApp> {
  late final AppSettingsController _settingsController;

  @override
  void initState() {
    super.initState();
    _settingsController = AppSettingsController(AppSettingsDatabase())..load();
  }

  @override
  void dispose() {
    _settingsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _settingsController,
      builder: (context, _) {
        return MaterialApp(
          title: 'كاشف الأرقام أوف لاين',
          debugShowCheckedModeBanner: false,
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: _settingsController.themeMode,
          builder: (context, child) => Directionality(
            textDirection: TextDirection.rtl,
            child: child ?? const SizedBox.shrink(),
          ),
          home: HomePage(settingsController: _settingsController),
        );
      },
    );
  }
}
