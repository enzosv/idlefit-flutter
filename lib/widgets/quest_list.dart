import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:idlefit/models/currency.dart';
import 'package:idlefit/models/quest_repo.dart';
import 'package:idlefit/models/quest_stats.dart';
import 'package:idlefit/providers/currency_provider.dart';
import 'package:idlefit/widgets/quest_card.dart';

class QuestList extends ConsumerWidget {
  final QuestType questType;
  const QuestList({super.key, required this.questType});

  void _onClaim(WidgetRef ref, Quest quest) {
    final currencyProvider =
        quest.rewardCurrency == CurrencyType.coin
            ? ref.read(coinProvider.notifier)
            : ref.read(spaceProvider.notifier);

    ref
        .read(questRepositoryProvider)
        .claimQuest(
          quest,
          ref.read(questStatsRepositoryProvider),
          currencyProvider,
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              questType.displayName,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const Divider(),
            FutureBuilder<List<Quest>>(
              future: ref.read(questRepositoryProvider).getQuests(questType),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.data == null || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No quests available'));
                }
                final quests = snapshot.data!;
                return Column(
                  children:
                      quests.map((quest) {
                        return QuestCard(
                          quest: quest,
                          onClaim: () => _onClaim(ref, quest),
                        );
                      }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
