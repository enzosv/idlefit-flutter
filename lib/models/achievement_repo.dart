import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:idlefit/objectbox.g.dart';
import 'achievement.dart';

class AchievementRepo {
  final Box<Achievement> box;

  AchievementRepo({required this.box});

  List<Achievement> getAll() {
    return box.getAll();
  }

  void saveAchievement(Achievement achievement) {
    box.put(achievement);
  }

  Achievement? getById(int id) {
    return box.get(id);
  }

  List<Achievement> getByAction(String action) {
    // Temporary solution until ObjectBox models are generated
    return box.getAll().where((a) => a.action == action).toList();
  }

  Future<List<Achievement>> loadAchievements() async {
    final String response = await rootBundle.loadString(
      'assets/achievements.json',
    );
    final List<dynamic> data = jsonDecode(response);

    List<Achievement> achievements = [];

    for (var item in data) {
      final List<int> requirements = List<int>.from(item['requirements']);
      final List<int> rewards = List<int>.from(item['rewards']);
      assert(requirements.length == rewards.length);
      for (int i = 0; i < requirements.length; i++) {
        Achievement achievement = Achievement();
        achievement.action = item['action'];
        achievement.reqUnit = item['req_unit'];
        achievement.rewardUnit = item['reward_unit'];
        achievement.requirement = requirements[i];
        achievement.reward = rewards[i];

        achievements.add(achievement);
      }
    }

    return achievements;
  }

  bool claimAchievement(Achievement achievement) {
    if (achievement.dateClaimed != null) return false;
    achievement.dateClaimed = DateTime.now().millisecondsSinceEpoch;
    box.put(achievement);
    return true;
  }

  double checkProgress(String action, double currentValue) {
    final achievements = getByAction(action);
    for (var achievement in achievements) {
      if (achievement.dateClaimed == null &&
          currentValue >= achievement.requirement) {
        return achievement.reward.toDouble();
      }
    }
    return 0;
  }
}
