import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:idlefit/constants.dart';
import 'package:idlefit/models/currency.dart';
import 'package:idlefit/providers/coin_generator_provider.dart';
import 'package:idlefit/providers/currency_provider.dart';
import 'package:idlefit/widgets/current_coins.dart';
import '../util.dart';

/// Provides the maximum coin value
final coinMaxProvider = Provider<double>((ref) {
  final currencies = ref.watch(currencyNotifierProvider);
  return currencies[CurrencyType.coin]?.max ?? 0;
});

/// Provides the total passive coin generation output
final passiveOutputProvider = Provider<double>((ref) {
  return ref
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
});

/// Widget that displays information about coins: max amount and passive generation
class CoinsInfo extends ConsumerWidget {
  const CoinsInfo({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coinMax = ref.watch(coinMaxProvider);
    final passiveOutput = ref.watch(passiveOutputProvider);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            '/${toLettersNotation(coinMax)}',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            '${toLettersNotation(passiveOutput)}/s',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Widget that displays current coins with icon and additional info
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

/// Provides energy currency data
final energyCurrencyProvider = Provider<Map<String, dynamic>>((ref) {
  final currencies = ref.watch(currencyNotifierProvider);
  final energy = currencies[CurrencyType.energy];
  return {'count': energy?.count ?? 0, 'max': energy?.max ?? 0};
});

/// Widget that displays energy currency
class EnergyCurrency extends ConsumerWidget {
  const EnergyCurrency({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final energy = ref.watch(energyCurrencyProvider);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Constants.energyIcon, color: Colors.greenAccent, size: 20),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            '${durationNotation(energy['count'])}/${durationNotation(energy['max'])}',
            style: const TextStyle(color: Colors.white, fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Provides space currency data
final spaceCurrencyProvider = Provider<Map<String, dynamic>>((ref) {
  final currencies = ref.watch(currencyNotifierProvider);
  final space = currencies[CurrencyType.space];
  return {'count': space?.count ?? 0, 'max': space?.max ?? 0};
});

/// Widget that displays space currency
class SpaceCurrency extends ConsumerWidget {
  const SpaceCurrency({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final space = ref.watch(spaceCurrencyProvider);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Constants.spaceIcon, color: Colors.blueAccent, size: 20),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            '${toLettersNotation(space['count'])}/${toLettersNotation(space['max'])}',
            style: const TextStyle(color: Colors.white, fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Bar that displays all currencies
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
