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
    final questStatsRepo = ref.watch(questStatsRepositoryProvider);
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
            _StateListTile(
              action: QuestAction.purchase,
              unit: QuestUnit.generator,
              repo: questStatsRepo,
            ),
            _StateListTile(
              action: QuestAction.upgrade,
              unit: QuestUnit.generator,
              repo: questStatsRepo,
            ),
            _StateListTile(
              action: QuestAction.upgrade,
              unit: QuestUnit.shopItem,
              repo: questStatsRepo,
            ),
          ],
        ),
      ),
    );
  }
}

class _StateListTile extends StatelessWidget {
  const _StateListTile({
    required this.action,
    required this.unit,
    required this.repo,
  });

  final QuestAction action;
  final QuestUnit unit;
  final QuestStatsRepository repo;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<(double, double)>(
      future: Future.wait([
        repo.getProgress(action, unit, todayTimestamp),
        repo.getTotalProgress(action, unit),
      ]).then((values) => (values[0], values[1])),
      builder: (context, AsyncSnapshot<(double, double)> snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final (progress, total) = snapshot.data!;
        if (total < 1) {
          return const SizedBox.shrink();
        }

        return ListTile(
          title: Text(
            "${unit.name.capitalize()}s ${action.name.capitalize()}d",
          ),
          subtitle: Text("Today: ${progress.floor()}"),
          trailing: Text("Total: ${total.floor()}"),
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
        children: [Text('Spent: ${_formatted(currency.totalSpent)}')],
      ),
    );
  }
}
