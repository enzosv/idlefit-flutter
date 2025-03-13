import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:idlefit/objectbox.g.dart';
import 'package:objectbox/objectbox.dart';

@Entity()
class DailyQuest {
  @Id()
  int id = 0;
  String action = '';
  String unit = '';
  int requirement = 0;
  int reward = 0;
  String rewardUnit = '';
  double progress = 0; // Track progress
  int dateAssigned = 0;
  bool isClaimed = false;

  DailyQuest();

  String get description {
    return '$action $requirement $unit';
  }

  String get rewardText {
    return reward.toString();
  }

  bool get isCompleted => progress >= requirement;

  factory DailyQuest.fromJson(Map<String, dynamic> json) {
    final quest =
        DailyQuest()
          ..action = json['action']
          ..unit = json['unit']
          ..requirement = json['requirement']
          ..reward = json['reward']
          ..rewardUnit = json['reward_unit'];
    return quest;
  }

  void updateProgress(double newProgress) {
    progress += newProgress;
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

  List<DailyQuest> getActiveQuests() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayTimestamp = today.millisecondsSinceEpoch;
    return box
        .query(DailyQuest_.dateAssigned.equals(todayTimestamp))
        .build()
        .find();
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
          ..action = 'Spend'
          ..unit = 'Coins'
          ..requirement = 1000
          ..reward = 100
          ..rewardUnit = 'Coins'
          ..dateAssigned = todayTimestamp;

    final walkQuest =
        DailyQuest()
          ..action = 'Walk'
          ..unit = 'Steps'
          ..requirement = 7500
          ..reward = 1000
          ..rewardUnit = 'Space'
          ..dateAssigned = todayTimestamp;

    final watchAdQuest =
        DailyQuest()
          ..action = 'Watch'
          ..unit = 'Ad'
          ..requirement = 1
          ..reward = 1000
          ..rewardUnit = 'Space'
          ..dateAssigned = todayTimestamp;
    final quests = [spendCoinQuest, walkQuest, watchAdQuest];
    box.putMany(quests);
    assert(quests.isNotEmpty);
    assert(quests[0].id > 0);
    return quests;
  }

  Future<void> progressTowards(String unit, action, double progress) async {
    final quests = await generateDailyQuests();
    for (final quest in quests) {
      print('${quest.action} ${action} ${quest.unit} $unit');

      if (quest.action.toLowerCase() != action.toLowerCase()) {
        continue;
      }
      if (quest.unit.toLowerCase() != unit.toLowerCase()) {
        continue;
      }
      print('progressing ${quest.action} ${action} ${quest.unit} $unit');

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
