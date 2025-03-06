import 'dart:math';

String toLettersNotation(double number) {
  if (number < 1) {
    return number.toStringAsPrecision(1);
  }
  if (number < 1000) {
    return number.toStringAsFixed(0);
  }

  const int asciiOffset = 97; // ASCII code for 'a'
  int exponent = (log(number) / ln10).floor() ~/ 3 * 3;
  double mantissa = number / pow(10.0, exponent);
  int letterIndex = exponent ~/ 3 - 1;
  // letter index is derived from the exponent divided by 3, minus one (since 'a' corresponds to 10³ or 1,000).

  String letters = '';
  while (letterIndex >= 0) {
    int charCode = asciiOffset + (letterIndex % 26);
    letters = String.fromCharCode(charCode) + letters;
    letterIndex = letterIndex ~/ 26 - 1;
  }

  return '${mantissa.toStringAsPrecision(2)}$letters';
}
