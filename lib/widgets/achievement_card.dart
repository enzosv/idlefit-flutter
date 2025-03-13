import 'package:flutter/material.dart';
import '../models/achievement.dart';
import '../models/daily_quest.dart';

class AchievementCard extends StatelessWidget {
  final Achievement achievement;
  final VoidCallback? onClaim;

  const AchievementCard({super.key, required this.achievement, this.onClaim});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progressPercent = (achievement.progress / achievement.requirement)
        .clamp(0.0, 1.0);

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
                    Text(
                      achievement.description,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Reward:', style: theme.textTheme.bodySmall),
                  Text(
                    '${achievement.rewardText} ${achievement.questRewardUnit.display}',
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
              if (achievement.dateAchieved != null && achievement.isClaimed)
                Text(
                  'Completed ${_formatDate(DateTime.fromMillisecondsSinceEpoch(achievement.dateAchieved!))}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                )
              else if (achievement.progress >= achievement.requirement)
                ElevatedButton(onPressed: onClaim, child: const Text('Claim')),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
