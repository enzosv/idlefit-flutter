import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:idlefit/helpers/util.dart';
import 'package:idlefit/main.dart';
import 'package:idlefit/models/currency.dart';
import 'package:idlefit/models/daily_quest.dart';
import 'package:idlefit/models/quest_stats.dart';
import 'package:idlefit/objectbox.g.dart';
import 'package:idlefit/providers/currency_provider.dart';
import 'package:objectbox/objectbox.dart';

enum QuestType { unknown, daily, weekly, monthly, achivement }

@Entity()
class Quest {
  @Id()
  int id = 0;

  int dayTimestamp = 0;

  String action = '';
  String unit = '';
  String rewardUnit = '';
  String type = '';

  double requirement = 0;
  double reward = 0;
  int? dateClaimed;

  Quest({
    required this.action,
    required this.unit,
    required this.rewardUnit,
    required this.type,
    required this.dayTimestamp,
    required this.requirement,
    required this.reward,
    this.dateClaimed,
  });

  QuestAction get questAction {
    return QuestAction.values.byNameOrNull(action) ?? QuestAction.unknown;
  }

  QuestUnit get questUnit {
    return QuestUnit.values.byNameOrNull(unit) ?? QuestUnit.unknown;
  }

  CurrencyType get rewardCurrency {
    return CurrencyType.values.byNameOrNull(rewardUnit) ?? CurrencyType.unknown;
  }

  QuestType get questType {
    return QuestType.values.byNameOrNull(type) ?? QuestType.unknown;
  }

  Future<double> progress(QuestStatsRepository repository) async {
    if (questType == QuestType.achivement) {
      return repository.getTotalProgress(questAction, questUnit);
    }
    return repository.getProgress(questAction, questUnit, dayTimestamp);
  }

  Future<bool> isCompleted(QuestStatsRepository repository) async {
    return (await progress(repository)) >= requirement;
  }

  String get description {
    return '${questAction.name.capitalize()} ${toLettersNotation(requirement.toDouble())} ${questUnit.name}';
  }
}

class QuestRepository {
  final Box<Quest> box;

  QuestRepository(this.box);
  Future<List<Quest>> getAchievements() async {
    return (await [
          _generateAchievement(QuestAction.spend, QuestUnit.coin),
          _generateAchievement(QuestAction.walk, QuestUnit.steps),
          _generateAchievement(QuestAction.spend, QuestUnit.energy),
        ].wait)
        .whereType<Quest>()
        .toList();
  }

  Future<int> _countAchievements(QuestAction action, QuestUnit unit) async {
    return box
        .query(
          Quest_.type
              .equals(QuestType.achivement.name)
              .and(Quest_.dateClaimed.greaterThan(0))
              .and(Quest_.action.equals(action.name))
              .and(Quest_.unit.equals(unit.name)),
        )
        .build()
        .count();
  }

  Future<Quest?> _generateAchievement(
    QuestAction action,
    QuestUnit unit,
  ) async {
    final level = await _countAchievements(action, unit);
    double requirement = 0;
    double reward = 0;
    CurrencyType rewardUnit = CurrencyType.unknown;

    switch ((action, unit)) {
      case (QuestAction.spend, QuestUnit.coin):
        rewardUnit = CurrencyType.coin;
        reward = pow(1000, (level + 1)).toDouble();
        requirement = reward * 1000;
      case (QuestAction.spend, QuestUnit.energy):
        rewardUnit = CurrencyType.energy;
        const requirements = [28800000, 86400000, 604800000, 2592000000];
        const rewards = [1200000, 3600000, 7200000, 10800000];
        requirement = requirements[level].toDouble();
        reward = rewards[level].toDouble();
      case (QuestAction.walk, QuestUnit.steps):
        rewardUnit = CurrencyType.space;
        const requirements = [10000, 50000, 100000, 200000, 500000, 1000000];
        const rewards = [1000, 2000, 3000, 4000, 5000, 6000];
        requirement = requirements[level].toDouble();
        reward = rewards[level].toDouble();
      // TODO: achivement for number of generators purchased
      // TODO: achivement for number of generator upgrades purchased
      // TODO: achivement for number of generator upgrades unlocked
      // TODO: achivement for number of shop items purchased
      // TODO: achivement for number of manual taps

      default:
        return null;
    }

    return Quest(
      action: action.name,
      unit: unit.name,
      rewardUnit: rewardUnit.name,
      type: QuestType.achivement.name,
      dayTimestamp: 0,
      requirement: requirement,
      reward: reward,
    );
  }

  Future<List<Quest>> _generateTodayDailyQuests() async {
    final maxCoins =
        await box
            .query(
              Quest_.type
                  .equals(QuestType.achivement.name)
                  .and(Quest_.action.equals(QuestAction.spend.name))
                  .and(Quest_.unit.equals(QuestUnit.coin.name))
                  .and(Quest_.dateClaimed.greaterThan(0)),
            )
            .order(Quest_.dateClaimed, flags: Order.descending)
            .build()
            .findFirstAsync();
    final coinRequirement = maxCoins?.reward ?? 1000;
    final coinReward = coinRequirement * 0.1;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    return [
      Quest(
        action: QuestAction.watch.name,
        unit: QuestUnit.ad.name,
        rewardUnit: CurrencyType.space.name,
        type: QuestType.daily.name,
        dayTimestamp: today,
        requirement: 1,
        reward: 1000,
      ),
      Quest(
        action: QuestAction.spend.name,
        unit: QuestUnit.coin.name,
        rewardUnit: CurrencyType.coin.name,
        type: QuestType.daily.name,
        dayTimestamp: today,
        requirement: coinRequirement,
        reward: coinReward,
      ),
      Quest(
        action: QuestAction.walk.name,
        unit: QuestUnit.steps.name,
        rewardUnit: CurrencyType.space.name,
        type: QuestType.daily.name,
        dayTimestamp: today,
        requirement: 7500,
        reward: 1000,
      ),
    ];
  }

  Future<List<Quest>> getTodayDailyQuests(int maxCoins) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final dailyQuests =
        box
            .query(
              Quest_.type
                  .equals(QuestType.daily.name)
                  .and(Quest_.dayTimestamp.equals(today)),
            )
            .build()
            .find();
    if (dailyQuests.isNotEmpty) {
      return dailyQuests;
    }
    return _generateTodayDailyQuests();
  }

  Future<void> claimQuest(
    Quest quest,
    QuestStatsRepository repository,
    CurrencyNotifier currencyNotifier,
  ) async {
    if (quest.dateClaimed != null || !(await quest.isCompleted(repository))) {
      return;
    }
    currencyNotifier.earn(quest.reward.toDouble());
    quest.dateClaimed = DateTime.now().millisecondsSinceEpoch;
    box.putAsync(quest);
  }
}

// class QuestNotifier extends StateNotifier<Quest> {
//   final GameStats stats;
//   final QuestRepository repository;

//   QuestNotifier(this.stats, this.repository, super.state);
// }

final questRepositoryProvider = Provider<QuestRepository>((ref) {
  final box = ref.read(objectBoxProvider).store.box<Quest>();
  return QuestRepository(box);
});

// final questProvider = StateNotifierProvider<QuestNotifier, Quest>((ref) {
//   final repository = ref.read(questRepositoryProvider);
//   final gameStats = ref.read(gameStatsProvider);
//   return QuestNotifier(gameStats, repository, Quest());
// });
