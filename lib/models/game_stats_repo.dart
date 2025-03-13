import 'package:idlefit/models/game_stats.dart';
import 'package:idlefit/models/base_stats_repo.dart';
import 'package:objectbox/objectbox.dart';

class GameStatsRepo extends BaseStatsRepo<GameStats> {
  GameStatsRepo({required Box<GameStats> box}) : super(box: box);

  // Get or create stats
  GameStats getOrCreateStats() {
    final allStats = getAllStats();

    if (allStats.isNotEmpty) {
      return allStats.first;
    } else {
      final stats = GameStats();
      stats.updateTimestamp();
      saveStats(stats);
      return stats;
    }
  }

  // Reset stats
  void resetStats() {
    deleteAllStats();
    getOrCreateStats();
  }

  // Get stats for a specific time period (useful for future features)
  GameStats getStatsForPeriod(DateTime startDate, DateTime endDate) {
    // This is a placeholder for future functionality
    // You would need to store daily stats to implement this properly
    return getOrCreateStats();
  }
}
