import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:idlefit/models/currency.dart';
import 'package:idlefit/models/quest_repo.dart';
import 'package:idlefit/models/quest_stats.dart';
import 'package:idlefit/providers/currency_provider.dart';
import 'package:idlefit/widgets/quest_card.dart';

// cache quests to be used on widget rebuild
final _questsProvider = FutureProvider.family
    .autoDispose<List<Quest>, QuestType>((ref, questType) async {
      final repository = ref.read(questRepositoryProvider);
      return repository.getQuests(questType);
    });

class QuestList extends ConsumerWidget {
  final QuestType questType;
  const QuestList({super.key, required this.questType});

  void _onClaim(WidgetRef ref, Quest quest) {
    final currencyProvider =
        quest.rewardCurrency == CurrencyType.coin
            ? ref.read(coinProvider.notifier)
            : ref.read(spaceProvider.notifier);

    Future(
      () => ref
          .read(questRepositoryProvider)
          .claimQuest(
            quest,
            ref.read(questStatsRepositoryProvider),
            currencyProvider,
          ),
    ).then((_) {
      // Invalidate both quests and stats to force refresh
      ref.invalidate(_questsProvider(questType));
      ref.invalidate(questStatsRepositoryProvider);
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questsAsync = ref.watch(_questsProvider(questType));

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
            questsAsync.when(
              data: (quests) {
                if (quests.isEmpty) {
                  return const Center(child: Text('No quests available'));
                }
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
              loading: () => const Center(child: CircularProgressIndicator()),
              error:
                  (_, __) => const Center(child: Text('Failed to load quests')),
            ),
          ],
        ),
      ),
    );
  }
}
