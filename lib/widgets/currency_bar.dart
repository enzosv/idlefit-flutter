import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:idlefit/helpers/constants.dart';
import 'package:idlefit/models/currency.dart';
import 'package:idlefit/providers/currency_provider.dart';
import 'package:idlefit/providers/game_state_provider.dart';
import 'package:idlefit/widgets/current_coins.dart';
import '../helpers/util.dart';

class CoinsInfo extends ConsumerWidget {
  const CoinsInfo({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameStateNotifier = ref.watch(gameStateProvider.notifier);
    final coins = ref.watch(coinProvider);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            '/${toLettersNotation(coins.max)}',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            '${toLettersNotation(gameStateNotifier.passiveOutput)}/s',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class CoinsDisplay extends StatelessWidget {
  const CoinsDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CurrencyType.coin.iconWithSize(24),
            const SizedBox(width: 4),
            CurrentCoins(key: CurrentCoins.globalKey),
          ],
        ),
        const SizedBox(height: 4),
        const CoinsInfo(),
      ],
    );
  }
}

class EnergyCurrency extends ConsumerWidget {
  const EnergyCurrency({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final energy = ref.watch(energyProvider);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        CurrencyType.energy.iconWithSize(20),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            '${durationNotation(energy.count)}/${durationNotation(energy.max)}',
            style: const TextStyle(color: Colors.white, fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class SpaceCurrency extends ConsumerWidget {
  const SpaceCurrency({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final space = ref.watch(spaceProvider);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        CurrencyType.space.iconWithSize(20),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            '${toLettersNotation(space.count)}/${toLettersNotation(space.max)}',
            style: const TextStyle(color: Colors.white, fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class CurrencyBar extends StatelessWidget {
  static final GlobalKey currencyBarKey = GlobalKey();
  const CurrencyBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: currencyBarKey,
      padding: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
      decoration: BoxDecoration(color: Constants.barColor),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Expanded(flex: 3, child: EnergyCurrency()),
          const Expanded(flex: 4, child: CoinsDisplay()),
          const Expanded(flex: 3, child: SpaceCurrency()),
        ],
      ),
    );
  }
}
