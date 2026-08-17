import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('كاشف الأرقام أوف لاين'),
        ),
        body: const Center(
          child: Text(
            'تم إنشاء أساس المشروع بنجاح',
            style: TextStyle(fontSize: 18),
          ),
        ),
      ),
    );
  }
}
