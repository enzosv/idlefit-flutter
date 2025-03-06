import 'package:idlefit/objectbox.g.dart';
import 'package:objectbox/objectbox.dart';

@Entity()
class HealthDataEntry {
  int id = 0; // ObjectBox automatically assigns a unique ID
  @Index()
  int timestamp; // Store as milliseconds since epoch
  double value;
  String type; // e.g., "STEPS", "ACTIVE_ENERGY_BURNED"

  HealthDataEntry({
    required this.timestamp,
    required this.value,
    required this.type,
  });
}

Future<double> healthForDay(
  Box<HealthDataEntry> box,
  String type,
  DateTime day,
) async {
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
  final entries =
      await box
          .query(
            HealthDataEntry_.type
                .equals(type)
                .and(
                  HealthDataEntry_.timestamp.lessThan(
                    now.millisecondsSinceEpoch,
                  ),
                )
                .and(HealthDataEntry_.timestamp.greaterOrEqual(start)),
          )
          .build()
          .findAsync();
  if (entries.isEmpty) return 0;
  // print(entries);
  return entries.fold<double>(0, (a, b) => a + b.value);
}
