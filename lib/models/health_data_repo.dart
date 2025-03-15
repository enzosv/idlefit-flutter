import 'package:health/health.dart';
import 'package:idlefit/models/health_data_entry.dart';
import 'package:idlefit/objectbox.g.dart';

class HealthStats {
  double steps = 0;
  double calories = 0;
  double exerciseMinutes = 0;
}

class HealthDataRepo {
  final Box<HealthDataEntry> box;

  HealthDataRepo({required this.box});

  Future<HealthStats> total() async {
    final query = box.query().build();
    final stats = await _groupQuery(query);
    query.close();
    return stats;
  }

  Future<List<HealthDataEntry>> newFromList(
    List<HealthDataEntry> entries,
    DateTime since,
  ) async {
    // query for entries that are newer than the since date
    final existing =
        await box
            .query(
              HealthDataEntry_.timestamp.greaterOrEqual(
                since.millisecondsSinceEpoch,
              ),
            )
            .build()
            .findAsync();
    if (existing.isEmpty) {
      // everything is new
      return entries;
    }
    final uniqueKeys = existing.map((e) => e.uniqueKey);
    return entries.where((e) => !uniqueKeys.contains(e.uniqueKey)).toList();
  }

  Future<HealthStats> today(DateTime day) async {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(Duration(days: 1));
    final query =
        box
            .query(
              HealthDataEntry_.timestamp
                  .greaterOrEqual(start.millisecondsSinceEpoch)
                  .and(
                    HealthDataEntry_.timestamp.lessThan(
                      end.millisecondsSinceEpoch,
                    ),
                  ),
            )
            .build();
    final stats = await _groupQuery(query);
    query.close();
    return stats;
  }

  Future<HealthStats> _groupQuery(Query<HealthDataEntry> query) async {
    final stats = HealthStats();
    for (final entry in query.find()) {
      if (entry.type == HealthDataType.STEPS.name) {
        stats.steps += entry.value;
      } else if (entry.type == HealthDataType.EXERCISE_TIME.name) {
        stats.exerciseMinutes += entry.value;
      } else if (entry.type == HealthDataType.ACTIVE_ENERGY_BURNED.name) {
        stats.calories += entry.value;
      }
    }
    return stats;
  }

  Future<HealthStats> newStats(int since) async {
    final query =
        box.query(HealthDataEntry_.recordedAt.greaterThan(since)).build();
    final stats = await _groupQuery(query);
    query.close();
    return stats;
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
    return DateTime.fromMillisecondsSinceEpoch(entry.timestamp);
  }

  Future<DateTime?> earliestEntryDate() async {
    final entry =
        await box
            .query()
            .order(HealthDataEntry_.timestamp)
            .build()
            .findFirstAsync();
    if (entry == null || entry.timestamp == 0) {
      return null;
    }
    return DateTime.fromMillisecondsSinceEpoch(entry.timestamp);
  }

  Future<DateTime> syncStart() async {
    final earliest = await earliestEntryDate();
    final now = DateTime.now();
    if (earliest == null) {
      // first time: start midnight today
      return DateTime(now.year, now.month, now.day);
    }

    DateTime start = await latestEntryDate() ?? now;
    start = start.subtract(Duration(hours: 24)); // handle late recordings
    if (earliest.isBefore(start)) {
      return start;
    }
    // do not fetch before earliest
    return earliest;
  }
}
