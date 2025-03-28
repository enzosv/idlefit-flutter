import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:idlefit/models/currency.dart';
import 'package:idlefit/models/quest_repo.dart';
import 'package:idlefit/providers/providers.dart';

final _questProgressProvider = FutureProvider.family.autoDispose<double, Quest>(
  (ref, quest) async {
    return quest.progress(ref.read(questStatsRepositoryProvider));
  },
);

class QuestCard extends ConsumerWidget {
  final Quest quest;
  final VoidCallback onClaim;

  const QuestCard({super.key, required this.quest, required this.onClaim});

  Widget _progressBar(double progressPercent, ThemeData theme) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progressPercent,
            minHeight: 8,
            color: quest.rewardCurrency.color,
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
            if (quest.dateClaimed != null)
              Text('Claimed', style: theme.textTheme.bodySmall)
            else if (progressPercent >= 1.0)
              ElevatedButton(onPressed: onClaim, child: const Text('Claim')),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final progressAsync = ref.watch(_questProgressProvider(quest));

    return progressAsync.when(
      data: (progress) {
        final progressPercent = (progress / quest.requirement).clamp(0.0, 1.0);
        return _card(progressPercent, theme);
      },
      loading: () => _card(0.0, theme),
      error: (_, __) => _card(0.0, theme),
    );
  }

  Widget _card(double progressPercent, ThemeData theme) {
    final opacity = quest.dateClaimed != null ? 0.6 : max(0.8, progressPercent);

    return Opacity(
      opacity: opacity,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Reward:'),
                    Row(
                      children: [
                        Text(
                          quest.rewardText,
                          style: TextStyle(color: quest.rewardCurrency.color),
                        ),
                        quest.rewardCurrency.iconWithSize(20),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            _progressBar(progressPercent, theme),
          ],
        ),
      ),
    );
  }
}
