import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:idlefit/main.dart';
import 'package:idlefit/models/quest_repo.dart';
import 'package:idlefit/objectbox.g.dart';
import 'package:objectbox/objectbox.dart';

@Entity()
class QuestStats {
  @Id()
  int id = 0;

  int dayTimestamp;
  int action;
  int unit;
  double value;

  QuestStats(this.dayTimestamp, this.action, this.unit, this.value);
}

class QuestStatsRepository {
  final Box<QuestStats> box;

  QuestStatsRepository(this.box);

  Future<QuestStats> _getOrCreateQuestStats(
    QuestAction action,
    QuestUnit unit,
    int dayTimestamp,
  ) async {
    final existing =
        await box
            .query(
              QuestStats_.dayTimestamp
                  .equals(dayTimestamp)
                  .and(QuestStats_.action.equals(action.index))
                  .and(QuestStats_.unit.equals(unit.index)),
            )
            .build()
            .findFirstAsync();

    if (existing != null) {
      return existing;
    }

    final newStats = QuestStats(dayTimestamp, action.index, unit.index, 0.0);
    await box.putAsync(newStats);
    return newStats;
  }

  /// Returns the difference in progress
  /// For health stats
  Future<double> setProgress(
    QuestAction action,
    QuestUnit unit,
    int dayTimestamp,
    double value,
  ) async {
    final stats = await _getOrCreateQuestStats(action, unit, dayTimestamp);
    final oldValue = stats.value;
    if (value == oldValue) {
      return 0;
    }
    stats.value = value;
    box.putAsync(stats);
    return value - oldValue;
  }

  Future<DateTime?> firstHealthDay() async {
    final firstStep =
        await box
            .query(QuestStats_.unit.equals(QuestUnit.steps.index))
            .order(QuestStats_.dayTimestamp)
            .build()
            .findFirstAsync();
    final firstDay = firstStep?.dayTimestamp;
    return firstDay != null
        ? DateTime.fromMillisecondsSinceEpoch(firstDay)
        : null;
  }

  Future<DateTime?> lastHealthDay() async {
    final lastStep =
        await box
            .query(QuestStats_.unit.equals(QuestUnit.steps.index))
            .order(QuestStats_.dayTimestamp, flags: Order.descending)
            .build()
            .findFirstAsync();
    final lastDay = lastStep?.dayTimestamp;
    return lastDay != null
        ? DateTime.fromMillisecondsSinceEpoch(lastDay)
        : null;
  }

  Future<void> progressTowards(
    QuestAction action,
    QuestUnit unit,
    int dayTimestamp,
    double value,
  ) async {
    final stats = await _getOrCreateQuestStats(action, unit, dayTimestamp);
    stats.value += value;
    box.putAsync(stats);
  }

  Future<double> getProgress(
    QuestAction action,
    QuestUnit unit,
    int dayTimestamp,
  ) async {
    final stats = await _getOrCreateQuestStats(action, unit, dayTimestamp);
    return stats.value;
  }

  Future<double> getTotalProgress(QuestAction action, QuestUnit unit) async {
    final stats =
        await box
            .query(
              QuestStats_.action
                  .equals(action.index)
                  .and(QuestStats_.unit.equals(unit.index)),
            )
            .build()
            .findAsync();
    final progress = stats.fold(0.0, (sum, stat) => sum + stat.value);
    return progress;
  }
}

final questStatsRepositoryProvider = Provider<QuestStatsRepository>((ref) {
  final box = ref.read(objectBoxProvider).store.box<QuestStats>();
  return QuestStatsRepository(box);
});
