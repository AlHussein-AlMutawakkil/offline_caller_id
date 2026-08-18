class PhoneNormalizer {
  const PhoneNormalizer._();

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
    }

    return normalized;
  }
}
