import 'package:idlefit/models/currency.dart';
import 'package:idlefit/repositories/currency_repo.dart';
import 'package:idlefit/models/time_based_stats.dart';
import 'package:idlefit/repositories/time_based_stats_repo.dart';
import 'package:idlefit/models/coin_generator.dart';
import 'package:idlefit/models/shop_items.dart';
import 'package:idlefit/repositories/shop_items_repo.dart';
import 'package:idlefit/models/daily_quest.dart';
import 'package:idlefit/services/stats_aggregation_service.dart';
import 'package:objectbox/objectbox.dart';

/// A unified service for managing all data repositories
/// This reduces redundancy by centralizing repository access
class DataService {
  // Repositories
  final CurrencyRepo currencyRepo;
  final TimeBasedStatsRepo timeBasedStatsRepo;
  final CoinGeneratorRepo generatorRepo;
  final ShopItemsRepo shopItemRepo;
  final DailyQuestRepo dailyQuestRepo;

  // Services
  late final StatsAggregationService statsAggregationService;

  // In-memory cache
  late TimeBasedStats _dailyStats;
  late TimeBasedStats _weeklyStats;
  late TimeBasedStats _monthlyStats;
  late Map<CurrencyType, Currency> _currencies;
  late List<CoinGenerator> _generators;
  late List<ShopItem> _shopItems;

  DataService({
    required this.currencyRepo,
    required this.timeBasedStatsRepo,
    required this.generatorRepo,
    required this.shopItemRepo,
    required this.dailyQuestRepo,
  }) {
    statsAggregationService = StatsAggregationService(
      timeBasedStatsRepo: timeBasedStatsRepo,
    );
  }

  /// Initialize all data
  Future<void> initialize() async {
    // Load stats
    _dailyStats = timeBasedStatsRepo.getOrCreateDailyStats();
    _weeklyStats = timeBasedStatsRepo.getOrCreateWeeklyStats();
    _monthlyStats = timeBasedStatsRepo.getOrCreateMonthlyStats();

    // Load currencies
    currencyRepo.ensureDefaultCurrencies();
    _currencies = currencyRepo.loadCurrencies();

    // Load generators and shop items
    _generators = await generatorRepo.parseCoinGenerators(
      'assets/coin_generators.json',
    );
    _shopItems = await shopItemRepo.parseShopItems('assets/shop_items.json');
  }

  // Currency access
  Currency getCurrency(CurrencyType type) {
    return _currencies[type] ?? currencyRepo.getOrCreate(type);
  }

  void saveCurrencies() {
    currencyRepo.saveCurrencies(_currencies.values.toList());
  }

  // Stats access
  Map<String, dynamic> getAllTimeStats() {
    return statsAggregationService.getAllTimeStats();
  }

  TimeBasedStats get dailyStats => _dailyStats;
  TimeBasedStats get weeklyStats => _weeklyStats;
  TimeBasedStats get monthlyStats => _monthlyStats;

  void saveStats() {
    timeBasedStatsRepo.saveStats(_dailyStats);
    timeBasedStatsRepo.saveStats(_weeklyStats);
    timeBasedStatsRepo.saveStats(_monthlyStats);
  }

  // Generator access
  List<CoinGenerator> get generators => _generators;

  void saveGenerator(CoinGenerator generator) {
    generatorRepo.saveCoinGenerator(generator);
  }

  // Shop items access
  List<ShopItem> get shopItems => _shopItems;

  void saveShopItem(ShopItem item) {
    shopItemRepo.saveShopItem(item);
  }

  // Check for period rollovers
  void checkAndUpdatePeriods() {
    final currentDailyStats = timeBasedStatsRepo.getOrCreateDailyStats();
    if (currentDailyStats.periodKey != _dailyStats.periodKey) {
      // We've rolled over to a new day
      _dailyStats = currentDailyStats;
    }

    final currentWeeklyStats = timeBasedStatsRepo.getOrCreateWeeklyStats();
    if (currentWeeklyStats.periodKey != _weeklyStats.periodKey) {
      // We've rolled over to a new week
      _weeklyStats = currentWeeklyStats;
    }

    final currentMonthlyStats = timeBasedStatsRepo.getOrCreateMonthlyStats();
    if (currentMonthlyStats.periodKey != _monthlyStats.periodKey) {
      // We've rolled over to a new month
      _monthlyStats = currentMonthlyStats;
    }
  }

  // Get stats for time periods
  List<Map<String, dynamic>> getStatsForLastNDays(int days) {
    final statsList = timeBasedStatsRepo.getStatsForLastNDays(days);
    return statsList.map((stats) => stats.toMap()).toList();
  }

  List<Map<String, dynamic>> getStatsForLastNWeeks(int weeks) {
    final statsList = timeBasedStatsRepo.getStatsForLastNWeeks(weeks);
    return statsList.map((stats) => stats.toMap()).toList();
  }

  List<Map<String, dynamic>> getStatsForLastNMonths(int months) {
    final statsList = timeBasedStatsRepo.getStatsForLastNMonths(months);
    return statsList.map((stats) => stats.toMap()).toList();
  }

  // Get stats for a specific time range
  Map<String, dynamic> getStatsForTimeRange(
    DateTime startDate,
    DateTime endDate,
  ) {
    return statsAggregationService.getStatsForTimeRange(startDate, endDate);
  }

  // Reset all stats
  void resetStats() {
    timeBasedStatsRepo.deleteAllStats();

    // Recreate the current period stats
    _dailyStats = timeBasedStatsRepo.getOrCreateDailyStats();
    _weeklyStats = timeBasedStatsRepo.getOrCreateWeeklyStats();
    _monthlyStats = timeBasedStatsRepo.getOrCreateMonthlyStats();
  }
}
