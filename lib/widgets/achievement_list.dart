import 'package:flutter/material.dart';
import 'package:idlefit/services/object_box.dart';
import 'package:provider/provider.dart';
import '../models/achievement.dart';
import '../models/achievement_repo.dart';
import '../models/daily_quest.dart';
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
  Map<QuestAction, double> progress = {};
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

    final newProgress = <QuestAction, double>{};
    for (final achievement in newAchievements) {
      if (achievement.dateClaimed != null) continue;

      switch (achievement.questAction) {
        case QuestAction.walk:
          newProgress[achievement.questAction] = healthStats.steps;
          break;
        case QuestAction.collect:
          newProgress[achievement.questAction] = gameState.coins.totalEarned;
          break;
        case QuestAction.spend:
          newProgress[achievement.questAction] = gameState.energy.totalSpent;
          break;
        default:
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
    switch (achievement.questRewardUnit) {
      case RewardUnit.space:
        gameState.space.earn(reward);
        break;
      case RewardUnit.coins:
        gameState.coins.earn(reward);
        break;
      case RewardUnit.energy:
        gameState.energy.earn(reward);
        break;
      default:
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Achievements',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const Divider(),
            ...achievements.map((achievement) {
              final currentProgress = progress[achievement.questAction] ?? 0;
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
      ),
    );
  }
}
