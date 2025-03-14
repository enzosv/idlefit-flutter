import 'package:flutter/material.dart';
import 'package:idlefit/providers/game_state_provider.dart';
import '../models/daily_quest.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DailyQuestList extends ConsumerWidget {
  const DailyQuestList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.read(gameStateProvider);
    final quests = gameState.dailyQuestRepo.getActiveQuests();
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
              ],
            ),
            const Divider(),
            ...quests.map((quest) {
              // Skip ad quests since we're auto-claiming
              if (quest.questAction == QuestAction.watch) {
                return const SizedBox.shrink();
              }

              return _DailyQuestCard(quest: quest);
            }),
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
                    '${quest.reward} ${quest.rewardCurrency.name}',
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
