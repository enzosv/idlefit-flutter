import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:idlefit/constants.dart';
import 'package:idlefit/widgets/current_coins.dart';
import '../services/game_state.dart';
import '../util.dart';
import '../models/shop_items.dart';

class CoinsInfo extends ConsumerWidget {
  const CoinsInfo({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameStateProvider);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            '/${toLettersNotation(gameState.coins.max)}',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            '${toLettersNotation(gameState.passiveOutput)}/s',
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
            Icon(Constants.coinIcon, color: Colors.amber, size: 24),
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
    final gameState = ref.watch(gameStateProvider);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Constants.energyIcon, color: Colors.greenAccent, size: 20),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            '${durationNotation(gameState.energy.count)}/${durationNotation(gameState.energy.max)}',
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
    final gameState = ref.watch(gameStateProvider);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Constants.spaceIcon, color: Colors.blueAccent, size: 20),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            '${toLettersNotation(gameState.space.count)}/${toLettersNotation(gameState.space.max)}',
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
