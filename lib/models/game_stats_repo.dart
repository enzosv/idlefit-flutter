import 'package:idlefit/models/game_stats.dart';
import 'package:objectbox/objectbox.dart';

class GameStatsRepo {
  final Box<GameStats> _box;

  GameStatsRepo({required Box<GameStats> box}) : _box = box;

  // Get the singleton instance of GameStats or create a new one if it doesn't exist
  GameStats getOrCreateStats() {
    final query = _box.query().build();
    final results = query.find();
    query.close();

    if (results.isNotEmpty) {
      return results.first;
    } else {
      final stats = GameStats();
      stats.updateTimestamp();
      _box.put(stats);
      return stats;
    }
  }

  // Save the stats to the database
  void saveStats(GameStats stats) {
    stats.updateTimestamp();
    _box.put(stats);
  }

  // Reset all stats (for testing or user-initiated reset)
  void resetStats() {
    final stats = getOrCreateStats();
    _box.remove(stats.id);

    final newStats = GameStats();
    newStats.updateTimestamp();
    _box.put(newStats);
  }

  // Get stats for a specific time period (useful for future features)
  GameStats getStatsForPeriod(DateTime startDate, DateTime endDate) {
    // This is a placeholder for future functionality
    // You would need to store daily stats to implement this properly
    return getOrCreateStats();
  }
}
