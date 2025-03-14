import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:idlefit/models/currency.dart';
import 'package:idlefit/providers/coin_provider.dart';
import 'package:idlefit/services/game_state_notifier.dart';
import 'package:idlefit/main.dart'; // Import providers from main.dart
import '../models/achievement.dart';
import '../models/achievement_repo.dart';
import '../models/daily_quest.dart';
import '../models/health_data_repo.dart';
import '../models/health_data_entry.dart';
import 'achievement_card.dart';

class AchievementList extends ConsumerStatefulWidget {
  const AchievementList({super.key});

  @override
  ConsumerState<AchievementList> createState() => _AchievementListState();
}

class _AchievementListState extends ConsumerState<AchievementList> {
  List<Achievement> achievements = [];
  Map<QuestAction, double> progress = {};
  late AchievementRepo _achievementRepo;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final objectBox = ref.read(objectBoxProvider);
    final achievementBox = objectBox.store.box<Achievement>();
    _achievementRepo = AchievementRepo(box: achievementBox);
    final newAchievements = await _achievementRepo.loadNewAchievements();

    // Get progress for each achievement type
    final healthBox = objectBox.store.box<HealthDataEntry>();
    final healthRepo = HealthDataRepo(box: healthBox);
    final healthStats = await healthRepo.total();
    final coins = ref.read(coinProvider);

    final newProgress = <QuestAction, double>{};
    for (final achievement in newAchievements) {
      if (achievement.dateClaimed != null) continue;

      switch (achievement.questAction) {
        case QuestAction.walk:
          newProgress[achievement.questAction] = healthStats.steps;
          break;
        case QuestAction.collect:
          newProgress[achievement.questAction] = coins.totalEarned;
          break;
        case QuestAction.spend:
          newProgress[achievement.questAction] =
              ref.read(energyProvider).totalSpent;
          break;
        default:
          assert(false, 'unhandled quest action ${achievement.questAction}');
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

    final reward = achievement.reward.toDouble();
    // Award the achievement reward

    switch (achievement.rewardCurrency) {
      case CurrencyType.coin:
        final coinsNotifier = ref.read(coinProvider.notifier);
        coinsNotifier.earn(reward);
      case CurrencyType.space:
        final spaceNotifier = ref.read(spaceProvider.notifier);
        spaceNotifier.earn(reward);
      case CurrencyType.energy:
        final energyNotifier = ref.read(energyProvider.notifier);
        energyNotifier.earn(reward);
      default:
        assert(false, 'unhandled currency type ${achievement.rewardCurrency}');
        return;
    }
    print("claimed, ${achievement.reward}");
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
