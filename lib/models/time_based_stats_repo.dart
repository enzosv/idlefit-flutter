import 'package:idlefit/models/time_based_stats.dart';
import 'package:idlefit/models/base_stats_repo.dart';
import 'package:objectbox/objectbox.dart';
import 'package:intl/intl.dart';

class TimeBasedStatsRepo extends BaseStatsRepo<TimeBasedStats> {
  TimeBasedStatsRepo({required Box<TimeBasedStats> box}) : super(box: box);

  // Get or create stats for the current day
  TimeBasedStats getOrCreateDailyStats() {
    final today = _getStartOfDay(DateTime.now());
    final tomorrow = today.add(const Duration(days: 1));
    final key = DateFormat('yyyy-MM-dd').format(today);

    return _getOrCreateStats(
      today.millisecondsSinceEpoch,
      tomorrow.millisecondsSinceEpoch,
      StatsPeriod.daily,
      key,
    );
  }

  // Get or create stats for the current week
  TimeBasedStats getOrCreateWeeklyStats() {
    final now = DateTime.now();
    final startOfWeek = _getStartOfWeek(now);
    final endOfWeek = startOfWeek.add(const Duration(days: 7));
    final key = 'W${DateFormat('w-yyyy').format(startOfWeek)}';

    return _getOrCreateStats(
      startOfWeek.millisecondsSinceEpoch,
      endOfWeek.millisecondsSinceEpoch,
      StatsPeriod.weekly,
      key,
    );
  }

  // Get or create stats for the current month
  TimeBasedStats getOrCreateMonthlyStats() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth =
        (now.month < 12)
            ? DateTime(now.year, now.month + 1, 1)
            : DateTime(now.year + 1, 1, 1);
    final key = DateFormat('MM-yyyy').format(startOfMonth);

    return _getOrCreateStats(
      startOfMonth.millisecondsSinceEpoch,
      endOfMonth.millisecondsSinceEpoch,
      StatsPeriod.monthly,
      key,
    );
  }

  // Helper method to get or create stats for a specific period
  TimeBasedStats _getOrCreateStats(
    int startTimestamp,
    int endTimestamp,
    StatsPeriod periodType,
    String key,
  ) {
    final allStats = getAllStats();

    // Find matching stats manually
    final existingStats = allStats.where(
      (stats) => stats.periodKey == key && stats.periodType == periodType,
    );

    if (existingStats.isNotEmpty) {
      return existingStats.first;
    } else {
      final stats = TimeBasedStats(
        periodStartTimestamp: startTimestamp,
        periodEndTimestamp: endTimestamp,
        periodTypeIndex: periodType.index,
        periodKey: key,
      );
      stats.updateTimestamp();
      saveStats(stats);
      return stats;
    }
  }

  // Get stats for a specific day
  TimeBasedStats? getStatsForDay(DateTime date) {
    final day = _getStartOfDay(date);
    final key = DateFormat('yyyy-MM-dd').format(day);

    return _getStatsByKey(key, StatsPeriod.daily);
  }

  // Get stats for a specific week
  TimeBasedStats? getStatsForWeek(DateTime date) {
    final startOfWeek = _getStartOfWeek(date);
    final key = 'W${DateFormat('w-yyyy').format(startOfWeek)}';

    return _getStatsByKey(key, StatsPeriod.weekly);
  }

  // Get stats for a specific month
  TimeBasedStats? getStatsForMonth(DateTime date) {
    final startOfMonth = DateTime(date.year, date.month, 1);
    final key = DateFormat('MM-yyyy').format(startOfMonth);

    return _getStatsByKey(key, StatsPeriod.monthly);
  }

  // Helper method to get stats by key and period type
  TimeBasedStats? _getStatsByKey(String key, StatsPeriod periodType) {
    final allStats = getAllStats();

    // Find matching stats manually
    final matchingStats = allStats.where(
      (stats) => stats.periodKey == key && stats.periodType == periodType,
    );

    return matchingStats.isNotEmpty ? matchingStats.first : null;
  }

  // Get stats for the last N days
  List<TimeBasedStats> getStatsForLastNDays(int days) {
    final now = DateTime.now();
    final startDate = _getStartOfDay(now.subtract(Duration(days: days - 1)));

    return _getStatsForPeriod(
      startDate.millisecondsSinceEpoch,
      StatsPeriod.daily,
    );
  }

  // Get stats for the last N weeks
  List<TimeBasedStats> getStatsForLastNWeeks(int weeks) {
    final now = DateTime.now();
    final startDate = _getStartOfWeek(
      now.subtract(Duration(days: 7 * (weeks - 1))),
    );

    return _getStatsForPeriod(
      startDate.millisecondsSinceEpoch,
      StatsPeriod.weekly,
    );
  }

  // Get stats for the last N months
  List<TimeBasedStats> getStatsForLastNMonths(int months) {
    final now = DateTime.now();
    DateTime startDate = now;

    for (int i = 0; i < months - 1; i++) {
      startDate = DateTime(
        startDate.month > 1 ? startDate.year : startDate.year - 1,
        startDate.month > 1 ? startDate.month - 1 : 12,
        1,
      );
    }

    return _getStatsForPeriod(
      startDate.millisecondsSinceEpoch,
      StatsPeriod.monthly,
    );
  }

  // Helper method to get stats for a period starting from a timestamp
  List<TimeBasedStats> _getStatsForPeriod(
    int startTimestamp,
    StatsPeriod periodType,
  ) {
    final allStats = getAllStats();

    // Find matching stats manually and sort them
    final matchingStats =
        allStats
            .where(
              (stats) =>
                  stats.periodStartTimestamp >= startTimestamp &&
                  stats.periodType == periodType,
            )
            .toList();

    // Sort by start timestamp
    matchingStats.sort(
      (a, b) => a.periodStartTimestamp.compareTo(b.periodStartTimestamp),
    );

    return matchingStats;
  }

  // Helper method to get the start of a day (midnight)
  DateTime _getStartOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  // Helper method to get the start of a week (Monday)
  DateTime _getStartOfWeek(DateTime date) {
    final dayOfWeek = date.weekday;
    return _getStartOfDay(date.subtract(Duration(days: dayOfWeek - 1)));
  }
}
