import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:idlefit/models/currency.dart';
import 'package:idlefit/providers/coin_generator_provider.dart';
import 'package:idlefit/providers/currency_provider.dart';
import '../constants.dart';
import '../util.dart';

class GameStatsCard extends StatelessWidget {
  const GameStatsCard({super.key});

  @override
  Widget build(BuildContext context) {
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
            const _DynamicStats(),
            const _StaticStats(),
          ],
        ),
      ),
    );
  }
}

class _DynamicStats extends ConsumerWidget {
  const _DynamicStats();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencies = ref.watch(currencyNotifierProvider);
    final coin = currencies[CurrencyType.coin];

    // Calculate passive output
    final passiveOutput = ref
        .watch(coinGeneratorNotifierProvider)
        .when(
          data: (generators) {
            double output = 0;
            for (final generator in generators) {
              output += generator.output;
            }
            return output;
          },
          loading: () => 0.0,
          error: (_, __) => 0.0,
        );

    return _StatListTile(
      icon: Constants.coinIcon,
      iconColor: Colors.amber,
      title: 'Gains',
      current: coin?.count ?? 0,
      max: coin?.max ?? 0,
      perSecond: passiveOutput,
      earned: coin?.totalEarned ?? 0,
      spent: coin?.totalSpent ?? 0,
    );
  }
}

class _StaticStats extends ConsumerWidget {
  const _StaticStats();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencies = ref.watch(currencyNotifierProvider);
    final energy = currencies[CurrencyType.energy];
    final space = currencies[CurrencyType.space];

    return Column(
      children: [
        _StatListTile(
          icon: Constants.energyIcon,
          iconColor: Colors.greenAccent,
          title: 'Energy',
          current: energy?.count ?? 0,
          max: energy?.max ?? 0,
          earned: energy?.totalEarned ?? 0,
          spent: energy?.totalSpent ?? 0,
        ),
        _StatListTile(
          icon: Constants.spaceIcon,
          iconColor: Colors.blueAccent,
          title: 'Space',
          current: space?.count ?? 0,
          max: space?.max ?? 0,
          earned: space?.totalEarned ?? 0,
          spent: space?.totalSpent ?? 0,
        ),
      ],
    );
  }
}

class _StatListTile extends StatelessWidget {
  const _StatListTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.current,
    required this.max,
    this.perSecond,
    required this.earned,
    required this.spent,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final double current;
  final double max;
  final double? perSecond;
  final double earned;
  final double spent;

  String _formatted(double value) {
    return title == "Energy"
        ? durationNotation(value)
        : toLettersNotation(value);
  }

  @override
  Widget build(BuildContext context) {
    String titleText = title;
    if (perSecond != null) {
      titleText = '$title • ${toLettersNotation(perSecond!)}/s';
    }
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(titleText),
      subtitle: Row(
        children: [Text('${_formatted(current)}/${_formatted(max)}')],
      ),
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('Earned: ${_formatted(earned)}'),
          Text('Spent: ${_formatted(spent)}'),
        ],
      ),
    );
  }
}
