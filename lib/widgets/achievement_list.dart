import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:idlefit/models/currency.dart';
import 'package:idlefit/providers/currency_provider.dart';
import 'package:idlefit/providers/game_engine_provider.dart';
import 'package:idlefit/providers/objectbox_provider.dart';
import '../models/achievement.dart';
import '../models/achievement_repo.dart';
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
  Map<String, double> progress = {};
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

    // Use currency provider to get totals
    final currencyNotifier = ref.read(currencyNotifierProvider);
    final coins = currencyNotifier[CurrencyType.coin];
    final energy = currencyNotifier[CurrencyType.energy];

    final newProgress = <String, double>{};
    for (final achievement in newAchievements) {
      if (achievement.dateClaimed != null) continue;

      switch (achievement.action.toLowerCase()) {
        case 'walk':
          newProgress[achievement.action] = healthStats.steps;
          break;
        case 'collect':
          newProgress[achievement.action] = coins?.totalEarned ?? 0;
          break;
        case 'spend':
          newProgress[achievement.action] = energy?.totalSpent ?? 0;
          break;
      }
    }

    if (mounted) {
      setState(() {
        achievements = newAchievements;
        progress = newProgress;
      });
    }
  }

  void _onClaim(Achievement achievement) async {
    print("attempting to claim");
    if (!_achievementRepo.claimAchievement(achievement)) {
      return;
    }
    if (!mounted) {
      return;
    }
    print("claimed, ${achievement.reward}");

    final currencyNotifier = ref.read(currencyNotifierProvider.notifier);
    final reward = achievement.reward.toDouble();

    // Award the achievement reward
    switch (achievement.rewardUnit.toLowerCase()) {
      case 'space':
        currencyNotifier.earn(CurrencyType.space, reward);
        break;
      case 'coins':
        currencyNotifier.earn(CurrencyType.coin, reward);
        break;
      case 'energy':
        currencyNotifier.earn(CurrencyType.energy, reward);
        break;
    }

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
      ),
    );
  }
}
