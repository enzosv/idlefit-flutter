import 'package:flutter/material.dart';
import 'package:idlefit/services/object_box.dart';
import 'package:provider/provider.dart';
import '../models/achievement.dart';
import '../models/achievement_repo.dart';
import '../models/health_data_repo.dart';
import '../models/health_data_entry.dart';
import '../services/game_state.dart';
import 'achievement_card.dart';

class AchievementList extends StatefulWidget {
  const AchievementList({super.key});

  @override
  _AchievementListState createState() => _AchievementListState();
}

class _AchievementListState extends State<AchievementList> {
  List<Achievement> achievements = [];
  Map<String, double> progress = {};

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final objectBox = Provider.of<ObjectBox>(context, listen: false);
    final achievementBox = objectBox.store.box<Achievement>();
    final achievementRepo = AchievementRepo(box: achievementBox);
    final allAchievements = await achievementRepo.loadAchievements();

    // Sort achievements by action, reqUnit, and requirement
    allAchievements.sort((a, b) {
      int actionCompare = a.action.compareTo(b.action);
      if (actionCompare != 0) return actionCompare;

      int reqUnitCompare = a.reqUnit.compareTo(b.reqUnit);
      if (reqUnitCompare != 0) return reqUnitCompare;

      return a.requirement.compareTo(b.requirement);
    });

    // Filter achievements to only show those where lower requirements are claimed
    final filteredAchievements =
        allAchievements.where((achievement) {
          // Find all achievements with same action and reqUnit but lower requirement
          final lowerRequirements = allAchievements.where(
            (a) =>
                a.action == achievement.action &&
                a.reqUnit == achievement.reqUnit &&
                a.requirement < achievement.requirement,
          );

          // If there are no lower requirements, show the achievement
          if (lowerRequirements.isEmpty) return true;

          // Only show if all lower requirements are claimed
          return lowerRequirements.every((a) => a.dateClaimed != null);
        }).toList();

    // Get progress for each achievement type
    final healthBox = objectBox.store.box<HealthDataEntry>();
    final healthRepo = HealthDataRepo(box: healthBox);
    final healthStats = await healthRepo.total();
    final gameState = Provider.of<GameState>(context, listen: false);

    final newProgress = <String, double>{};
    for (final achievement in filteredAchievements) {
      if (achievement.dateClaimed != null) continue;

      switch (achievement.action.toLowerCase()) {
        case 'walk':
          newProgress[achievement.action] = healthStats.steps;
          break;
        case 'collect':
          newProgress[achievement.action] = gameState.coins.totalEarned;
          break;
        case 'spend':
          newProgress[achievement.action] = gameState.energy.totalSpent;
          break;
      }
    }

    setState(() {
      achievements = filteredAchievements;
      progress = newProgress;
    });
  }

  void _onClaim(Achievement achievement) async {
    final objectBox = Provider.of<ObjectBox>(context, listen: false);
    final achievementBox = objectBox.store.box<Achievement>();
    final achievementRepo = AchievementRepo(box: achievementBox);

    if (achievementRepo.claimAchievement(achievement)) {
      final gameState = Provider.of<GameState>(context, listen: false);

      // Award the achievement reward
      switch (achievement.rewardUnit.toLowerCase()) {
        case 'space':
          gameState.space.earn(achievement.reward.toDouble());
          break;
        case 'coins':
          gameState.coins.earn(achievement.reward.toDouble());
          break;
        case 'energy':
          gameState.energy.earn(achievement.reward.toDouble());
          break;
      }

      // Refresh the achievement list to update visibility
      _fetchData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ...achievements.map((achievement) {
            final currentProgress = progress[achievement.action] ?? 0;
            return AchievementCard(
              achievement: achievement,
              progress: currentProgress,
              onClaim: () => _onClaim(achievement),
            );
          }),
        ],
      ),
    );
  }
}
