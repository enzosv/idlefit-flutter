import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:idlefit/models/currency.dart';
import 'package:idlefit/models/quest_repo.dart';
import 'package:idlefit/providers/currency_provider.dart';
import 'package:idlefit/widgets/quest_card.dart';
import 'package:idlefit/providers/providers.dart';

// cache quests to be used on widget rebuild
final _questsProvider = FutureProvider.family
    .autoDispose<List<Quest>, QuestType>((ref, questType) async {
      final repository = ref.read(questRepositoryProvider);
      return repository.getQuests(questType);
    });

class QuestList extends ConsumerStatefulWidget {
  const QuestList({super.key, required this.questType});

  final QuestType questType;

  @override
  ConsumerState<QuestList> createState() => _QuestListState();
}

class _QuestListState extends ConsumerState<QuestList>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // Prevent unnecessary rebuilds

  CurrencyNotifier _rewardNotifier(WidgetRef ref, Quest quest) {
    switch (quest.rewardCurrency) {
      case CurrencyType.coin:
        return ref.read(coinProvider.notifier);
      case CurrencyType.space:
        return ref.read(spaceProvider.notifier);
      case CurrencyType.energy:
        return ref.read(energyProvider.notifier);
      default:
        assert(
          false,
          "unhandled reward notifier for currency type ${quest.rewardCurrency}",
        );
        return ref.read(coinProvider.notifier);
    }
  }

  void _onClaim(WidgetRef ref, Quest quest) {
    final currencyProvider = _rewardNotifier(ref, quest);

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
      ref.invalidate(_questsProvider(widget.questType));
      ref.invalidate(questStatsRepositoryProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    final questsAsync = ref.watch(_questsProvider(widget.questType));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.questType.displayName,
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
