import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:idlefit/models/currency.dart';
import 'package:idlefit/models/game_stats.dart';
import 'package:idlefit/models/quest_repo.dart';
import 'package:idlefit/providers/currency_provider.dart';
import 'package:idlefit/main.dart'; // Import providers from main.dart
import 'package:idlefit/providers/game_stats_provider.dart';
import 'package:idlefit/widgets/quest_card.dart';

class QuestList extends ConsumerStatefulWidget {
  const QuestList({super.key});

  @override
  ConsumerState<QuestList> createState() => _QuestListState();
}

class _QuestListState extends ConsumerState<QuestList> {
  List<Quest> quests = [];
  late QuestRepository _questRepo;
  late GameStats _gameStats;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final objectBox = ref.read(objectBoxProvider);
    final questBox = objectBox.store.box<Quest>();
    _questRepo = QuestRepository(questBox);
    final achievements = await _questRepo.getAchievements();
    _gameStats = await ref.read(gameStatsProvider);
    setState(() {
      quests = achievements;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quests', style: Theme.of(context).textTheme.headlineSmall),
            const Divider(),
            ...quests.map((quest) {
              final currencyProvider =
                  quest.rewardCurrency == CurrencyType.coin
                      ? ref.read(coinProvider.notifier)
                      : ref.read(spaceProvider.notifier);
              return QuestCard(
                quest: quest,
                progress: quest.progress(_gameStats),
                onClaim:
                    () => _questRepo.claimQuest(
                      quest,
                      _gameStats,
                      currencyProvider,
                    ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
