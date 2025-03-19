import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:idlefit/helpers/constants.dart';
import 'package:idlefit/models/coin_generator.dart';
import 'package:idlefit/providers/currency_provider.dart';
import 'package:idlefit/providers/generator_provider.dart';
import 'package:idlefit/helpers/util.dart';
import 'common_card.dart';

class GeneratorUpgradeCard extends ConsumerWidget {
  final CoinGenerator generator;

  const GeneratorUpgradeCard({super.key, required this.generator});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coinGeneratorNotifier = ref.read(generatorProvider.notifier);

    final additionalInfo = <Widget>[
      Row(
        children: [
          Text(
            'Output: ${toLettersNotation(generator.output)} ',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Icon(Constants.coinIcon, color: Colors.amber, size: 16),
          Text('/s', style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    ];

    if (generator.level < generator.maxLevel) {
      additionalInfo.add(
        Row(
          children: [
            Text(
              'Next level: ${toLettersNotation(generator.outputAtLevel(generator.level + 1))} ',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Icon(Constants.coinIcon, color: Colors.amber, size: 16),
            Text('/s', style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      );
    }

    final isMaxLevel = generator.level >= generator.maxLevel;
    final coins = ref.watch(coinProvider);
    return CommonCard(
      title: generator.name,
      rightText: 'Level: ${generator.level}/${generator.maxLevel}',
      additionalInfo: additionalInfo,
      cost: isMaxLevel ? null : generator.upgradeCost,
      affordable: coins.count >= generator.upgradeCost,
      costIcon: isMaxLevel ? null : Constants.coinIcon,
      buttonText: isMaxLevel ? 'MAXED' : 'Upgrade',
      onButtonPressed:
          (isMaxLevel || coins.count < generator.upgradeCost)
              ? null
              : () => coinGeneratorNotifier.upgradeGenerator(generator),
    );
  }
}
