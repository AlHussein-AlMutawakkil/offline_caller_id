import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:offline_caller_id/app/app.dart';

void main() {
  testWidgets('يعرض التطبيق واجهته الأساسية', (tester) async {
    await tester.pumpWidget(const OfflineCallerIdApp());
    await tester.pump();

    expect(find.text('كاشف الأرقام أوف لاين'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
