import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:idlefit/models/currency.dart';
import 'package:idlefit/models/quest_repo.dart';
import 'package:idlefit/models/quest_stats.dart';
import 'package:idlefit/providers/currency_provider.dart';
import 'package:idlefit/widgets/quest_card.dart';

class QuestList extends ConsumerStatefulWidget {
  const QuestList({super.key});

  @override
  ConsumerState<QuestList> createState() => _QuestListState();
}

class _QuestListState extends ConsumerState<QuestList> {
  List<Quest> quests = [];
  late QuestRepository _questRepo;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    _questRepo = ref.read(questRepositoryProvider);
    final achievements = await _questRepo.getAchievements();
    setState(() {
      quests = achievements;
    });
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
              'Achievements',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const Divider(),
            ...quests.map((quest) {
              return QuestCard(quest: quest, onClaim: () => onClaim(quest));
            }),
          ],
        ),
      ),
    );
  }
}
