class NumberUtils {
  static String formatNumber(double number) {
    String integerPart = number.round().toString();
    String formatted = '';
    for (int i = 0; i < integerPart.length; i++) {
      if (i > 0 && (integerPart.length - i) % 3 == 0) {
        formatted += ' ';
      }
      formatted += integerPart[i];
    }
    return formatted;
  }

  static double parseFormattedNumber(String text) {
    return double.tryParse(text.replaceAll(' ', '')) ?? 0.0;
  }
}