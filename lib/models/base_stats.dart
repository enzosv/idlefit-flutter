import 'package:objectbox/objectbox.dart';

/// Base class for statistics tracking
/// Contains common fields and methods used by both GameStats and TimeBasedStats
abstract class BaseStats {
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

  // Get total coins earned
  double get totalCoinsEarned => passiveCoinsEarned + manualCoinsEarned;

  // Update the timestamp
  void updateTimestamp() {
    lastUpdated = DateTime.now().millisecondsSinceEpoch;
  }

  // Convert to a map (useful for display or exporting)
  Map<String, dynamic> toBaseMap() {
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

  // Abstract method to be implemented by subclasses
  Map<String, dynamic> toMap();
}
