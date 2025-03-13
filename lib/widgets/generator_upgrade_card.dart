import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:idlefit/constants.dart';
import 'package:idlefit/models/coin_generator.dart';
import 'package:idlefit/models/currency.dart';
import 'package:idlefit/providers/currency_provider.dart';
import 'package:idlefit/providers/game_engine_provider.dart';
import 'package:idlefit/util.dart';
import 'common_card.dart';

class GeneratorUpgradeCard extends ConsumerWidget {
  final CoinGenerator generator;

  const GeneratorUpgradeCard({super.key, required this.generator});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencies = ref.watch(currencyNotifierProvider);
    final coins = currencies[CurrencyType.coin];
    final space = currencies[CurrencyType.space];

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

    if (!generator.isUnlocked) {
      final spaceCount = space?.count ?? 0;
      final canAfford = spaceCount >= generator.upgradeUnlockCost;

      return CommonCard(
        title: generator.name,
        rightText: 'Level: ${generator.level}/${generator.maxLevel}',
        additionalInfo: additionalInfo,
        cost: generator.upgradeUnlockCost,
        affordable: canAfford,
        costIcon: Constants.spaceIcon,
        buttonText: 'Unlock',
        onButtonPressed:
            canAfford
                ? () => ref
                    .read(gameEngineProvider.notifier)
                    .unlockGenerator(generator.tier)
                : null,
      );
    }

    final isMaxLevel = generator.level >= generator.maxLevel;
    final coinCount = coins?.count ?? 0;
    final canAfford = coinCount >= generator.upgradeCost;

    return CommonCard(
      title: generator.name,
      rightText: 'Level: ${generator.level}/${generator.maxLevel}',
      additionalInfo: additionalInfo,
      cost: isMaxLevel ? null : generator.upgradeCost,
      affordable: canAfford,
      costIcon: isMaxLevel ? null : Constants.coinIcon,
      buttonText: isMaxLevel ? 'MAXED' : 'Upgrade',
      onButtonPressed:
          (isMaxLevel || !canAfford)
              ? null
              : () => ref
                  .read(gameEngineProvider.notifier)
                  .upgradeGenerator(generator.tier),
    );
  }
}
