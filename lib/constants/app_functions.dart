class AppFunctions {
  static String numberToWords(int number) {
    if (number == 0) return 'zéro';

    final units = ['', 'un', 'deux', 'trois', 'quatre', 'cinq', 'six', 'sept', 'huit', 'neuf'];
    final teens = [
      'dix',
      'onze',
      'douze',
      'treize',
      'quatorze',
      'quinze',
      'seize',
      'dix-sept',
      'dix-huit',
      'dix-neuf'
    ];
    final tens = [
      '',
      '',
      'vingt',
      'trente',
      'quarante',
      'cinquante',
      'soixante',
      'soixante-dix',
      'quatre-vingt',
      'quatre-vingt-dix'
    ];

    String convertHundreds(int n) {
      String result = '';

      if (n >= 100) {
        int hundreds = n ~/ 100;
        if (hundreds == 1) {
          result += 'cent';
        } else {
          result += '${units[hundreds]} cent';
        }
        if (n % 100 == 0) result += 's';
        n %= 100;
        if (n > 0) result += ' ';
      }

      if (n >= 20) {
        int tensDigit = n ~/ 10;
        int unitsDigit = n % 10;

        if (tensDigit == 7) {
          result += 'soixante';
          if (unitsDigit == 1) {
            result += ' et onze';
          } else if (unitsDigit > 1) {
            result += '-${teens[unitsDigit]}';
          } else {
            result += '-dix';
          }
        } else if (tensDigit == 9) {
          result += 'quatre-vingt';
          if (unitsDigit == 1) {
            result += ' et onze';
          } else if (unitsDigit > 1) {
            result += '-${teens[unitsDigit]}';
          } else {
            result += '-dix';
          }
        } else {
          result += tens[tensDigit];
          if (unitsDigit == 1 &&
              (tensDigit == 2 || tensDigit == 3 || tensDigit == 4 || tensDigit == 5 || tensDigit == 6)) {
            result += ' et un';
          } else if (unitsDigit > 1) {
            result += '-${units[unitsDigit]}';
          }
        }
      } else if (n >= 10) {
        result += teens[n - 10];
      } else if (n > 0) {
        result += units[n];
      }

      return result;
    }

    String result = '';

    if (number >= 1000000) {
      int millions = number ~/ 1000000;
      if (millions == 1) {
        result += 'un million';
      } else {
        result += '${convertHundreds(millions)} million';
      }
      if (millions > 1) result += 's';
      number %= 1000000;
      if (number > 0) result += ' ';
    }

    if (number >= 1000) {
      int thousands = number ~/ 1000;
      if (thousands == 1) {
        result += 'mille';
      } else {
        result += '${convertHundreds(thousands)} mille';
      }
      number %= 1000;
      if (number > 0) result += ' ';
    }

    if (number > 0) {
      result += convertHundreds(number);
    }

    return result.trim().replaceAll(RegExp(r'\s+'), ' ');
  }
}
