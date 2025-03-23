import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:idlefit/models/currency.dart';
import 'package:idlefit/providers/currency_provider.dart';
import '../helpers/util.dart';

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
          ],
        ),
      ),
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
