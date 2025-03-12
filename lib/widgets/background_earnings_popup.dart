import 'package:flutter/material.dart';
import '../util.dart';

class BackgroundEarningsPopup extends StatelessWidget {
  final msToMins = 60000;
  final Map<String, double> earnings;

  const BackgroundEarningsPopup({super.key, required this.earnings});

  @override
  Widget build(BuildContext context) {
    final double energyEarned = (earnings['energy_earned'] ?? 0) / msToMins;
    final double spaceEarned = earnings['space'] ?? 0;
    final double coinsEarned = earnings['coins'] ?? 0;
    final double energySpent = (earnings['energy_spent'] ?? 0) / msToMins;
    if (coinsEarned < 1 && spaceEarned < 1 && energyEarned < 1) {
      return const SizedBox.shrink();
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'While You Were Away',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            if (coinsEarned > 0) const SizedBox(height: 24),
            if (coinsEarned > 0)
              _buildEarningRow(
                context,
                icon: Icons.monetization_on,
                label: 'Earned',
                value: toLettersNotation(coinsEarned),
                color: Colors.amber,
              ),

            if (spaceEarned > 0) const SizedBox(height: 16),
            if (spaceEarned > 0)
              _buildEarningRow(
                context,
                icon: Icons.space_dashboard,
                label: 'Earned',
                value: toLettersNotation(spaceEarned),
                color: Colors.blueAccent,
              ),
            if (energyEarned > 0) const SizedBox(height: 16),
            if (energyEarned > 0)
              _buildEarningRow(
                context,
                icon: Icons.bolt,
                label: 'Earned',
                value: durationNotation(energyEarned * msToMins),
                color: Colors.greenAccent,
              ),
            if (energySpent > 0) const SizedBox(height: 16),
            if (energySpent > 0)
              _buildEarningRow(
                context,
                icon: Icons.bolt,
                label: 'Spent',
                value: durationNotation(energySpent * msToMins),
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
  }

  Widget _buildEarningRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
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
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
