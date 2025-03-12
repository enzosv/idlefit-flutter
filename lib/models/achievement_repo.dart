import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:idlefit/objectbox.g.dart';
import 'package:idlefit/util.dart';
import 'achievement.dart';

class AchievementRepo {
  final Box<Achievement> box;

  AchievementRepo({required this.box});

  Future<List<Achievement>> loadNewAchievements() async {
    final String response = await rootBundle.loadString(
      'assets/achievements.json',
    );
    final List<dynamic> data = jsonDecode(response);

    List<Achievement> achievements = [];

    for (final item in data) {
      final List<int> requirements = List<int>.from(item['requirements']);
      assert(isSorted(requirements));
      final List<int> rewards = List<int>.from(item['rewards']);
      assert(
        requirements.length == rewards.length,
        "${item["action"]} invalid",
      );
      final String action = item['action'];
      final String reqUnit = item['req_unit'];
      assert(
        achievements
            .where((a) => (a.action == action && a.reqUnit == reqUnit))
            .isEmpty,
        "there should only be one achivement per action and requirement pair",
      );

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
        achievements.add(achievement);
        // only get the achievement with the lowest requirement
        break;
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
