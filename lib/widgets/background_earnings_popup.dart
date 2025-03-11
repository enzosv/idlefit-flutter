import 'package:flutter/material.dart';
import '../util.dart';
import '../services/game_state.dart';
import 'package:provider/provider.dart';

class BackgroundEarningsPopup extends StatelessWidget {
  const BackgroundEarningsPopup({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, child) {
        final backgroundCurrencies = gameState.getBackgroundState();
        final energyEarned =
            (gameState.energy.count -
                (backgroundCurrencies['energy_earned'] ?? 0)) /
            600000;
        final spaceEarned =
            (gameState.space.count - (backgroundCurrencies['space'] ?? 0));
        final coinsEarned =
            gameState.coins.count - (backgroundCurrencies['coins'] ?? 0);
        final energySpent =
            (backgroundCurrencies['energy_spent'] ?? 0) / 600000;
        if (coinsEarned < 1 && spaceEarned < 1 && energyEarned < 1) {
          return const SizedBox.shrink();
        }
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Since You Were Gone',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                if (coinsEarned > 0) const SizedBox(height: 24),
                if (coinsEarned > 0)
                  _buildEarningRow(
                    context,
                    icon: Icons.monetization_on,
                    label: 'Coins Earned',
                    value: coinsEarned,
                    color: Colors.amber,
                  ),

                if (spaceEarned > 0) const SizedBox(height: 16),
                if (spaceEarned > 0)
                  _buildEarningRow(
                    context,
                    icon: Icons.space_dashboard,
                    label: 'Space Earned',
                    value: spaceEarned,
                    color: Colors.blueAccent,
                  ),
                if (energyEarned > 0) const SizedBox(height: 16),
                if (energyEarned > 0)
                  _buildEarningRow(
                    context,
                    icon: Icons.bolt,
                    label: 'Energy Earned',
                    value: energyEarned * 600000,
                    color: Colors.greenAccent,
                  ),
                if (energySpent > 0) const SizedBox(height: 16),
                if (energySpent > 0)
                  _buildEarningRow(
                    context,
                    icon: Icons.bolt,
                    label: 'Energy Spent',
                    value: energySpent * 600000,
                    color: Colors.redAccent,
                  ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade400,
                    foregroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Great!',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEarningRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required double value,
    required Color color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Text(label),
          ],
        ),
        Text(
          label == "Energy Spent" || label == "Energy Earned"
              ? durationNotation(value)
              : toLettersNotation(value),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
