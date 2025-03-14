import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:idlefit/main.dart';
import 'package:idlefit/models/currency.dart';
import 'package:idlefit/models/daily_quest.dart';
import 'package:idlefit/objectbox.g.dart';
import 'package:idlefit/providers/currency_provider.dart';

class DailyQuestNotifier extends StateNotifier<List<DailyQuest>> {
  final Ref ref;
  final Box<DailyQuest> box;
  static const maxActiveQuests = 3;

  DailyQuestNotifier(this.ref, this.box, super.state);

  Future<void> initialize() async {
    state = await _generateDailyQuests();
  }

  Future<List<DailyQuest>> loadAvailableQuests() async {
    final String response = await rootBundle.loadString(
      'assets/daily_quests.json',
    );
    final List<dynamic> data = jsonDecode(response);
    return data.map((item) => DailyQuest.fromJson(item)).toList();
  }

  Future<List<DailyQuest>> getActiveQuests() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayTimestamp = today.millisecondsSinceEpoch;
    final quests =
        await box
            .query(DailyQuest_.dateAssigned.equals(todayTimestamp))
            .build()
            .findAsync();
    if (quests.isNotEmpty) {
      return quests;
    }
    return _generateDailyQuests();
  }

  Future<List<DailyQuest>> _generateDailyQuests() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayTimestamp = today.millisecondsSinceEpoch;
    if (state.isNotEmpty && state.first.dateAssigned == todayTimestamp) {
      // already have quests for today
      return state;
    }

    // Check if we already have quests for today
    final existingQuests =
        box
            .query(DailyQuest_.dateAssigned.equals(todayTimestamp))
            .build()
            .find();

    if (existingQuests.isNotEmpty) {
      return existingQuests; // Already have quests for today
    }

    // generate quests
    // coin quests should be based on the max coin the player can have
    final maxCoins = ref.read(coinProvider).max;
    final spendCoinQuest =
        DailyQuest()
          ..action = QuestAction.spend.name
          ..unit = QuestUnit.coin.name
          ..requirement = maxCoins ~/ 2
          ..reward = maxCoins ~/ 20
          ..rewardUnit = CurrencyType.coin.name
          ..dateAssigned = todayTimestamp;

    final walkQuest =
        DailyQuest()
          ..action = QuestAction.collect.name
          ..unit = QuestUnit.space.name
          ..requirement = 7500
          ..reward = 1000
          ..rewardUnit = CurrencyType.space.name
          ..dateAssigned = todayTimestamp;

    final watchAdQuest =
        DailyQuest()
          ..action = QuestAction.watch.name
          ..unit = QuestUnit.ad.name
          ..requirement = 1
          ..reward = 1000
          ..rewardUnit = CurrencyType.space.name
          ..dateAssigned = todayTimestamp;
    final quests = [spendCoinQuest, walkQuest, watchAdQuest];
    box.putMany(quests);
    assert(quests.isNotEmpty);
    assert(quests[0].id > 0);
    return quests;
  }

  // Updated to use enum types
  Future<void> progressTowards(
    QuestAction action,
    QuestUnit unit,
    double progress,
  ) async {
    final quest =
        state
            .where(
              (quest) =>
                  quest.questAction == action &&
                  quest.questUnit == unit &&
                  !quest.isCompleted,
            )
            .firstOrNull;
    if (quest == null) {
      return;
    }

    print('progressing ${quest.questAction} $action ${quest.questUnit} $unit');
    state =
        state.map((quest) {
          if (quest.id == quest.id) {
            return quest.updateProgress(progress);
          }
          return quest;
        }).toList();
    box.putAsync(quest);
    return;
  }

  void updateQuestProgress(DailyQuest quest, double progress) {
    quest.updateProgress(progress);
    box.put(quest);
  }

  bool areAllQuestsCompleted() {
    final quests = box.getAll();
    return quests.length == maxActiveQuests &&
        quests.every((quest) => quest.isCompleted);
  }
}

final dailyQuestProvider =
    StateNotifierProvider<DailyQuestNotifier, List<DailyQuest>>((ref) {
      return DailyQuestNotifier(
        ref,
        ref.read(objectBoxProvider).store.box<DailyQuest>(),
        [],
      );
    });
