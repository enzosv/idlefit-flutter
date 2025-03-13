import 'package:objectbox/objectbox.dart';
import 'package:idlefit/models/base_stats.dart';

/// Base repository class for statistics
/// Contains common methods used by both GameStatsRepo and TimeBasedStatsRepo
abstract class BaseStatsRepo<T extends BaseStats> {
  final Box<T> _box;

  BaseStatsRepo({required Box<T> box}) : _box = box;

  // Save stats to the database
  void saveStats(T stats) {
    stats.updateTimestamp();
    _box.put(stats);
  }

  // Get all stats
  List<T> getAllStats() {
    final query = _box.query().build();
    final allStats = query.find();
    query.close();
    return allStats;
  }

  // Delete all stats
  void deleteAllStats() {
    _box.removeAll();
  }
}
