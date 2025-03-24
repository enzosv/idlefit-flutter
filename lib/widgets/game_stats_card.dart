import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:idlefit/models/currency.dart';
import 'package:idlefit/models/quest_repo.dart';
import 'package:idlefit/models/quest_stats.dart';
import 'package:idlefit/providers/currency_provider.dart';
import '../helpers/util.dart';

class GameStatsCard extends ConsumerWidget {
  const GameStatsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questStatsRepo = ref.read(questStatsRepositoryProvider);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Game Stats',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const Divider(),
            _CurrencyListTile(currency: ref.watch(coinProvider)),
            _CurrencyListTile(currency: ref.watch(energyProvider)),
            _CurrencyListTile(currency: ref.watch(spaceProvider)),
            const Divider(),
            _GeneratorStatsListTile(repo: questStatsRepo),
            const Divider(),
            _OtherStatsListTile(repo: questStatsRepo),
          ],
        ),
      ),
    );
  }
}

class _OtherStatsListTile extends StatelessWidget {
  const _OtherStatsListTile({required this.repo});

  final QuestStatsRepository repo;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<(int, int)>(
      future: Future.wait([
        repo.getTotalProgress(QuestAction.upgrade, QuestUnit.shopItem),
        repo.getTotalProgress(QuestAction.watch, QuestUnit.ad),
      ]).then((values) => (values[0].floor(), values[1].floor())),
      builder: (context, AsyncSnapshot<(int, int)> snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }
        final (shop, ads) = snapshot.data!;
        return ListTile(
          title: Text("Others"),
          subtitle: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [Text("Upgrades: $shop"), Text("Ads Watched: $ads")],
          ),
        );
      },
    );
  }
}

class _GeneratorStatsListTile extends StatelessWidget {
  const _GeneratorStatsListTile({required this.repo});

  final QuestStatsRepository repo;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<(int, int, int)>(
      future: Future.wait([
        repo.getTotalProgress(QuestAction.purchase, QuestUnit.generator),
        repo.getTotalProgress(QuestAction.upgrade, QuestUnit.generator),
        repo.getTotalProgress(QuestAction.tap, QuestUnit.generator),
      ]).then(
        (values) => (values[0].floor(), values[1].floor(), values[2].floor()),
      ),
      builder: (context, AsyncSnapshot<(int, int, int)> snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }
        final (purchase, upgrade, tap) = snapshot.data!;
        return ListTile(
          title: Text("Exercises"),
          subtitle: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Reps: $purchase"),
              Text("Upgrades: $upgrade"),
              Text("Taps: $tap"),
            ],
          ),
        );
      },
    );
  }
}

class _CurrencyListTile extends StatelessWidget {
  const _CurrencyListTile({required this.currency});

  final Currency currency;

  String _formatted(double value) {
    return currency.type == CurrencyType.energy
        ? durationNotation(value)
        : toLettersNotation(value);
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: currency.type.iconWithSize(28),
      title: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Earned:"),
          Text(_formatted(currency.totalEarned)),
        ],
      ),
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'Spent:\n${_formatted(currency.totalSpent)}',
            textAlign: TextAlign.end,
          ),
        ],
      ),
    );
  }
}
