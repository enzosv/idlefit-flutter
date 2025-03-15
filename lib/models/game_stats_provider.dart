import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:idlefit/main.dart';
import 'package:idlefit/models/daily_quest.dart';
import 'package:idlefit/models/game_stats.dart';
import 'package:idlefit/objectbox.g.dart';

class GameStatsNotifier extends StateNotifier<GameStats> {
  final Box<GameStats> box;
  GameStatsNotifier(this.box, super.state);

  Future<GameStats> _getToday() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final existing = box.get(today);
    if (existing != null) {
      return existing;
    }
    return GameStats()..dayTimestamp = today;
  }

  Future<void> progressTowards(
    QuestAction action,
    QuestUnit unit,
    double progress,
  ) async {
    final today = await _getToday();

    switch (action) {
      case QuestAction.purchase:
        switch (unit) {
          case QuestUnit.generator:
            today.generatorsPurchased += progress.toInt();
            break;
          case QuestUnit.shopItem:
            today.shopItemsPurchased += progress.toInt();
            break;
          default:
            throw UnimplementedError('Unknown unit: $unit');
        }
        break;
      case QuestAction.upgrade:
        assert(unit == QuestUnit.generator, "only generators can be upgraded");
        today.generatorsUpgraded += progress.toInt();
        break;
      case QuestAction.tap:
        assert(unit == QuestUnit.generator, "only generators can be tapped");
        today.manualTaps += progress.toInt();
      default:
        throw UnimplementedError('Unknown action: $action');
    }
    state = today;
    box.putAsync(today);
  }
}

final gameStatsProvider = StateNotifierProvider<GameStatsNotifier, GameStats>((
  ref,
) {
  return GameStatsNotifier(
    ref.read(objectBoxProvider).store.box<GameStats>(),
    GameStats(),
  );
});
