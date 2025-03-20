import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:idlefit/models/currency.dart';
import 'package:idlefit/models/quest_repo.dart';
import 'package:idlefit/models/quest_stats.dart';

class QuestCard extends ConsumerWidget {
  final Quest quest;
  final VoidCallback onClaim;

  const QuestCard({super.key, required this.quest, required this.onClaim});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

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
                    Row(
                      children: [
                        Text(
                          quest.description,
                          style: theme.textTheme.titleMedium,
                        ),
                        if (quest.questUnit.currencyType != null)
                          quest.questUnit.currencyType!.iconWithSize(20),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Reward:'),
                  Row(
                    children: [
                      Text(
                        quest.rewardText,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: quest.rewardCurrency.color,
                        ),
                      ),
                      quest.rewardCurrency.iconWithSize(20),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          FutureBuilder<double>(
            future: quest.progress(ref.read(questStatsRepositoryProvider)),
            builder: (context, snapshot) {
              final progress = snapshot.data ?? 0.0;
              final progressPercent = (progress / quest.requirement).clamp(
                0.0,
                1.0,
              );

              return Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: snapshot.hasData ? progressPercent : null,
                      minHeight: 8,
                      color: quest.rewardCurrency.color,
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        snapshot.hasData
                            ? '${(progressPercent * 100).toInt()}%'
                            : 'Loading...',
                        style: theme.textTheme.bodySmall,
                      ),
                      if (quest.dateClaimed != null)
                        Text('Claimed', style: theme.textTheme.bodySmall)
                      else if (snapshot.hasData &&
                          progress >= quest.requirement)
                        ElevatedButton(
                          onPressed: onClaim,
                          child: const Text('Claim'),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
