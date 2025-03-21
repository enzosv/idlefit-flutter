import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:idlefit/helpers/constants.dart';
import 'package:idlefit/models/currency.dart';
import 'package:idlefit/providers/currency_provider.dart';
import 'package:idlefit/providers/game_state_provider.dart';
import 'package:idlefit/widgets/current_coins.dart';
import '../helpers/util.dart';

class CoinsDisplay extends ConsumerWidget {
  const CoinsDisplay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coins = ref.watch(coinProvider);
    final gameStateNotifier = ref.watch(gameStateProvider.notifier);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            CurrencyType.coin.iconWithSize(32),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              // mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CurrentCoins(
                      key: CurrentCoins.globalKey,
                      currentCoins: toLettersNotation(coins.count),
                    ),
                    Text(
                      '/${toLettersNotation(coins.max)}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      '${toLettersNotation(gameStateNotifier.passiveOutput)}/s ',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {},
                      label: Text(""),
                      icon: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Icon(Icons.play_circle),
                          Text("Boost"),
                        ],
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Constants.primaryColor,
                        foregroundColor: Colors.white,
                        iconSize: 12,
                        padding: const EdgeInsets.only(left: 4),
                        visualDensity: VisualDensity.compact,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        minimumSize: const Size(0, 0),
                        side: BorderSide(color: CurrencyType.coin.color),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class CurrencyWidget extends ConsumerWidget {
  final CurrencyType currencyType;
  const CurrencyWidget({super.key, required this.currencyType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider =
        currencyType == CurrencyType.space
            ? ref.watch(spaceProvider)
            : ref.watch(energyProvider);
    final count =
        currencyType == CurrencyType.space
            ? toLettersNotation(provider.count)
            : durationNotation(provider.count);
    final max =
        currencyType == CurrencyType.space
            ? toLettersNotation(provider.max)
            : durationNotation(provider.max);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        currencyType.iconWithSize(20),
        const SizedBox(width: 4),
        Text(count, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text('/$max'),
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
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 12),
      decoration: BoxDecoration(color: Constants.barColor),
      child: Flex(
        direction: Axis.horizontal,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        // crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 1,
            child: IconButton(
              iconSize: 32,
              onPressed: () {},
              icon: const Icon(Icons.menu),
            ),
          ),
          Expanded(flex: 3, child: CoinsDisplay()),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                CurrencyWidget(currencyType: CurrencyType.energy),
                CurrencyWidget(currencyType: CurrencyType.space),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
