import 'package:idlefit/models/daily_quest.dart';
import 'package:idlefit/models/game_stats.dart';
import 'package:idlefit/models/game_stats_repo.dart';
import 'package:idlefit/models/time_based_stats.dart';
import 'package:idlefit/models/time_based_stats_repo.dart';
import 'package:objectbox/objectbox.dart';

class StatsService {
  final DailyQuestRepo _dailyQuestRepo;
  final GameStatsRepo _gameStatsRepo;
  final TimeBasedStatsRepo _timeBasedStatsRepo;

  // In-memory game statistics
  late GameStats _gameStats;

  // In-memory time-based statistics
  late TimeBasedStats _dailyStats;
  late TimeBasedStats _weeklyStats;
  late TimeBasedStats _monthlyStats;

  StatsService({
    required DailyQuestRepo dailyQuestRepo,
    required GameStatsRepo gameStatsRepo,
    required TimeBasedStatsRepo timeBasedStatsRepo,
  }) : _dailyQuestRepo = dailyQuestRepo,
       _gameStatsRepo = gameStatsRepo,
       _timeBasedStatsRepo = timeBasedStatsRepo {
    // Load stats from repositories
    _gameStats = _gameStatsRepo.getOrCreateStats();
    _dailyStats = _timeBasedStatsRepo.getOrCreateDailyStats();
    _weeklyStats = _timeBasedStatsRepo.getOrCreateWeeklyStats();
    _monthlyStats = _timeBasedStatsRepo.getOrCreateMonthlyStats();
  }

  // Track generator interactions
  void trackManualGeneratorClick(int generatorTier) {
    // Update all-time stats
    _gameStats.manualGeneratorClicks++;

    // Update time-based stats
    _dailyStats.manualGeneratorClicks++;
    _weeklyStats.manualGeneratorClicks++;
    _monthlyStats.manualGeneratorClicks++;

    _saveStats();
  }

  void trackGeneratorPurchase(int tier) {
    // Update all-time stats
    _gameStats.generatorsPurchased++;

    // Update time-based stats
    _dailyStats.generatorsPurchased++;
    _weeklyStats.generatorsPurchased++;
    _monthlyStats.generatorsPurchased++;

    _dailyQuestRepo.progressTowards(
      QuestAction.spend,
      QuestUnit.coins,
      0, // The actual cost is tracked elsewhere
    );
    _saveStats();
  }

  void trackGeneratorUpgrade(int tier) {
    // Update all-time stats
    _gameStats.generatorsUpgraded++;

    // Update time-based stats
    _dailyStats.generatorsUpgraded++;
    _weeklyStats.generatorsUpgraded++;
    _monthlyStats.generatorsUpgraded++;

    _dailyQuestRepo.progressTowards(
      QuestAction.spend,
      QuestUnit.coins,
      0, // The actual cost is tracked elsewhere
    );
    _saveStats();
  }

  void trackGeneratorUnlock(int tier) {
    // Update all-time stats
    _gameStats.generatorsUnlocked++;

    // Update time-based stats
    _dailyStats.generatorsUnlocked++;
    _weeklyStats.generatorsUnlocked++;
    _monthlyStats.generatorsUnlocked++;

    _dailyQuestRepo.progressTowards(
      QuestAction.spend,
      QuestUnit.space,
      0, // The actual cost is tracked elsewhere
    );
    _saveStats();
  }

  // Track shop interactions
  void trackShopItemUpgrade(int itemId) {
    // Update all-time stats
    _gameStats.shopItemsUpgraded++;

    // Update time-based stats
    _dailyStats.shopItemsUpgraded++;
    _weeklyStats.shopItemsUpgraded++;
    _monthlyStats.shopItemsUpgraded++;

    _dailyQuestRepo.progressTowards(
      QuestAction.spend,
      QuestUnit.space,
      0, // The actual cost is tracked elsewhere
    );
    _saveStats();
  }

  // Track currency earnings
  void trackPassiveCoinsEarned(double amount) {
    // Update all-time stats
    _gameStats.passiveCoinsEarned += amount;

    // Update time-based stats
    _dailyStats.passiveCoinsEarned += amount;
    _weeklyStats.passiveCoinsEarned += amount;
    _monthlyStats.passiveCoinsEarned += amount;

    // Save less frequently for passive earnings to avoid excessive writes
    if (_gameStats.passiveCoinsEarned % 1000 < amount) {
      _saveStats();
    }
  }

  void trackManualCoinsEarned(double amount) {
    // Update all-time stats
    _gameStats.manualCoinsEarned += amount;

    // Update time-based stats
    _dailyStats.manualCoinsEarned += amount;
    _weeklyStats.manualCoinsEarned += amount;
    _monthlyStats.manualCoinsEarned += amount;

    _saveStats();
  }

  // Track ad interactions
  void trackAdView() {
    // Update all-time stats
    _gameStats.adViewCount++;

    // Update time-based stats
    _dailyStats.adViewCount++;
    _weeklyStats.adViewCount++;
    _monthlyStats.adViewCount++;

    _saveStats();
  }

  // Track health metrics
  void trackHealthMetrics(
    double steps,
    double calories,
    double exerciseMinutes,
  ) {
    // Update all-time stats
    _gameStats.totalSteps += steps;
    _gameStats.totalCalories += calories;
    _gameStats.totalExerciseMinutes += exerciseMinutes;

    // Update time-based stats
    _dailyStats.steps += steps;
    _dailyStats.calories += calories;
    _dailyStats.exerciseMinutes += exerciseMinutes;

    _weeklyStats.steps += steps;
    _weeklyStats.calories += calories;
    _weeklyStats.exerciseMinutes += exerciseMinutes;

    _monthlyStats.steps += steps;
    _monthlyStats.calories += calories;
    _monthlyStats.exerciseMinutes += exerciseMinutes;

    _dailyQuestRepo.progressTowards(QuestAction.walk, QuestUnit.steps, steps);
    _dailyQuestRepo.progressTowards(
      QuestAction.burn,
      QuestUnit.calories,
      calories,
    );

    _saveStats();
  }

  // Get all-time statistics as a map for display
  Map<String, dynamic> getStats() {
    return _gameStats.toMap();
  }

  // Get daily statistics
  Map<String, dynamic> getDailyStats() {
    // Check if we need to roll over to a new day
    _checkAndUpdatePeriods();
    return _dailyStats.toMap();
  }

  // Get weekly statistics
  Map<String, dynamic> getWeeklyStats() {
    // Check if we need to roll over to a new week
    _checkAndUpdatePeriods();
    return _weeklyStats.toMap();
  }

  // Get monthly statistics
  Map<String, dynamic> getMonthlyStats() {
    // Check if we need to roll over to a new month
    _checkAndUpdatePeriods();
    return _monthlyStats.toMap();
  }

  // Get stats for the last N days
  List<Map<String, dynamic>> getStatsForLastNDays(int days) {
    final statsList = _timeBasedStatsRepo.getStatsForLastNDays(days);
    return statsList.map((stats) => stats.toMap()).toList();
  }

  // Get stats for the last N weeks
  List<Map<String, dynamic>> getStatsForLastNWeeks(int weeks) {
    final statsList = _timeBasedStatsRepo.getStatsForLastNWeeks(weeks);
    return statsList.map((stats) => stats.toMap()).toList();
  }

  // Get stats for the last N months
  List<Map<String, dynamic>> getStatsForLastNMonths(int months) {
    final statsList = _timeBasedStatsRepo.getStatsForLastNMonths(months);
    return statsList.map((stats) => stats.toMap()).toList();
  }

  // Reset all stats (for testing or user-initiated reset)
  void resetStats() {
    _gameStatsRepo.resetStats();
    _gameStats = _gameStatsRepo.getOrCreateStats();

    // We don't reset time-based stats here, as they're historical
  }

  // Check if we need to roll over to new time periods
  void _checkAndUpdatePeriods() {
    final currentDailyStats = _timeBasedStatsRepo.getOrCreateDailyStats();
    if (currentDailyStats.periodKey != _dailyStats.periodKey) {
      // We've rolled over to a new day
      _dailyStats = currentDailyStats;
    }

    final currentWeeklyStats = _timeBasedStatsRepo.getOrCreateWeeklyStats();
    if (currentWeeklyStats.periodKey != _weeklyStats.periodKey) {
      // We've rolled over to a new week
      _weeklyStats = currentWeeklyStats;
    }

    final currentMonthlyStats = _timeBasedStatsRepo.getOrCreateMonthlyStats();
    if (currentMonthlyStats.periodKey != _monthlyStats.periodKey) {
      // We've rolled over to a new month
      _monthlyStats = currentMonthlyStats;
    }
  }

  // Private helper to save all stats
  void _saveStats() {
    _gameStatsRepo.saveStats(_gameStats);
    _timeBasedStatsRepo.saveStats(_dailyStats);
    _timeBasedStatsRepo.saveStats(_weeklyStats);
    _timeBasedStatsRepo.saveStats(_monthlyStats);
  }
}
