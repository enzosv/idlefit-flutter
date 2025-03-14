import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:idlefit/objectbox.g.dart';
import 'package:objectbox/objectbox.dart';

// Define enums for quest properties
enum QuestAction { spend, walk, watch, burn, collect }

enum QuestUnit { coins, steps, ad, calories, energy, space }

enum RewardUnit { coins, energy, space, gems }

// Extension methods to handle string conversion for JSON and display
extension QuestActionExtension on QuestAction {
  String toJson() {
    return name[0].toUpperCase() + name.substring(1);
  }

  static QuestAction fromJson(String json) {
    final normalized = json.toLowerCase();
    return QuestAction.values.firstWhere(
      (action) => action.name == normalized,
      orElse: () => QuestAction.spend,
    );
  }

  String get display => name[0].toUpperCase() + name.substring(1);
}

extension QuestUnitExtension on QuestUnit {
  String toJson() {
    return name.toLowerCase();
  }

  static QuestUnit fromJson(String json) {
    final normalized = json.toLowerCase();
    return QuestUnit.values.firstWhere(
      (unit) => unit.name == normalized,
      orElse: () => QuestUnit.coins,
    );
  }

  String get display => name[0].toUpperCase() + name.substring(1);
}

extension RewardUnitExtension on RewardUnit {
  String toJson() {
    return name.toLowerCase();
  }

  static RewardUnit fromJson(String json) {
    final normalized = json.toLowerCase();
    return RewardUnit.values.firstWhere(
      (unit) => unit.name == normalized,
      orElse: () => RewardUnit.coins,
    );
  }

  String get display => name[0].toUpperCase() + name.substring(1);
}

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

  // Getters and setters for enum properties - marked as @Transient so ObjectBox ignores them
  @Transient()
  QuestAction get questAction => QuestActionExtension.fromJson(action);
  set questAction(QuestAction value) => action = value.toJson();

  @Transient()
  QuestUnit get questUnit => QuestUnitExtension.fromJson(unit);
  set questUnit(QuestUnit value) => unit = value.toJson();

  @Transient()
  RewardUnit get questRewardUnit => RewardUnitExtension.fromJson(rewardUnit);
  set questRewardUnit(RewardUnit value) => rewardUnit = value.toJson();

  @Transient()
  String get description {
    return '${questAction.display} $requirement ${questUnit.display}';
  }

  @Transient()
  String get rewardText {
    return reward.toString();
  }

  @Transient()
  bool get isCompleted => progress >= requirement;

  factory DailyQuest.fromJson(Map<String, dynamic> json) {
    final quest =
        DailyQuest()
          ..questAction = QuestActionExtension.fromJson(json['action'])
          ..questUnit = QuestUnitExtension.fromJson(json['unit'])
          ..requirement = json['requirement']
          ..reward = json['reward']
          ..questRewardUnit = RewardUnitExtension.fromJson(json['reward_unit']);
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
          ..questAction = QuestAction.spend
          ..questUnit = QuestUnit.coins
          ..requirement = 1000
          ..reward = 100
          ..questRewardUnit = RewardUnit.coins
          ..dateAssigned = todayTimestamp;

    final walkQuest =
        DailyQuest()
          ..questAction = QuestAction.walk
          ..questUnit = QuestUnit.steps
          ..requirement = 7500
          ..reward = 1000
          ..questRewardUnit = RewardUnit.space
          ..dateAssigned = todayTimestamp;

    final watchAdQuest =
        DailyQuest()
          ..questAction = QuestAction.watch
          ..questUnit = QuestUnit.ad
          ..requirement = 1
          ..reward = 1000
          ..questRewardUnit = RewardUnit.space
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
    final quests = await generateDailyQuests();
    for (final quest in quests) {
      print('${quest.questAction} ${action} ${quest.questUnit} $unit');

      if (quest.questAction != action) {
        continue;
      }
      if (quest.questUnit != unit) {
        continue;
      }
      print(
        'progressing ${quest.questAction} ${action} ${quest.questUnit} $unit',
      );

      quest.progress += progress;
      box.put(quest);
      return;
    }
  }

  // Keep the string-based method for backward compatibility
  Future<void> progressTowardsString(
    String actionStr,
    String unitStr,
    double progress,
  ) async {
    final action = QuestActionExtension.fromJson(actionStr);
    final unit = QuestUnitExtension.fromJson(unitStr);
    return progressTowards(action, unit, progress);
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
