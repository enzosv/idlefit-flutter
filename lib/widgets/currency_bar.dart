import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:idlefit/models/currency.dart';
import 'package:idlefit/widgets/boost_button.dart';
import 'package:idlefit/widgets/current_coins.dart';
import '../helpers/util.dart';
import 'package:idlefit/providers/providers.dart';

const _smallStyle = TextStyle(fontSize: 12, color: Colors.white70);

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
            CurrencyType.coin.iconWithSize(28),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CurrentCoins(
                      key: CurrentCoins.globalKey,
                      currentCoins: toLettersNotation(coins.count),
                    ),
                    Text(
                      '/${toLettersNotation(coins.max)}',
                      style: _smallStyle,
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      '${toLettersNotation(gameStateNotifier.passiveOutput)}/s ',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    const BoostButton(),
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
        Text(
          count,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        Text('/$max', style: _smallStyle),
      ],
    );
  }
}

class CurrencyBar extends ConsumerWidget {
  final VoidCallback onMenuPressed;
  final bool isSidebarOpen;

  const CurrencyBar({
    super.key,
    required this.onMenuPressed,
    required this.isSidebarOpen,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        IconButton(
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Icon(
              isSidebarOpen ? Icons.close : Icons.menu,
              key: ValueKey(isSidebarOpen),
            ),
          ),
          iconSize: 28,
          onPressed: onMenuPressed,
        ),
        const SizedBox(width: 8),
        const Expanded(flex: 3, child: CoinsDisplay()),
        Expanded(
          flex: 2,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              CurrencyWidget(currencyType: CurrencyType.energy),
              CurrencyWidget(currencyType: CurrencyType.space),
            ],
          ),
        ),
      ],
    );
  }
}
