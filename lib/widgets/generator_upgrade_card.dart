import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:idlefit/models/coin_generator.dart';
import 'package:idlefit/models/currency.dart';
import 'package:idlefit/helpers/util.dart';
import 'common_card.dart';
import 'package:idlefit/providers/providers.dart';

class GeneratorUpgradeCard extends ConsumerWidget {
  final CoinGenerator generator;

  const GeneratorUpgradeCard({super.key, required this.generator});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coinGeneratorNotifier = ref.read(generatorProvider.notifier);
    final icon = CurrencyType.coin.iconWithSize(16);

    final additionalInfo = <Widget>[
      Row(
        children: [
          Text(
            'Output: ${toLettersNotation(generator.output)} ',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          icon,
          Text('/s', style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    ];
    final isMaxLevel = generator.level >= generator.maxLevel;

    if (!isMaxLevel) {
      additionalInfo.add(
        Row(
          children: [
            Text(
              'Next level: ${toLettersNotation(generator.outputAtLevel(generator.level + 1))} ',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            icon,
            Text('/s', style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      );
    }

    final space = ref.watch(spaceProvider);
    return CommonCard(
      title: generator.name,
      rightText: 'Level: ${generator.level}/${generator.maxLevel}',
      additionalInfo: additionalInfo,
      cost: isMaxLevel ? null : generator.upgradeCost,
      affordable: space.count >= generator.upgradeCost,
      costCurrency: isMaxLevel ? null : CurrencyType.space,
      buttonText: isMaxLevel ? 'MAXED' : 'Upgrade',
      onButtonPressed:
          (isMaxLevel || space.count < generator.upgradeCost)
              ? null
              : () => coinGeneratorNotifier.upgradeGenerator(generator, ref),
    );
  }
}
