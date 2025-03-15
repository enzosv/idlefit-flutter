import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:idlefit/main.dart';
import 'package:idlefit/models/daily_quest.dart';
import 'package:idlefit/models/game_stats.dart';
import 'package:idlefit/objectbox.g.dart';

const _validActionUnits = {
  QuestAction.purchase: {QuestUnit.generator},
  QuestAction.upgrade: {QuestUnit.generator, QuestUnit.shopItem},
  QuestAction.tap: {QuestUnit.generator},
  QuestAction.watch: {QuestUnit.ad},
  QuestAction.burn: {QuestUnit.calories},
  QuestAction.collect: {QuestUnit.coin, QuestUnit.space, QuestUnit.energy},
  QuestAction.spend: {QuestUnit.coin, QuestUnit.space, QuestUnit.energy},
};

class GameStatsNotifier extends StateNotifier<GameStats> {
  final Box<GameStats> box;
  GameStatsNotifier(this.box, super.state);

  Future<GameStats> _getToday() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    return box.get(today) ?? (GameStats()..dayTimestamp = today);
  }

  Future<GameStats> get total async {
    final allStats = await box.getAllAsync();
    final totaled = GameStats();
    for (final stat in allStats) {
      totaled
        ..generatorsPurchased += stat.generatorsPurchased
        ..generatorsUpgraded += stat.generatorsUpgraded
        ..shopItemsPurchased += stat.shopItemsPurchased
        ..generatorsTapped += stat.generatorsTapped
        ..adsWatched += stat.adsWatched
        ..caloriesBurned += stat.caloriesBurned
        ..coinsCollected += stat.coinsCollected
        ..spaceCollected += stat.spaceCollected
        ..energyCollected += stat.energyCollected;
    }
    return totaled;
  }

  Future<GameStats> statsFor(DateTime date) async {
    final dayTimestamp =
        DateTime(date.year, date.month, date.day).millisecondsSinceEpoch;
    return await box.getAsync(dayTimestamp) ?? GameStats();
  }

  Future<void> progressTowards(
    QuestAction action,
    QuestUnit unit,
    double progress,
  ) async {
    // Validate action-unit combination
    if (!_validActionUnits[action]!.contains(unit)) {
      throw ArgumentError('Invalid action-unit combination: $action-$unit');
    }

    switch (action) {
      case QuestAction.purchase:
        assert(unit == QuestUnit.generator, "only generators can be purchased");
        today.generatorsPurchased += progress.toInt();
        break;
      case QuestAction.upgrade:
        switch (unit) {
          case QuestUnit.generator:
            today.generatorsUpgraded += progress.toInt();
            break;
          case QuestUnit.shopItem:
            today.shopItemsPurchased += progress.toInt();
            break;
          default:
            throw UnimplementedError('Unknown unit: $unit');
        }
      case QuestAction.tap:
        assert(unit == QuestUnit.generator, "only generators can be tapped");
        today.generatorsTapped += progress.toInt();
        break;
      case QuestAction.watch:
        assert(unit == QuestUnit.ad, "only ads can be watched");
        today.adsWatched += progress.toInt();
        break;
      case QuestAction.burn:
        assert(unit == QuestUnit.calories, "only calories can be burned");
        today.caloriesBurned += progress;
        break;
      case QuestAction.collect:
        switch (unit) {
          case QuestUnit.coin:
            today.coinsCollected += progress;
            break;
          case QuestUnit.space:
            today.spaceCollected += progress;
            break;
          case QuestUnit.energy:
            today.energyCollected += progress;
            break;
          default:
            throw UnimplementedError('Unknown unit: $unit');
        }
        break;
      case QuestAction.spend:
        switch (unit) {
          case QuestUnit.coin:
            today.coinsSpent += progress;
            break;
          case QuestUnit.space:
            today.spaceSpent += progress;
            break;
          case QuestUnit.energy:
            today.energySpent += progress;
            break;
          default:
            throw UnimplementedError('Unknown unit: $unit');
        }
        break;
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
