import 'package:flutter/material.dart';

import '../data/app_settings_database.dart';
import '../../../services/call_monitor_service.dart';

class AppSettingsController extends ChangeNotifier {
  static const _themeModeKey = 'theme_mode';
  static const _callerIdentificationKey = 'caller_identification_enabled';
  static const _overlayKey = 'overlay_enabled';
  static const _showDatabaseOnHomeKey = 'show_database_on_home';

  final AppSettingsDatabase database;

  ThemeMode themeMode = ThemeMode.system;
  bool callerIdentificationEnabled = false;
  bool overlayEnabled = false;
  bool showDatabaseOnHome = true;
  bool isLoading = false;

  AppSettingsController(this.database);

  Future<void> load() async {
    isLoading = true;
    notifyListeners();
    try {
      themeMode = _parseThemeMode(await database.read(_themeModeKey));
      callerIdentificationEnabled =
          _parseBool(await database.read(_callerIdentificationKey), false);
      overlayEnabled = _parseBool(await database.read(_overlayKey), false);
      showDatabaseOnHome =
          _parseBool(await database.read(_showDatabaseOnHomeKey), true);
      await syncCallMonitorService();
    } catch (_) {
      // في اختبارات Flutter قد لا تكون sqflite مهيأة؛ نستخدم القيم الافتراضية.
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setThemeMode(ThemeMode value) async {
    themeMode = value;
    notifyListeners();
    await database.write(_themeModeKey, value.name);
  }

  Future<void> setCallerIdentificationEnabled(bool value) async {
    callerIdentificationEnabled = value;
    notifyListeners();
    await database.write(_callerIdentificationKey, value.toString());
    await syncCallMonitorService();
  }

  Future<void> setOverlayEnabled(bool value) async {
    overlayEnabled = value;
    notifyListeners();
    await database.write(_overlayKey, value.toString());
    await syncCallMonitorService();
  }

  Future<void> setShowDatabaseOnHome(bool value) async {
    showDatabaseOnHome = value;
    notifyListeners();
    await database.write(_showDatabaseOnHomeKey, value.toString());
  }

  Future<void> syncCallMonitorService() async {
    try {
      await CallMonitorService.syncWithSettings();
    } catch (_) {
      // لا تؤثر تهيئة Android على فتح الإعدادات أو اختبار Widget.
    }
  }

  ThemeMode _parseThemeMode(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  bool _parseBool(String? value, bool fallback) {
    if (value == null) return fallback;
    return value.toLowerCase() == 'true';
  }

  @override
  void dispose() {
    database.close();
    super.dispose();
  }
}
