import 'package:flutter/material.dart';

import '../features/caller_id/presentation/pages/home_page.dart';
import 'app_theme.dart';

class OfflineCallerIdApp extends StatelessWidget {
  const OfflineCallerIdApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'كاشف الأرقام أوف لاين',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const HomePage(),
    );
  }
}
