import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:idlefit/models/daily_quest.dart';
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
      final QuestAction action = QuestActionExtension.fromJson(item['action']);
      final QuestUnit reqUnit = QuestUnitExtension.fromJson(item['req_unit']);
      assert(
        achievements
            .where(
              (a) => (a.questAction == action && a.questReqUnit == reqUnit),
            )
            .isEmpty,
        "there should only be one achivement per action and requirement pair",
      );

      for (int i = 0; i < requirements.length; i++) {
        Achievement achievement = Achievement();
        achievement.questAction = action;
        achievement.questReqUnit = reqUnit;
        achievement.requirement = requirements[i];

        final same = getSame(achievement);
        if (same != null && same.progress > same.requirement) {
          print(
            "skipping ${action.name} ${reqUnit.name} ${achievement.requirement}",
          );
          // Skip if already achieved
          continue;
        }
        if (same != null) {
          achievements.add(same);
          break;
        }

        achievement.questRewardUnit = RewardUnitExtension.fromJson(
          item['reward_unit'],
        );
        achievement.reward = rewards[i];
        achievements.add(achievement);
        // only get the achievement with the lowest requirement
        break;
      }
    }

    return achievements;
  }

  bool claimAchievement(Achievement achievement) {
    if (achievement.isClaimed) return false;
    if (achievement.progress < achievement.requirement) return false;
    achievement.dateAchieved ??= DateTime.now().millisecondsSinceEpoch;
    achievement.isClaimed = true;
    // TODO: give reward
    box.put(achievement);
    return true;
  }

  List<Achievement> getClaimed(Achievement achievement) {
    return box.getAll();
  }

  Achievement? getSame(Achievement achievement) {
    if (achievement.id > 0) {
      final match = box.get(achievement.id);
      if (match != null) {
        return match;
      }
    }

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

  /// load existing achivement from box or json
  Future<Achievement?> loadAchivement(
    QuestAction action,
    QuestUnit unit,
  ) async {
    //load from box
    final same =
        box
            .query(
              Achievement_.action
                  .equals(action.name)
                  .and(Achievement_.reqUnit.equals(unit.name))
                  .and(Achievement_.isClaimed.equals(false)),
            )
            .build()
            .findFirst();
    if (same != null) {
      return same;
    }

    // get latest
    // the one to be loaded from json should have higher requirement
    final latest =
        box
            .query(
              Achievement_.action
                  .equals(action.name)
                  .and(Achievement_.reqUnit.equals(unit.name)),
            )
            .order(Achievement_.requirement, flags: Order.descending)
            .build()
            .findFirst(); //TODO: just get requirement property
    //load from json

    final String response = await rootBundle.loadString(
      'assets/achievements.json',
    );
    final List<dynamic> data = jsonDecode(response);
    for (final item in data) {
      final QuestAction itemAction = QuestActionExtension.fromJson(
        item['action'],
      );
      if (itemAction != action) {
        continue;
      }
      final QuestUnit itemReqUnit = QuestUnitExtension.fromJson(
        item['req_unit'],
      );
      if (itemReqUnit != unit) {
        continue;
      }
      final List<int> requirements = List<int>.from(item['requirements']);
      final List<int> rewards = List<int>.from(item['rewards']);
      assert(requirements.length == rewards.length);
      for (int i = 0; i < requirements.length; i++) {
        if (requirements[i] <= (latest?.requirement ?? 0)) {
          // loaded from json should have higher requirement
          continue;
        }
        final Achievement achievement = Achievement();
        achievement.questAction = action;
        achievement.questReqUnit = unit;
        achievement.requirement = requirements[i];
        achievement.questRewardUnit = RewardUnitExtension.fromJson(
          item['reward_unit'],
        );
        achievement.reward = rewards[i];
        box.put(achievement);
        return achievement;
      }
    }
    return null;
  }

  Future<void> progressTowards(
    QuestAction action,
    QuestUnit unit,
    double progress,
  ) async {
    final quest = await loadAchivement(action, unit);
    if (quest == null) {
      return;
    }
    quest.progress += progress;
    if (quest.progress >= quest.requirement) {
      quest.dateAchieved = DateTime.now().millisecondsSinceEpoch;
    }
    box.put(quest);
    // progress towards the next achievement
    progressTowards(action, unit, quest.progress);
  }
}
