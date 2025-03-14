import 'package:flutter/material.dart';
import 'package:idlefit/helpers/constants.dart';
import 'package:idlefit/models/background_activity.dart';
import '../helpers/util.dart';

class BackgroundEarningsPopup extends StatelessWidget {
  final msToMins = 60000;
  final BackgroundActivity backgroundActivity;

  const BackgroundEarningsPopup({super.key, required this.backgroundActivity});

  @override
  Widget build(BuildContext context) {
    print("backgroundActivity: ${backgroundActivity.coinsEarned}");
    if (backgroundActivity.coinsEarned < 1 &&
        backgroundActivity.spaceEarned < 1) {
      return const SizedBox.shrink();
    }
    final double energyEarned = backgroundActivity.energyEarned / msToMins;
    final double energySpent = backgroundActivity.energySpent / msToMins;
    if (energyEarned < 1 && energySpent < 1) {
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
            if (backgroundActivity.coinsEarned > 0) const SizedBox(height: 24),
            if (backgroundActivity.coinsEarned > 0)
              _buildEarningRow(
                context,
                icon: Constants.coinIcon,
                label: 'Earned',
                value: toLettersNotation(backgroundActivity.coinsEarned),
                color: Colors.amber,
              ),

            if (backgroundActivity.spaceEarned > 0) const SizedBox(height: 16),
            if (backgroundActivity.spaceEarned > 0)
              _buildEarningRow(
                context,
                icon: Constants.spaceIcon,
                label: 'Earned',
                value: toLettersNotation(backgroundActivity.spaceEarned),
                color: Colors.blueAccent,
              ),
            if (energyEarned > 0) const SizedBox(height: 16),
            if (energyEarned > 0)
              _buildEarningRow(
                context,
                icon: Constants.energyIcon,
                label: 'Earned',
                value: durationNotation(energyEarned * msToMins),
                color: Colors.greenAccent,
              ),
            if (energySpent > 0) const SizedBox(height: 16),
            if (energySpent > 0)
              _buildEarningRow(
                context,
                icon: Constants.energyIcon,
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
