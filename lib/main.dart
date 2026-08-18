import 'dart:async';

import 'package:flutter/material.dart';

import 'app/app.dart';
import 'features/caller_overlay/presentation/caller_overlay_page.dart';
import 'services/call_monitor_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  unawaited(CallMonitorService.initialize());
  runApp(const OfflineCallerIdApp());
}

@pragma('vm:entry-point')
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: CallerOverlayPage(),
      ),
    ),
  );
}
