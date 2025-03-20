import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:idlefit/models/currency.dart';
import 'package:idlefit/models/quest_repo.dart';
import 'package:idlefit/models/quest_stats.dart';
import 'package:idlefit/providers/currency_provider.dart';
import 'package:idlefit/widgets/quest_card.dart';

class QuestList extends ConsumerStatefulWidget {
  final QuestType questType;
  const QuestList({super.key, required this.questType});

  @override
  ConsumerState<QuestList> createState() => _QuestListState();
}

class _QuestListState extends ConsumerState<QuestList> {
  List<Quest> quests = [];
  late QuestRepository _questRepo;

  @override
  void initState() {
    super.initState();
    _questRepo = ref.read(questRepositoryProvider);
  }

  void onClaim(Quest quest) {
    // assuming only coins and spaces are rewarded
    final currencyProvider =
        quest.rewardCurrency == CurrencyType.coin
            ? ref.read(coinProvider.notifier)
            : ref.read(spaceProvider.notifier);
    _questRepo.claimQuest(
      quest,
      ref.read(questStatsRepositoryProvider),
      currencyProvider,
    );
    setState(() {});
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
              widget.questType.displayName,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const Divider(),
            FutureBuilder<List<Quest>>(
              future: () async {
                final List<Quest> quests = await _questRepo.getQuests(
                  widget.questType,
                );
                return quests;
              }(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.data == null) {
                  return const Center(child: Text('No quests found'));
                }
                final quests = snapshot.data!;
                return Column(
                  children:
                      quests.map((quest) {
                        return QuestCard(
                          quest: quest,
                          onClaim: () => onClaim(quest),
                        );
                      }).toList(), // Convert Iterable to List
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
