import 'dart:math';

String durationNotation(double milliseconds) {
  if (milliseconds < 3600000) {
    final mins = (milliseconds / 60000);
    if (mins >= 1 && mins < 1.01) {
      return "${toLettersNotation(mins)}min";
    }
    return "${toLettersNotation(mins)}mins";
  }
  final hrs = milliseconds / 3600000;
  if (hrs >= 1 && hrs < 1.01) {
    return "${toLettersNotation(hrs)}hr";
  }
  return "${toLettersNotation(hrs)}hrs";
}

String toLettersNotation(double number) {
  if (number < 0.1) {
    final result = number.toStringAsFixed(2);
    if (result == "0.00") {
      return "0";
    }
  }
  if (number < 1) {
    return number.toStringAsFixed(1);
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
  if (mantissa.toStringAsFixed(2).endsWith('.00')) {
    return '${mantissa.toStringAsFixed(0)}$letters';
  }
  if (mantissa * 10 == (mantissa * 10).floor()) {
    return '${mantissa.toStringAsFixed(1)}$letters';
  }
  return '${mantissa.toStringAsFixed(2)}$letters';
}
