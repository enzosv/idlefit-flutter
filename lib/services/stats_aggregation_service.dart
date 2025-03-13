import 'package:idlefit/models/time_based_stats.dart';
import 'package:idlefit/repositories/time_based_stats_repo.dart';

/// Service that aggregates TimeBasedStats data to provide all-time statistics
/// This replaces the need for a separate GameStats class
class StatsAggregationService {
  final TimeBasedStatsRepo _timeBasedStatsRepo;

  StatsAggregationService({required TimeBasedStatsRepo timeBasedStatsRepo})
    : _timeBasedStatsRepo = timeBasedStatsRepo;

  /// Get all-time statistics by aggregating all TimeBasedStats records
  Map<String, dynamic> getAllTimeStats() {
    final allStats = _timeBasedStatsRepo.getAllStats();

    // Initialize result with zeros
    final result = <String, dynamic>{
      'manual_generator_clicks': 0,
      'ad_view_count': 0,
      'generators_purchased': 0,
      'generators_upgraded': 0,
      'generators_unlocked': 0,
      'shop_items_upgraded': 0,
      'passive_coins_earned': 0.0,
      'manual_coins_earned': 0.0,
      'total_steps': 0.0,
      'total_calories': 0.0,
      'total_exercise_minutes': 0.0,
      'last_updated': 0,
    };

    // Aggregate metrics across all time periods
    for (final stats in allStats) {
      result['manual_generator_clicks'] += stats.manualGeneratorClicks;
      result['ad_view_count'] += stats.adViewCount;
      result['generators_purchased'] += stats.generatorsPurchased;
      result['generators_upgraded'] += stats.generatorsUpgraded;
      result['generators_unlocked'] += stats.generatorsUnlocked;
      result['shop_items_upgraded'] += stats.shopItemsUpgraded;
      result['passive_coins_earned'] += stats.passiveCoinsEarned;
      result['manual_coins_earned'] += stats.manualCoinsEarned;

      // For health metrics, use the period-specific fields
      result['total_steps'] += stats.steps;
      result['total_calories'] += stats.calories;
      result['total_exercise_minutes'] += stats.exerciseMinutes;

      // Keep track of the most recent update
      if (stats.lastUpdated > result['last_updated']) {
        result['last_updated'] = stats.lastUpdated;
      }
    }

    return result;
  }

  /// Get statistics for a specific time range by aggregating TimeBasedStats
  Map<String, dynamic> getStatsForTimeRange(
    DateTime startDate,
    DateTime endDate,
  ) {
    final startTimestamp = startDate.millisecondsSinceEpoch;
    final endTimestamp = endDate.millisecondsSinceEpoch;

    final allStats = _timeBasedStatsRepo.getAllStats();
    final relevantStats =
        allStats
            .where(
              (stats) =>
                  stats.periodStartTimestamp >= startTimestamp &&
                  stats.periodEndTimestamp <= endTimestamp,
            )
            .toList();

    // Initialize result with zeros
    final result = <String, dynamic>{
      'manual_generator_clicks': 0,
      'ad_view_count': 0,
      'generators_purchased': 0,
      'generators_upgraded': 0,
      'generators_unlocked': 0,
      'shop_items_upgraded': 0,
      'passive_coins_earned': 0.0,
      'manual_coins_earned': 0.0,
      'total_steps': 0.0,
      'total_calories': 0.0,
      'total_exercise_minutes': 0.0,
      'period_start': startTimestamp,
      'period_end': endTimestamp,
      'last_updated': 0,
    };

    // Aggregate metrics for the relevant time periods
    for (final stats in relevantStats) {
      result['manual_generator_clicks'] += stats.manualGeneratorClicks;
      result['ad_view_count'] += stats.adViewCount;
      result['generators_purchased'] += stats.generatorsPurchased;
      result['generators_upgraded'] += stats.generatorsUpgraded;
      result['generators_unlocked'] += stats.generatorsUnlocked;
      result['shop_items_upgraded'] += stats.shopItemsUpgraded;
      result['passive_coins_earned'] += stats.passiveCoinsEarned;
      result['manual_coins_earned'] += stats.manualCoinsEarned;

      // For health metrics, use the period-specific fields
      result['total_steps'] += stats.steps;
      result['total_calories'] += stats.calories;
      result['total_exercise_minutes'] += stats.exerciseMinutes;

      // Keep track of the most recent update
      if (stats.lastUpdated > result['last_updated']) {
        result['last_updated'] = stats.lastUpdated;
      }
    }

    return result;
  }
}
