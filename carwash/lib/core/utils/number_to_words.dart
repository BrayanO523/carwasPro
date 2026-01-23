class NumberToWords {
  static String convert(double number) {
    if (number == 0) return 'CERO LEMPIRAS EXACTOS';

    // Fix rounding issues (e.g. 321.996 -> 322.00)
    double rounded = double.parse(number.toStringAsFixed(2));

    int integers = rounded.truncate();
    int decimals = ((rounded - integers) * 100).round();

    String integersText = _convertInteger(integers);
    String decimalsText = decimals.toString().padLeft(2, '0');

    return '$integersText LEMPIRAS CON $decimalsText/100'.toUpperCase();
  }

  static String _convertInteger(int n) {
    if (n == 0) return '';
    if (n < 0) return 'MENOS ${_convertInteger(-n)}';

    if (n <= 999) return _convertHundreds(n);
    if (n <= 999999) return _convertThousands(n);
    if (n <= 999999999) return _convertMillions(n);

    return n.toString(); // Fallback for huge numbers
  }

  static String _convertHundreds(int n) {
    if (n > 999) return '';

    if (n == 100) return 'CIEN';
    if (n > 100 && n <= 199) return 'CIENTO ${_convertHundreds(n - 100)}';

    final List<String> units = [
      '',
      'UN',
      'DOS',
      'TRES',
      'CUATRO',
      'CINCO',
      'SEIS',
      'SIETE',
      'OCHO',
      'NUEVE',
      'DIEZ',
      'ONCE',
      'DOCE',
      'TRECE',
      'CATORCE',
      'QUINCE',
      'DIECISÉIS',
      'DIECISIETE',
      'DIECIOCHO',
      'DIECINUEVE',
      'VEINTE',
      'VEINTIÚN',
      'VEINTIDÓS',
      'VEINTITRÉS',
      'VEINTICUATRO',
      'VEINTICINCO',
      'VEINTISÉIS',
      'VEINTISIETE',
      'VEINTIOCHO',
      'VEINTINUEVE',
    ];

    final List<String> tens = [
      '',
      'DIEZ',
      'VEINTE',
      'TREINTA',
      'CUARENTA',
      'CINCUENTA',
      'SESENTA',
      'SETENTA',
      'OCHENTA',
      'NOVENTA',
    ];

    final List<String> hundreds = [
      '',
      'CIENTO',
      'DOSCIENTOS',
      'TRESCIENTOS',
      'CUATROCIENTOS',
      'QUINIENTOS',
      'SEISCIENTOS',
      'SETECIENTOS',
      'OCHOCIENTOS',
      'NOVECIENTOS',
    ];

    if (n < 30) return units[n];

    if (n < 100) {
      int ten = n ~/ 10;
      int unit = n % 10;
      return unit == 0 ? tens[ten] : '${tens[ten]} Y ${units[unit]}';
    }

    int hundred = n ~/ 100;
    int rest = n % 100;
    return '${hundreds[hundred]} ${_convertHundreds(rest)}'.trim();
  }

  static String _convertThousands(int n) {
    int thousand = n ~/ 1000;
    int rest = n % 1000;

    String thousandText = thousand == 1
        ? 'MIL'
        : '${_convertHundreds(thousand)} MIL';
    if (rest == 0) return thousandText;

    return '$thousandText ${_convertHundreds(rest)}';
  }

  static String _convertMillions(int n) {
    int million = n ~/ 1000000;
    int rest = n % 1000000;

    String millionText = million == 1
        ? 'UN MILLON'
        : '${_convertInteger(million)} MILLONES';

    if (rest == 0) return millionText;

    // Check if rest is in thousands range to avoid recursion issues if structure changes
    if (rest >= 1000) return '$millionText ${_convertThousands(rest)}';
    return '$millionText ${_convertHundreds(rest)}';
  }
}
