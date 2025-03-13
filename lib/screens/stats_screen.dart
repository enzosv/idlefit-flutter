import 'package:flutter/material.dart';
import 'package:idlefit/constants.dart';
import 'package:idlefit/widgets/achievement_list.dart';
import 'package:idlefit/widgets/health_stats_card.dart';
import 'package:idlefit/widgets/game_stats_card.dart';
import 'package:idlefit/widgets/banner_ad_widget.dart';
import 'package:idlefit/widgets/daily_quest_list.dart';
import 'package:idlefit/services/game_state.dart';
import 'package:provider/provider.dart';
import 'package:idlefit/util.dart';
import 'package:idlefit/screens/time_based_stats_screen.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final gameState = Provider.of<GameState>(context);
    final stats = gameState.getGameStats();

    return Scaffold(
      appBar: AppBar(title: const Text('Game Statistics')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatSection(context, 'Generator Statistics', [
                _buildStatRow(
                  'Manual Clicks',
                  stats['manual_generator_clicks'].toString(),
                ),
                _buildStatRow(
                  'Generators Purchased',
                  stats['generators_purchased'].toString(),
                ),
                _buildStatRow(
                  'Generators Upgraded',
                  stats['generators_upgraded'].toString(),
                ),
                _buildStatRow(
                  'Generators Unlocked',
                  stats['generators_unlocked'].toString(),
                ),
              ]),
              const SizedBox(height: 24),
              _buildStatSection(context, 'Currency Statistics', [
                _buildStatRow(
                  'Passive Coins Earned',
                  formatNumber(stats['passive_coins_earned']),
                ),
                _buildStatRow(
                  'Manual Coins Earned',
                  formatNumber(stats['manual_coins_earned']),
                ),
                _buildStatRow(
                  'Total Coins Earned',
                  formatNumber(
                    stats['passive_coins_earned'] +
                        stats['manual_coins_earned'],
                  ),
                ),
              ]),
              const SizedBox(height: 24),
              _buildStatSection(context, 'Shop Statistics', [
                _buildStatRow(
                  'Shop Items Upgraded',
                  stats['shop_items_upgraded'].toString(),
                ),
              ]),
              const SizedBox(height: 24),
              _buildStatSection(context, 'Health Statistics', [
                _buildStatRow(
                  'Total Steps',
                  formatNumber(stats['total_steps']),
                ),
                _buildStatRow(
                  'Total Calories Burned',
                  formatNumber(stats['total_calories']),
                ),
                _buildStatRow(
                  'Total Exercise Minutes',
                  durationNotation(stats['total_exercise_minutes'] * 60000),
                ),
              ]),
              const SizedBox(height: 24),
              _buildStatSection(context, 'Miscellaneous', [
                _buildStatRow('Ad Views', stats['ad_view_count'].toString()),
              ]),
              const SizedBox(height: 32),
              Center(
                child: Column(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TimeBasedStatsScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.timeline),
                      label: const Text('View Time-Based Statistics'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        _showResetConfirmationDialog(context, gameState);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text('Reset Statistics'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatSection(
    BuildContext context,
    String title,
    List<Widget> rows,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const Divider(),
        ...rows,
      ],
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showResetConfirmationDialog(BuildContext context, GameState gameState) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Reset Statistics'),
            content: const Text(
              'Are you sure you want to reset all statistics? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  final stats = gameState.getGameStats();
                  gameState.resetStats();
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Statistics have been reset')),
                  );
                },
                child: const Text('Reset'),
              ),
            ],
          ),
    );
  }
}

// Helper function to format numbers with commas
String formatNumber(dynamic value) {
  if (value is int) {
    return value.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  } else if (value is double) {
    return value
        .toStringAsFixed(1)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }
  return value.toString();
}
