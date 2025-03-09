import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/game_state.dart';
import '../util.dart';

class CurrencyBar extends StatelessWidget {
  const CurrencyBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade800,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildCurrencyItem(
                context,
                icon: Icons.monetization_on,
                label: 'Coins',
                value:
                    '${toLettersNotation(gameState.coins.count)}/${toLettersNotation(gameState.coins.max)}',
                color: Colors.amber,
              ),
              _buildCurrencyItem(
                context,
                icon: Icons.diamond,
                label: 'Gems',
                value:
                    '${toLettersNotation(gameState.gems.count)}/${toLettersNotation(gameState.gems.max)}',
                color: Colors.purpleAccent,
              ),
              _buildCurrencyItem(
                context,
                icon: Icons.bolt,
                label: 'Energy',
                value:
                    '${(gameState.energy.count / 60000).toStringAsFixed(0)}mins/${(gameState.energy.max / 3600000).toStringAsFixed(0)}hrs',
                color: Colors.greenAccent,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCurrencyItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 28),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),

        // const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 16)),
      ],
    );
  }
}
