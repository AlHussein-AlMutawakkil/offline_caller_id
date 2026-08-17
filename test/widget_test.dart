import 'package:flutter_test/flutter_test.dart';

import 'package:offline_caller_id/app/app.dart';

void main() {
  testWidgets('يعرض التطبيق شاشة استيراد قاعدة البيانات', (tester) async {
    await tester.pumpWidget(const OfflineCallerIdApp());

    expect(find.text('كاشف الأرقام أوف لاين'), findsOneWidget);
    expect(find.text('قاعدة بيانات الأرقام'), findsOneWidget);
    expect(find.text('لم يتم استيراد قاعدة بيانات بعد'), findsOneWidget);
    expect(find.text('اختيار قاعدة البيانات'), findsOneWidget);
  });
}
