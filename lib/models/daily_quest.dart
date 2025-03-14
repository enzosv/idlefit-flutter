import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:idlefit/helpers/util.dart';
import 'package:idlefit/models/currency.dart';
import 'package:idlefit/objectbox.g.dart';

// Define enums for quest properties
enum QuestAction { unknown, spend, walk, watch, burn, collect }

enum QuestUnit { unknown, coin, steps, ad, calories, energy, space }

@Entity()
class DailyQuest {
  @Id()
  int id = 0;

  // Store enum values as strings in the database
  String action = '';
  String unit = '';
  String rewardUnit = '';

  int requirement = 0;
  int reward = 0;
  double progress = 0; // Track progress
  int dateAssigned = 0;
  bool isClaimed = false;

  DailyQuest();

  QuestAction get questAction {
    return QuestAction.values.byName(action);
  }

  QuestUnit get questUnit {
    return QuestUnit.values.byName(unit);
  }

  CurrencyType get rewardCurrency {
    return CurrencyType.values.byName(rewardUnit);
  }

  bool get isCompleted => progress >= requirement;

  factory DailyQuest.fromJson(Map<String, dynamic> json) {
    final quest =
        DailyQuest()
          ..action = json['action']
          ..unit = json['unit']
          ..rewardUnit = json['reward_unit']
          ..requirement = json['requirement']
          ..reward = json['reward'];
    return quest;
  }

  void updateProgress(double newProgress) {
    progress += newProgress;
  }

  String get description {
    return '${questAction.name} ${toLettersNotation(requirement.toDouble())} ${questUnit.name}';
  }
}

class DailyQuestRepo {
  final Box<DailyQuest> box;
  static const maxActiveQuests = 3;

  DailyQuestRepo({required this.box});

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
    return generateDailyQuests();
  }

  Future<List<DailyQuest>> generateDailyQuests() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayTimestamp = today.millisecondsSinceEpoch;

    // Check if we already have quests for today
    final existingQuests =
        box
            .query(DailyQuest_.dateAssigned.equals(todayTimestamp))
            .build()
            .find();

    if (existingQuests.isNotEmpty) {
      return existingQuests; // Already have quests for today
    }

    final spendCoinQuest =
        DailyQuest()
          ..action = QuestAction.spend.name
          ..unit = QuestUnit.coin.name
          ..requirement = 1000
          ..reward = 100
          ..rewardUnit = CurrencyType.coin.name
          ..dateAssigned = todayTimestamp;

    final walkQuest =
        DailyQuest()
          ..action = QuestAction.walk.name
          ..unit = QuestUnit.steps.name
          ..requirement = 7500
          ..reward = 1000
          ..rewardUnit = CurrencyType.space.name
          ..dateAssigned = todayTimestamp;

    // final watchAdQuest =
    //     DailyQuest()
    //       ..action = QuestAction.watch.name
    //       ..unit = QuestUnit.ad.name
    //       ..requirement = 1
    //       ..reward = 1000
    //       ..rewardUnit = CurrencyType.space.name
    //       ..dateAssigned = todayTimestamp;
    final quests = [spendCoinQuest, walkQuest];
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
    final quests = await generateDailyQuests();
    for (final quest in quests) {
      print('${quest.questAction} $action ${quest.questUnit} $unit');

      if (quest.questAction != action) {
        continue;
      }
      if (quest.questUnit != unit) {
        continue;
      }
      print(
        'progressing ${quest.questAction} $action ${quest.questUnit} $unit',
      );

      quest.progress += progress;
      box.put(quest);
      return;
    }
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
