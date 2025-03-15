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
    if (state.dayTimestamp == today) {
      return state;
    }
    return box.get(today) ?? (GameStats()..dayTimestamp = today);
  }

  Future<GameStats> get total async {
    final allStats = await box.getAllAsync();
    final totaled = GameStats();
    for (final stat in allStats) {
      totaled
        ..generatorsPurchased += stat.generatorsPurchased
        ..generatorsUpgraded += stat.generatorsUpgraded
        ..shopItemsUpgraded += stat.shopItemsUpgraded
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
    // TODO: analytics

    // Validate action-unit combination
    if (!_validActionUnits[action]!.contains(unit)) {
      throw ArgumentError('Invalid action-unit combination: $action-$unit');
    }
    final today = await _getToday();

    switch ((action, unit)) {
      case (QuestAction.purchase, QuestUnit.generator):
        today.generatorsPurchased += progress.toInt();

      case (QuestAction.upgrade, QuestUnit.generator):
        today.generatorsUpgraded += progress.toInt();

      case (QuestAction.upgrade, QuestUnit.shopItem):
        today.shopItemsUpgraded += progress.toInt();

      case (QuestAction.tap, QuestUnit.generator):
        today.generatorsTapped += progress.toInt();

      case (QuestAction.watch, QuestUnit.ad):
        today.adsWatched += progress.toInt();

      case (QuestAction.burn, QuestUnit.calories):
        today.caloriesBurned += progress;

      case (QuestAction.collect, QuestUnit.coin):
        today.coinsCollected += progress;

      case (QuestAction.collect, QuestUnit.space):
        today.spaceCollected += progress;

      case (QuestAction.collect, QuestUnit.energy):
        today.energyCollected += progress;

      case (QuestAction.spend, QuestUnit.coin):
        today.coinsSpent += progress;

      case (QuestAction.spend, QuestUnit.space):
        today.spaceSpent += progress;

      case (QuestAction.spend, QuestUnit.energy):
        today.energySpent += progress;

      default:
        throw UnimplementedError(
          'Unhandled action-unit combination: $action-$unit',
        );
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
