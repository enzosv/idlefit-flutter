import 'package:objectbox/objectbox.dart';
import 'package:idlefit/models/base_stats.dart';

enum StatsPeriod { unknown, daily, weekly, monthly }

@Entity()
class TimeBasedStats extends BaseStats {
  @Id()
  int id = 0;

  // Time period identification
  int
  periodStartTimestamp; // Start of the period (midnight for daily, start of week, start of month)
  int periodEndTimestamp; // End of the period
  int periodTypeIndex =
      StatsPeriod.unknown.index; // Type of period (daily, weekly, monthly)
  String
  periodKey; // Unique identifier for the period (e.g., "2023-05-15" for daily)

  // Health metrics - renamed to avoid conflict with BaseStats
  double steps = 0;
  double calories = 0;
  double exerciseMinutes = 0;

  StatsPeriod get periodType => StatsPeriod.values[periodTypeIndex];

  // Default constructor with required fields
  TimeBasedStats({
    required this.periodStartTimestamp,
    required this.periodEndTimestamp,
    required this.periodKey,
    this.periodTypeIndex = 0,
  });

  // Convert to a map (useful for display or exporting)
  @override
  Map<String, dynamic> toMap() {
    final baseMap = toBaseMap();
    return {
      ...baseMap,
      'period_start': periodStartTimestamp,
      'period_end': periodEndTimestamp,
      'period_type': periodType.toString(),
      'period_key': periodKey,
      'steps': steps,
      'calories': calories,
      'exercise_minutes': exerciseMinutes,
    };
  }
}
