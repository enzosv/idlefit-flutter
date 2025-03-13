import 'package:objectbox/objectbox.dart';
import 'player_stats.dart';

class PlayerStatsRepo {
  final Box<PlayerStats> box;
  static const int SINGLETON_ID = 1;

  PlayerStatsRepo({required this.box});

  /// Load PlayerStats from ObjectBox, creating default if it doesn't exist
  PlayerStats loadPlayerStats() {
    // Try to load existing PlayerStats
    PlayerStats? stats = box.get(SINGLETON_ID);

    // Create default if it doesn't exist
    if (stats == null) {
      stats = PlayerStats();
      stats.id = SINGLETON_ID;
      box.put(stats);
    }

    return stats;
  }

  /// Save PlayerStats to ObjectBox
  void savePlayerStats(PlayerStats stats) {
    box.put(stats);
  }
}
