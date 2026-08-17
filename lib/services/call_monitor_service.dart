import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart' as overlay;
import 'package:phone_state/phone_state.dart';

import '../features/caller_id/data/datasources/caller_database_datasource.dart';
import '../features/caller_id/data/datasources/database_connection.dart';
import '../features/caller_id/data/repositories/caller_id_repository_impl.dart';

abstract final class CallMonitorService {
  static const notificationChannelId = 'offline_caller_id_channel';
  static const notificationId = 888;

  static Future<void> initialize() async {
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
        autoStart: true,
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
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) {
  DartPluginRegistrant.ensureInitialized();

  final connection = DatabaseConnection();
  StreamSubscription<PhoneState>? phoneSubscription;

  phoneSubscription = PhoneState.stream.listen((event) async {
    if (event.status == PhoneStateStatus.CALL_INCOMING) {
      final incomingNumber = event.number;
      if (incomingNumber == null || incomingNumber.isEmpty) return;

      try {
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
      } catch (_) {
        // لا نوقف خدمة المكالمات بسبب فشل بحث واحد.
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
