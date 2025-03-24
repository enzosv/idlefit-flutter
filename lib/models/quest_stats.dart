import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:idlefit/main.dart';
import 'package:idlefit/models/quest_repo.dart';
import 'package:idlefit/objectbox.g.dart';
import 'package:objectbox/objectbox.dart';

@Entity()
class QuestStats {
  @Id()
  int id = 0;

  int dayTimestamp = 0;
  int action;
  int unit;
  double value = 0.0;

  QuestStats({required this.action, required this.unit, this.dayTimestamp = 0});

  QuestAction get questAction => QuestAction.values[action];
  QuestUnit get questUnit => QuestUnit.values[unit];

  String get description {
    switch ((questAction, questUnit)) {
      case (QuestAction.tap, QuestUnit.generator):
        return 'Generators tapped';
      case (QuestAction.watch, QuestUnit.ad):
        return 'Ads watched';
      case (QuestAction.purchase, QuestUnit.generator):
        return 'Generators purchased';
      case (QuestAction.upgrade, QuestUnit.generator):
        return 'Generators upgraded';
      case (QuestAction.tap, QuestUnit.shopItem):
        return 'Shop items tapped';
      case (QuestAction.upgrade, QuestUnit.shopItem):
        return 'Shop items upgraded';
      default:
        assert(
          false,
          'unhandled action: ${questAction.name}, unit: ${questUnit.name} ',
        );
        return '';
    }
  }
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

    final newStats = QuestStats(
      action: action.index,
      unit: unit.index,
      dayTimestamp: dayTimestamp,
    );
    box.put(newStats);
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
