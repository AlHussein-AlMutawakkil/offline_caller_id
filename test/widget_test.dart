import 'package:flutter_test/flutter_test.dart';

import 'package:offline_caller_id/app/app.dart';

void main() {
  testWidgets('يعرض التطبيق الشاشة الرئيسية الأساسية', (tester) async {
    await tester.pumpWidget(const OfflineCallerIdApp());

    expect(find.text('كاشف الأرقام أوف لاين'), findsOneWidget);
    expect(find.text('تم إنشاء أساس المشروع بنجاح'), findsOneWidget);
  });
}
