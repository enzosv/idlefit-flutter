import 'package:objectbox/objectbox.dart';

enum StatsPeriod { unknown, daily, weekly, monthly }

@Entity()
class TimeBasedStats {
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

  // Game statistics
  int manualGeneratorClicks = 0;
  int adViewCount = 0;
  int generatorsPurchased = 0;
  int generatorsUpgraded = 0;
  int generatorsUnlocked = 0;
  int shopItemsUpgraded = 0;
  double passiveCoinsEarned = 0;
  double manualCoinsEarned = 0;

  // Health metrics
  double steps = 0;
  double calories = 0;
  double exerciseMinutes = 0;

  // Last updated timestamp
  int lastUpdated = 0;

  StatsPeriod get periodType => StatsPeriod.values[periodTypeIndex];

  // Default constructor with required fields
  TimeBasedStats({
    required this.periodStartTimestamp,
    required this.periodEndTimestamp,
    required this.periodKey,
    this.periodTypeIndex = 0,
  });

  // Convert to a map (useful for display or exporting)
  Map<String, dynamic> toMap() {
    return {
      'period_start': periodStartTimestamp,
      'period_end': periodEndTimestamp,
      'period_type': periodType.toString(),
      'period_key': periodKey,
      'manual_generator_clicks': manualGeneratorClicks,
      'ad_view_count': adViewCount,
      'generators_purchased': generatorsPurchased,
      'generators_upgraded': generatorsUpgraded,
      'generators_unlocked': generatorsUnlocked,
      'shop_items_upgraded': shopItemsUpgraded,
      'passive_coins_earned': passiveCoinsEarned,
      'manual_coins_earned': manualCoinsEarned,
      'steps': steps,
      'calories': calories,
      'exercise_minutes': exerciseMinutes,
      'last_updated': lastUpdated,
    };
  }

  // Update the timestamp
  void updateTimestamp() {
    lastUpdated = DateTime.now().millisecondsSinceEpoch;
  }

  // Get total coins earned
  double get totalCoinsEarned => passiveCoinsEarned + manualCoinsEarned;
}
