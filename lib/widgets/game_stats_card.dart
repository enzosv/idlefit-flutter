import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:idlefit/models/currency.dart';
import 'package:idlefit/models/quest_repo.dart';
import '../helpers/util.dart';
import 'package:idlefit/providers/providers.dart';

// Cache providers for stats data
final _generatorStatsProvider = FutureProvider<(int, int, int)>((ref) async {
  final repo = ref.read(questStatsRepositoryProvider);
  final values = await Future.wait([
    repo.getTotalProgress(QuestAction.purchase, QuestUnit.generator),
    repo.getTotalProgress(QuestAction.upgrade, QuestUnit.generator),
    repo.getTotalProgress(QuestAction.tap, QuestUnit.generator),
  ]);
  return (values[0].floor(), values[1].floor(), values[2].floor());
});

final _otherStatsProvider = FutureProvider<(int, int)>((ref) async {
  final repo = ref.read(questStatsRepositoryProvider);
  final values = await Future.wait([
    repo.getTotalProgress(QuestAction.upgrade, QuestUnit.shopItem),
    repo.getTotalProgress(QuestAction.watch, QuestUnit.ad),
  ]);
  return (values[0].floor(), values[1].floor());
});

class GameStatsCard extends ConsumerWidget {
  const GameStatsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            _GeneratorStatsListTile(),
            const Divider(),
            _OtherStatsListTile(),
          ],
        ),
      ),
    );
  }
}

class _OtherStatsListTile extends ConsumerWidget {
  const _OtherStatsListTile();

  Widget _tile(int? upgrades, int? ads) {
    return ListTile(
      title: const Text("Others"),
      subtitle: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("Upgrades: ${upgrades ?? ""}"),
          Text("Ads Watched: ${ads ?? ""}"),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.read(_otherStatsProvider);

    return statsAsync.when(
      data: (data) {
        final (shop, ads) = data;
        return _tile(shop, ads);
      },
      loading: () => _tile(null, null),
      error: (_, __) => _tile(null, null),
    );
  }
}

class _GeneratorStatsListTile extends ConsumerWidget {
  const _GeneratorStatsListTile();

  Widget _tile(int? purchase, int? upgrade, int? tap) {
    return ListTile(
      title: const Text("Exercises"),
      subtitle: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("Reps: ${purchase ?? ""}"),
          Text("Upgrades: ${upgrade ?? ""}"),
          Text("Taps: ${tap ?? ""}"),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.read(_generatorStatsProvider);

    return statsAsync.when(
      data: (data) {
        final (purchase, upgrade, tap) = data;
        return _tile(purchase, upgrade, tap);
      },
      loading: () => _tile(null, null, null),
      error: (_, __) => _tile(null, null, null),
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
