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

  Future<List<Achievement>> loadNewAchievements() async {
    final String response = await rootBundle.loadString(
      'assets/achievements.json',
    );
    final List<dynamic> data = jsonDecode(response);

    // Map to store the lowest unclaimed achievement for each action/reqUnit pair
    Map<String, Achievement> lowestUnclaimedMap = {};

    for (var item in data) {
      final List<int> requirements = List<int>.from(item['requirements']);
      final List<int> rewards = List<int>.from(item['rewards']);
      assert(requirements.length == rewards.length);

      String action = item['action'];
      String reqUnit = item['req_unit'];
      String key = '$action:$reqUnit';

      for (int i = 0; i < requirements.length; i++) {
        Achievement achievement = Achievement();
        achievement.action = action;
        achievement.reqUnit = reqUnit;
        achievement.requirement = requirements[i];

        final same = getSame(achievement);
        if (same != null) {
          print("skipping $action $reqUnit ${achievement.requirement}");
          // Skip if already claimed
          continue;
        }

        achievement.rewardUnit = item['reward_unit'];
        achievement.reward = rewards[i];

        // Only keep the achievement with lowest requirement for this action/reqUnit pair
        if (!lowestUnclaimedMap.containsKey(key) ||
            lowestUnclaimedMap[key]!.requirement > achievement.requirement) {
          lowestUnclaimedMap[key] = achievement;
        }
      }
    }

    return lowestUnclaimedMap.values.toList();
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

  List<Achievement> getClaimed(Achievement achievement) {
    return box.getAll();
  }

  Achievement? getSame(Achievement achievement) {
    return box
        .query(
          Achievement_.action
              .equals(achievement.action)
              .and(Achievement_.reqUnit.equals(achievement.reqUnit))
              .and(Achievement_.requirement.equals(achievement.requirement)),
        )
        .build()
        .findFirst();
  }

  List<Achievement> getPreviousAchievements(Achievement achievement) {
    return box
        .query(
          Achievement_.action
              .equals(achievement.action)
              .and(Achievement_.reqUnit.equals(achievement.reqUnit))
              .and(Achievement_.requirement.lessThan(achievement.requirement)),
        )
        .order(Achievement_.requirement)
        .build()
        .find();
  }
}
