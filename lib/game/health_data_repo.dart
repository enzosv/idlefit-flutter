import 'package:idlefit/game/health_data_entry.dart';
import 'package:idlefit/objectbox.g.dart';

class HealthDataRepo {
  final Box<HealthDataEntry> box;

  HealthDataRepo({required this.box});

  Future<double> total(String type) async {
    return box
        .query(HealthDataEntry_.type.equals(type))
        .build()
        .property(HealthDataEntry_.value)
        .sum();
  }

  Future<double> newStats(String type, int since) async {
    return box
        .query(
          HealthDataEntry_.type
              .equals(type)
              .and(HealthDataEntry_.recordedAt.greaterThan(since)),
        )
        .build()
        .property(HealthDataEntry_.value)
        .sum();
  }

  Future<double> healthForDay(String type, DateTime day) async {
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

  /// Get the latest saved timestamp
  Future<DateTime?> latestEntryDate() async {
    final entry =
        await box
            .query()
            .order(HealthDataEntry_.timestamp, flags: Order.descending)
            .build()
            .findFirstAsync();
    if (entry == null || entry.timestamp == 0) {
      return null;
    }
    print("latest is ${entry.timestamp}");
    return DateTime.fromMillisecondsSinceEpoch(entry.timestamp);
  }
}
