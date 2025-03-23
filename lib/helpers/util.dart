import 'dart:math';

import 'package:flutter/rendering.dart';

String durationNotation(double milliseconds) {
  Duration duration = Duration(milliseconds: milliseconds.floor());
  final days = duration.inDays;
  if (days > 1) {
    return '$days days';
  }
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  return '$hours:${minutes.toString().padLeft(2, '0')}';

  // if (milliseconds < 3600000) {
  //   final mins = (milliseconds / 60000);
  //   if (mins >= 1 && mins < 1.01) {
  //     return "${toLettersNotation(mins)}m";
  //   }
  //   return "${toLettersNotation(mins)}mins";
  // }
  // final hrs = milliseconds / 3600000;
  // if (hrs >= 1 && hrs < 1.01) {
  //   return "${toLettersNotation(hrs)}hr";
  // }
  // return "${toLettersNotation(hrs)}hrs";
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

String formatRelativeTime(DateTime dateTime) {
  final now = DateTime.now();
  final difference = now.difference(dateTime);

  if (difference.inMinutes < 1) {
    return 'Just now';
  } else if (difference.inHours < 1) {
    return '${difference.inMinutes}m ago';
  } else if (difference.inDays < 1) {
    return '${difference.inHours}h ago';
  } else if (difference.inDays < 7) {
    return '${difference.inDays}d ago';
  }
  return '${dateTime.year}-${dateTime.month}-${dateTime.day}';
}

bool isSorted<T extends Comparable>(List<T> list) {
  for (int i = 0; i < list.length - 1; i++) {
    if (list[i].compareTo(list[i + 1]) > 0) {
      return false;
    }
  }
  return true;
}

void debugPrintWithCaller(String message, {int depth = 2}) {
  final stackTrace = StackTrace.current.toString().split("\n");

  if (stackTrace.length > depth) {
    final traceLine = stackTrace[depth]; // Get caller info
    final match = RegExp(r'^(.*) \((.*):(\d+):(\d+)\)$').firstMatch(traceLine);

    if (match != null) {
      final filePath = match.group(2); // File path
      final lineNumber = match.group(3); // Line number

      debugPrint("[$filePath:$lineNumber] $message");
    } else {
      debugPrint(message);
    }
  } else {
    debugPrint(message);
  }
}

int get todayTimestamp {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
}

extension EnumByNameOrNull<T extends Enum> on Iterable<T> {
  T? byNameOrNull(String name) {
    for (var value in this) {
      if (value.name == name) return value;
    }
    return null;
  }
}

extension StringExtensions on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
