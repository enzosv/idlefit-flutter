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
  late AchievementRepo _achievementRepo;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final objectBox = Provider.of<ObjectBox>(context, listen: false);
    final achievementBox = objectBox.store.box<Achievement>();
    _achievementRepo = AchievementRepo(box: achievementBox);
    final newAchievements = await _achievementRepo.loadNewAchievements();

    // Get progress for each achievement type
    final healthBox = objectBox.store.box<HealthDataEntry>();
    final healthRepo = HealthDataRepo(box: healthBox);
    final healthStats = await healthRepo.total();
    final gameState = Provider.of<GameState>(context, listen: false);

    final newProgress = <String, double>{};
    for (final achievement in newAchievements) {
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
      achievements = newAchievements;
      progress = newProgress;
    });
  }

  void _onClaim(Achievement achievement) async {
    // final isLast = _isLastAchievement(achievement, allAchievements);
    print("attempting to claim");
    if (!_achievementRepo.claimAchievement(achievement)) {
      return;
    }
    if (!mounted) {
      return;
    }
    print("claimed, ${achievement.reward}");

    final gameState = Provider.of<GameState>(context, listen: false);
    final reward = achievement.reward.toDouble();
    // Award the achievement reward
    switch (achievement.rewardUnit.toLowerCase()) {
      case 'space':
        gameState.space.earn(reward);
        break;
      case 'coins':
        gameState.coins.earn(reward);
        break;
      case 'energy':
        gameState.energy.earn(reward);
        break;
    }
    // if (isLast) {
    //   return;
    // }

    // Refresh the achievement list to update visibility
    _fetchData();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ...achievements.map((achievement) {
            final currentProgress = progress[achievement.action] ?? 0;
            final bool isCompleted = achievement.dateClaimed != null;
            final bool canClaim =
                currentProgress >= achievement.requirement && !isCompleted;

            return AchievementCard(
              achievement: achievement,
              progress: currentProgress,
              onClaim: canClaim ? () => _onClaim(achievement) : null,
            );
          }),
        ],
      ),
    );
  }
}
