import 'package:flutter_test/flutter_test.dart';

import 'package:offline_caller_id/app/app.dart';

void main() {
  testWidgets('يعرض التطبيق شاشة البحث والاستيراد', (tester) async {
    await tester.pumpWidget(const OfflineCallerIdApp());

    expect(find.text('كاشف الأرقام أوف لاين'), findsOneWidget);
    expect(find.text('عدد السجلات: 0'), findsOneWidget);
    expect(find.text('لم يتم استيراد قاعدة بيانات بعد'), findsOneWidget);
    expect(find.text('اختيار قاعدة البيانات'), findsOneWidget);
    expect(find.text('بحث بالاسم'), findsOneWidget);
    expect(find.text('بحث بالرقم'), findsOneWidget);
  });
}
