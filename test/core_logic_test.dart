import 'package:flutter_test/flutter_test.dart';
import 'package:offline_caller_id/core/utils/phone_normalizer.dart';
import 'package:offline_caller_id/features/caller_id/domain/entities/contact_record.dart';

void main() {
  group('PhoneNormalizer', () {
    test('يوحد الأرقام العربية والمسافات وصيغة +967', () {
      expect(PhoneNormalizer.normalize('+967 ٧٧-١٢٣ ٤٥٦٧'), '771234567');
    });

    test('يوحد صيغة 00967', () {
      expect(PhoneNormalizer.normalize('00967 71 222 333'), '71222333');
    });
  });

  test('يفصل ContactRecord الأسماء المتعددة دون عناصر فارغة', () {
    const record = ContactRecord(
      phone: '771234567',
      names: 'أحمد، أحمد علي |  أحمد خالد , ',
    );

    expect(record.namesList, ['أحمد', 'أحمد علي', 'أحمد خالد']);
  });
}
