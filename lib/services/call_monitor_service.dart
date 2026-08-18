import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart' as overlay;
import 'package:permission_handler/permission_handler.dart';
import 'package:phone_state/phone_state.dart';

import '../features/caller_id/data/datasources/caller_database_datasource.dart';
import '../features/caller_id/data/datasources/database_connection.dart';
import '../features/caller_id/data/repositories/caller_id_repository_impl.dart';
import '../features/settings/data/app_settings_database.dart';

/// أسلوب الخدمات: تهيئة غير حاجبة، وتشغيل فقط عندما يختاره المستخدم ويمنح إذن الهاتف.
abstract final class CallMonitorService {
  static const notificationChannelId = 'offline_caller_id_channel';
  static const notificationId = 888;
  static Future<void>? _initialization;

  static Future<void> initialize() {
    return _initialization ??= _configure();
  }

  static Future<void> _configure() async {
    final service = FlutterBackgroundService();
    const channel = AndroidNotificationChannel(
      notificationChannelId,
      'خدمة كاشف الأرقام',
      description: 'تشغيل التعرف على المتصل في الخلفية',
      importance: Importance.low,
    );

    final notifications = FlutterLocalNotificationsPlugin();
    await notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: notificationChannelId,
        initialNotificationTitle: 'كاشف الأرقام أوف لاين',
        initialNotificationContent: 'التعرف على المتصل يعمل',
        foregroundServiceNotificationId: notificationId,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  static Future<void> syncWithSettings() async {
    await initialize();
    final settings = await _readRuntimeSettings();
    final service = FlutterBackgroundService();
    final isRunning = await service.isRunning();
    final phoneGranted = await Permission.phone.isGranted;

    if (!settings.callerIdentificationEnabled || !phoneGranted) {
      if (isRunning) service.invoke('stopService');
      if (await overlay.FlutterOverlayWindow.isActive()) {
        await overlay.FlutterOverlayWindow.closeOverlay();
      }
      return;
    }

    if (!isRunning) await service.startService();
  }
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  final connection = DatabaseConnection();
  StreamSubscription<PhoneState>? phoneSubscription;

  phoneSubscription = PhoneState.stream.listen((event) async {
    if (event.status == PhoneStateStatus.CALL_INCOMING) {
      final incomingNumber = event.number;
      if (incomingNumber == null || incomingNumber.isEmpty) return;

      try {
        final settings = await _readRuntimeSettings();
        if (!settings.callerIdentificationEnabled || !settings.overlayEnabled) {
          return;
        }
        if (!await overlay.FlutterOverlayWindow.isPermissionGranted()) return;

        final database = await connection.database;
        final repository = CallerIdRepositoryImpl(
          CallerDatabaseDataSource(database),
        );
        final results = await repository.searchByNumber(incomingNumber);
        final displayName = results.isEmpty
            ? 'رقم غير مسجل'
            : results.first.namesList.join('، ');

        final isActive = await overlay.FlutterOverlayWindow.isActive();
        if (!isActive) {
          await overlay.FlutterOverlayWindow.showOverlay(
            height: 450,
            width: overlay.WindowSize.matchParent,
            alignment: overlay.OverlayAlignment.center,
            flag: overlay.OverlayFlag.defaultFlag,
            enableDrag: false,
            positionGravity: overlay.PositionGravity.auto,
          );
        }

        await overlay.FlutterOverlayWindow.shareData({
          'name': displayName,
          'phone': incomingNumber,
        });
      } catch (error) {
        debugPrint('Call monitor lookup failed: $error');
      }
    }

    if (event.status == PhoneStateStatus.CALL_ENDED) {
      if (await overlay.FlutterOverlayWindow.isActive()) {
        await overlay.FlutterOverlayWindow.closeOverlay();
      }
    }
  });

  service.on('stopService').listen((_) async {
    await phoneSubscription?.cancel();
    await connection.close();
    service.stopSelf();
  });
}

class _RuntimeSettings {
  final bool callerIdentificationEnabled;
  final bool overlayEnabled;

  const _RuntimeSettings({
    required this.callerIdentificationEnabled,
    required this.overlayEnabled,
  });
}

Future<_RuntimeSettings> _readRuntimeSettings() async {
  const callerKey = 'caller_identification_enabled';
  const overlayKey = 'overlay_enabled';
  final database = AppSettingsDatabase();
  try {
    final callerValue = await database.read(callerKey);
    final overlayValue = await database.read(overlayKey);
    return _RuntimeSettings(
      callerIdentificationEnabled: callerValue?.toLowerCase() == 'true',
      overlayEnabled: overlayValue?.toLowerCase() == 'true',
    );
  } finally {
    await database.close();
  }
}
