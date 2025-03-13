import 'package:objectbox/objectbox.dart';

@Entity()
class GameStats {
  @Id()
  int id = 0;

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
  double totalSteps = 0;
  double totalCalories = 0;
  double totalExerciseMinutes = 0;

  // Last updated timestamp
  int lastUpdated = 0;

  GameStats();

  // Convert from a map (useful when migrating from other storage methods)
  GameStats.fromMap(Map<String, dynamic> map) {
    manualGeneratorClicks = map['manual_generator_clicks'] ?? 0;
    adViewCount = map['ad_view_count'] ?? 0;
    generatorsPurchased = map['generators_purchased'] ?? 0;
    generatorsUpgraded = map['generators_upgraded'] ?? 0;
    generatorsUnlocked = map['generators_unlocked'] ?? 0;
    shopItemsUpgraded = map['shop_items_upgraded'] ?? 0;
    passiveCoinsEarned = map['passive_coins_earned'] ?? 0.0;
    manualCoinsEarned = map['manual_coins_earned'] ?? 0.0;
    totalSteps = map['total_steps'] ?? 0.0;
    totalCalories = map['total_calories'] ?? 0.0;
    totalExerciseMinutes = map['total_exercise_minutes'] ?? 0.0;
    lastUpdated = map['last_updated'] ?? DateTime.now().millisecondsSinceEpoch;
  }

  // Convert to a map (useful for display or exporting)
  Map<String, dynamic> toMap() {
    return {
      'manual_generator_clicks': manualGeneratorClicks,
      'ad_view_count': adViewCount,
      'generators_purchased': generatorsPurchased,
      'generators_upgraded': generatorsUpgraded,
      'generators_unlocked': generatorsUnlocked,
      'shop_items_upgraded': shopItemsUpgraded,
      'passive_coins_earned': passiveCoinsEarned,
      'manual_coins_earned': manualCoinsEarned,
      'total_steps': totalSteps,
      'total_calories': totalCalories,
      'total_exercise_minutes': totalExerciseMinutes,
      'last_updated': lastUpdated,
    };
  }

  // Update the timestamp
  void updateTimestamp() {
    lastUpdated = DateTime.now().millisecondsSinceEpoch;
  }
}
