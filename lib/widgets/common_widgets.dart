import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../game/game_state.dart';

class CurrencyBar extends StatelessWidget {
  const CurrencyBar({Key? key}) : super(key: key);

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
                color: Colors.black.withOpacity(0.2),
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
                value: gameState.coins.floor().toString(),
                color: Colors.amber,
              ),
              _buildCurrencyItem(
                context,
                icon: Icons.diamond,
                label: 'Gems',
                value: gameState.gems.toString(),
                color: Colors.purpleAccent,
              ),
              _buildCurrencyItem(
                context,
                icon: Icons.bolt,
                label: 'Energy',
                value: (gameState.energy / 60000).floor().toString(),
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
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 16)),
      ],
    );
  }
}
