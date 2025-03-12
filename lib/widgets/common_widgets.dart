import 'package:flutter/material.dart';
import 'package:idlefit/constants.dart';
import 'package:idlefit/widgets/current_coins.dart';
import 'package:provider/provider.dart';
import '../services/game_state.dart';
import '../util.dart';
import '../models/shop_items.dart';

class CoinsInfo extends StatelessWidget {
  const CoinsInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, child) {
        // Calculate total coins per second
        double totalCoinsPerSecond = 0;
        for (final generator in gameState.coinGenerators) {
          totalCoinsPerSecond += generator.output;
        }

        // Apply coin multiplier from upgrades
        double coinMultiplier = 1.0;
        for (final item in gameState.shopItems) {
          if (item.effect == ShopItemEffect.coinMultiplier) {
            coinMultiplier += item.effectValue * item.level;
          }
        }
        totalCoinsPerSecond *= coinMultiplier;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '/${toLettersNotation(gameState.coins.max)}',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(width: 8),
            Text(
              '${toLettersNotation(totalCoinsPerSecond)}/s',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        );
      },
    );
  }
}

class CoinsDisplay extends StatelessWidget {
  const CoinsDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.monetization_on, color: Colors.amber, size: 20),
        const SizedBox(width: 4),
        CurrentCoins(key: CurrentCoins.globalKey),
        const SizedBox(width: 4),
        const CoinsInfo(),
      ],
    );
  }
}

class OtherCurrencies extends StatelessWidget {
  const OtherCurrencies({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildCurrencyItem(
              context,
              icon: Icons.diamond,
              value:
                  '${toLettersNotation(gameState.gems.count)}/${toLettersNotation(gameState.gems.max)}',
              color: Colors.purpleAccent,
            ),
            _buildCurrencyItem(
              context,
              icon: Icons.bolt,
              value:
                  '${durationNotation(gameState.energy.count)}/${durationNotation(gameState.energy.max)}',
              color: Colors.greenAccent,
            ),
            _buildCurrencyItem(
              context,
              icon: Icons.space_dashboard,
              value:
                  '${toLettersNotation(gameState.space.count)}/${toLettersNotation(gameState.space.max)}',
              color: Colors.blueAccent,
            ),
          ],
        );
      },
    );
  }

  Widget _buildCurrencyItem(
    BuildContext context, {
    required IconData icon,
    required String value,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 14)),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CoinsDisplay(),
          const SizedBox(height: 8),
          const OtherCurrencies(),
        ],
      ),
    );
  }
}
