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

enum QuestType { unknown, daily, weekly, monthly, achievement }

extension QuestTypeX on QuestType {
  String get displayName {
    switch (this) {
      case QuestType.unknown:
        return 'Unknown';
      case QuestType.daily:
        return 'Daily Quests';
      case QuestType.weekly:
        return 'Weekly Quests';
      case QuestType.monthly:
        return 'Monthly Quests';
      case QuestType.achievement:
        return 'Achievements';
    }
  }
}

@Entity()
class Quest {
  @Id()
  int id = 0;

  int dayTimestamp = 0;

  int action = 0;
  int unit = 0;
  int rewardUnit = 0;
  int type = 0;

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
    return QuestAction.values[action];
  }

  QuestUnit get questUnit {
    return QuestUnit.values[unit];
  }

  CurrencyType get rewardCurrency {
    return CurrencyType.values[rewardUnit];
  }

  QuestType get questType {
    return QuestType.values[type];
  }

  Future<double> progress(QuestStatsRepository repository) async {
    if (questType == QuestType.achievement) {
      return repository.getTotalProgress(questAction, questUnit);
    }
    return repository.getProgress(questAction, questUnit, dayTimestamp);
  }

  Future<bool> isCompleted(QuestStatsRepository repository) async {
    return (await progress(repository)) >= requirement;
  }

  String get description {
    final valueText =
        questUnit == QuestUnit.energy
            ? durationNotation(requirement.toDouble())
            : toLettersNotation(requirement.toDouble());
    if (questUnit.currencyType == null) {
      return '${questAction.name.capitalize()} $valueText ${questUnit.name}';
    }
    return '${questAction.name.capitalize()} $valueText';
  }

  String get rewardText {
    if (rewardCurrency == CurrencyType.energy) {
      return durationNotation(reward.toDouble());
    }
    return toLettersNotation(reward.toDouble());
  }
}

class QuestRepository {
  final Box<Quest> box;

  QuestRepository(this.box);

  Future<List<Quest>> getQuests(QuestType type) async {
    switch (type) {
      case QuestType.achievement:
        return await _getAchievements();
      case QuestType.daily:
        return await _getDailyQuests();
      default:
        return [];
    }
  }

  Future<List<Quest>> _getAchievements() async {
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
              .equals(QuestType.achievement.index)
              .and(Quest_.dateClaimed.greaterThan(0))
              .and(Quest_.action.equals(action.index))
              .and(Quest_.unit.equals(unit.index)),
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
      // TODO: achievement for number of generators purchased
      // TODO: achievement for number of generator upgrades purchased
      // TODO: achievement for number of generator upgrades unlocked
      // TODO: achievement for number of shop items purchased
      // TODO: achievement for number of manual taps

      default:
        return null;
    }

    return Quest(
      action: action.index,
      unit: unit.index,
      rewardUnit: rewardUnit.index,
      type: QuestType.achievement.index,
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
                  .equals(QuestType.achievement.index)
                  .and(Quest_.action.equals(QuestAction.spend.index))
                  .and(Quest_.unit.equals(QuestUnit.coin.index))
                  .and(Quest_.dateClaimed.greaterThan(0)),
            )
            .order(Quest_.dateClaimed, flags: Order.descending)
            .build()
            .findFirstAsync();
    final coinRequirement = maxCoins?.reward ?? 1000;
    final coinReward = coinRequirement * 0.1;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final quests = [
      Quest(
        action: QuestAction.watch.index,
        unit: QuestUnit.ad.index,
        rewardUnit: CurrencyType.space.index,
        type: QuestType.daily.index,
        dayTimestamp: today,
        requirement: 1,
        reward: 1000,
      ),
      Quest(
        action: QuestAction.spend.index,
        unit: QuestUnit.coin.index,
        rewardUnit: CurrencyType.coin.index,
        type: QuestType.daily.index,
        dayTimestamp: today,
        requirement: coinRequirement,
        reward: coinReward,
      ),
      Quest(
        action: QuestAction.walk.index,
        unit: QuestUnit.steps.index,
        rewardUnit: CurrencyType.space.index,
        type: QuestType.daily.index,
        dayTimestamp: today,
        requirement: 7500,
        reward: 1000,
      ),
    ];
    box.putMany(quests);
    return quests;
  }

  /// returns daily quests for today
  /// generates them if they dont exist
  Future<List<Quest>> _getDailyQuests() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final dailyQuests =
        box
            .query(
              Quest_.type
                  .equals(QuestType.daily.index)
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
    print("claiming quest: ${quest.id}");
    currencyNotifier.earn(quest.reward.toDouble());
    quest.dateClaimed = DateTime.now().millisecondsSinceEpoch;
    box.put(quest);
    print("quest claimed: ${quest.id}");
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
