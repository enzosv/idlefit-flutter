import 'dart:convert';
import 'package:flutter/services.dart';
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
          ..rewardUnit = json['reward_unit']
          ..progress = 0;
    return quest;
  }

  void updateProgress(double newProgress) {
    progress = newProgress;
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
    return box.getAll();
  }

  Future<void> generateDailyQuests() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayTimestamp = today.millisecondsSinceEpoch;

    // Check if we already have quests for today
    final existingQuests =
        box
            .getAll()
            .where((quest) => quest.dateAssigned == todayTimestamp)
            .toList();

    if (existingQuests.isNotEmpty) {
      return; // Already have quests for today
    }

    // Clear old quests
    box.removeAll();

    // Load available quests and randomly select 3
    final availableQuests = await loadAvailableQuests();
    availableQuests.shuffle();
    final selectedQuests =
        availableQuests.take(maxActiveQuests).map((quest) {
          quest.dateAssigned = todayTimestamp;
          return quest;
        }).toList();

    // Save new quests
    box.putMany(selectedQuests);
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
