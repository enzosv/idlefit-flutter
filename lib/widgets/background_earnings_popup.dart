import 'package:flutter/material.dart';
import '../util.dart';

class BackgroundEarningsPopup extends StatelessWidget {
  final Map<String, double> earnings;

  const BackgroundEarningsPopup({super.key, required this.earnings});

  @override
  Widget build(BuildContext context) {
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
            const SizedBox(height: 24),
            _buildEarningRow(
              context,
              icon: Icons.monetization_on,
              label: 'Coins Earned',
              value: earnings['coins'] ?? 0,
              color: Colors.amber,
            ),
            const SizedBox(height: 16),
            _buildEarningRow(
              context,
              icon: Icons.bolt,
              label: 'Energy Earned',
              value: earnings['energy_earned'] ?? 0,
              color: Colors.greenAccent,
            ),
            const SizedBox(height: 8),
            _buildEarningRow(
              context,
              icon: Icons.bolt_outlined,
              label: 'Energy Spent',
              value: earnings['energy_spent'] ?? 0,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 16),
            _buildEarningRow(
              context,
              icon: Icons.space_dashboard,
              label: 'Space Earned',
              value: earnings['space'] ?? 0,
              color: Colors.blueAccent,
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
          toLettersNotation(value),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
