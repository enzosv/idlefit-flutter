import 'package:intl/intl.dart';

String shortNotation(double value) {
  Map<int, String> remap = {
    1000000000000000000: "c",
    1000000000000000: "b",
    1000000000000: "a",
    1000000000: "B",
    1000000: "M",
    1000: "K",
  };
  for (final key in remap.keys) {
    if (value > key) {
      // final formatter = NumberFormat('#,##,000');
      // return "${formatter.format((value / key).round())}${remap[key]}";
      return "${(value / key).toStringAsPrecision(3)}${remap[key]}";
    }
  }
  return value.round().toString();
}
