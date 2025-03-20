import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:idlefit/models/currency.dart';
import 'package:idlefit/models/daily_quest.dart';
import 'package:idlefit/models/quest_repo.dart';
import 'package:idlefit/models/quest_stats.dart';

class QuestCard extends ConsumerStatefulWidget {
  final Quest quest;
  final VoidCallback onClaim;

  @override
  ConsumerState<QuestCard> createState() => _QuestCardState();

  const QuestCard({super.key, required this.quest, required this.onClaim});
}

class _QuestCardState extends ConsumerState<QuestCard> {
  double progress = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final progress = await widget.quest.progress(
      ref.read(questStatsRepositoryProvider),
    );
    setState(() {
      this.progress = progress;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final progressPercent = (progress / widget.quest.requirement).clamp(
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
                    Row(
                      children: [
                        Text(
                          widget.quest.description,
                          style: theme.textTheme.titleMedium,
                        ),
                        if (widget.quest.questUnit.currencyType != null)
                          widget.quest.questUnit.currencyType!.iconWithSize(20),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Reward:', style: theme.textTheme.bodySmall),
                  Row(
                    children: [
                      Text(
                        widget.quest.rewardText,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      widget.quest.rewardCurrency.iconWithSize(20),
                    ],
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
              if (widget.quest.dateClaimed != null)
                Text(
                  'Completed ${_formatDate(DateTime.fromMillisecondsSinceEpoch(widget.quest.dateClaimed!))}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                )
              else if (progress >= widget.quest.requirement)
                ElevatedButton(
                  onPressed: widget.onClaim,
                  child: const Text('Claim'),
                ),
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
