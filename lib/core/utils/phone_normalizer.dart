class PhoneNormalizer {
  const PhoneNormalizer._();

  /// أطول رقم محلي متوقع داخل اليمن (رقم جوال من 9 خانات مثل 7xxxxxxxx).
  static const _yemenLocalNumberMaxLength = 9;

  static String normalize(String value) {
    var normalized = value
        .replaceAll('٠', '0')
        .replaceAll('١', '1')
        .replaceAll('٢', '2')
        .replaceAll('٣', '3')
        .replaceAll('٤', '4')
        .replaceAll('٥', '5')
        .replaceAll('٦', '6')
        .replaceAll('٧', '7')
        .replaceAll('٨', '8')
        .replaceAll('٩', '9')
        .replaceAll(RegExp(r'[\s\-()/.]'), '');

    if (normalized.startsWith('+967')) {
      normalized = normalized.substring(4);
    } else if (normalized.startsWith('00967')) {
      normalized = normalized.substring(5);
    } else if (normalized.startsWith('967') &&
        normalized.length > _yemenLocalNumberMaxLength) {
      // بعض أجهزة Android تُسلّم رقم المتصل الوارد بصيغة 967xxxxxxxxx
      // بدون + أو 00. الشرط على الطول يمنع قص أرقام محلية تبدأ فعليًا
      // بـ 967 (لا يوجد بادئة شركات يمنية تبدأ بهذا التسلسل حاليًا، لكن
      // الاحتياط يبقي السلوك آمنًا لو تغيّرت مخططات الترقيم مستقبلًا).
      normalized = normalized.substring(3);
    }

    return normalized;
  }
}
