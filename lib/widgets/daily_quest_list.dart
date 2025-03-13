import 'package:flutter/material.dart';
import 'package:idlefit/services/object_box.dart';
import 'package:provider/provider.dart';
import '../models/daily_quest.dart';
import '../services/game_state.dart';
import '../models/health_data_repo.dart';
import '../models/health_data_entry.dart';
import '../util.dart';

class DailyQuestList extends StatefulWidget {
  const DailyQuestList({super.key});

  @override
  _DailyQuestListState createState() => _DailyQuestListState();
}

class _DailyQuestListState extends State<DailyQuestList> {
  List<DailyQuest> quests = [];
  late DailyQuestRepo _questRepo;
  late HealthDataRepo _healthRepo;
  bool allQuestsCompleted = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final objectBox = Provider.of<ObjectBox>(context, listen: false);
    final questBox = objectBox.store.box<DailyQuest>();
    final healthBox = objectBox.store.box<HealthDataEntry>();
    _questRepo = DailyQuestRepo(box: questBox);
    _healthRepo = HealthDataRepo(box: healthBox);

    // Generate daily quests if needed
    await _questRepo.generateDailyQuests();

    // Get active quests
    final activeQuests = _questRepo.getActiveQuests();
    final gameState = Provider.of<GameState>(context, listen: false);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final healthStats = await _healthRepo.today(today);

    // Update progress for each quest
    for (final quest in activeQuests) {
      double progress = 0;
      switch (quest.action.toLowerCase()) {
        case 'walk':
          progress = healthStats.steps.toDouble();
          break;
        case 'spend':
          if (quest.unit.toLowerCase() == 'coins') {
            progress = gameState.dailyCoinsSpent;
          } else if (quest.unit.toLowerCase() == 'space') {
            progress = gameState.dailySpaceSpent;
          }
          break;
        case 'burn':
          progress = healthStats.calories;
          break;
        case 'watch':
          // Skip ad quests since we're auto-claiming
          continue;
      }

      // Update quest progress
      if (progress != quest.progress) {
        _questRepo.updateQuestProgress(quest, progress);

        // If quest just completed, give reward
        if (progress >= quest.requirement &&
            quest.progress < quest.requirement) {
          _giveReward(quest);
        }
      }
    }

    // Check if all quests are completed for bonus
    final wasCompleted = allQuestsCompleted;
    final isNowCompleted = _questRepo.areAllQuestsCompleted();

    if (!wasCompleted && isNowCompleted) {
      // Give bonus reward (100 gems) when all quests are completed
      gameState.gems.earn(100);
    }

    setState(() {
      quests = activeQuests;
      allQuestsCompleted = isNowCompleted;
    });
  }

  void _giveReward(DailyQuest quest) {
    if (!mounted) return;

    final gameState = Provider.of<GameState>(context, listen: false);
    final reward = quest.reward.toDouble();

    // Award the quest reward
    switch (quest.rewardUnit.toLowerCase()) {
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
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Daily Quests',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                if (allQuestsCompleted)
                  const Icon(Icons.star, color: Colors.amber),
              ],
            ),
            const Divider(),
            ...quests.map((quest) {
              // Skip ad quests since we're auto-claiming
              if (quest.action.toLowerCase() == 'watch') {
                return const SizedBox.shrink();
              }

              return _DailyQuestCard(quest: quest);
            }),
            if (allQuestsCompleted) ...[
              const Divider(),
              const Center(
                child: Text(
                  'All quests completed! +100 gems bonus!',
                  style: TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DailyQuestCard extends StatelessWidget {
  final DailyQuest quest;

  const _DailyQuestCard({required this.quest});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progressPercent = (quest.progress / quest.requirement).clamp(
      0.0,
      1.0,
    );

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(quest.description, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Reward:', style: theme.textTheme.bodySmall),
                  Text(
                    '${quest.rewardText} ${quest.rewardUnit}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progressPercent,
              minHeight: 8,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(progressPercent * 100).toInt()}%',
                style: theme.textTheme.bodySmall,
              ),
              if (quest.isCompleted)
                Text(
                  'Completed',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
