import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:idlefit/models/daily_quest.dart';
import 'package:idlefit/models/quest_stats.dart';
import 'package:idlefit/helpers/util.dart';
import 'package:idlefit/providers/game_state_provider.dart';
import 'package:idlefit/widgets/card_button.dart';
import 'package:idlefit/main.dart';

// Provider for health stats data
final _healthStatsProvider = FutureProvider.autoDispose<(DateTime?, DateTime?)>(
  (ref) async {
    final repository = ref.read(questStatsRepositoryProvider);
    final earliest = await repository.firstHealthDay();
    final latest = await repository.lastHealthDay();
    return (latest, earliest);
  },
);

// Provider for health tile stats
final _healthTileStatsProvider = FutureProvider.family
    .autoDispose<(double, double), (QuestAction, QuestUnit)>((
      ref,
      params,
    ) async {
      final (action, unit) = params;
      final repository = ref.read(questStatsRepositoryProvider);
      final [today, total] =
          await [
            repository.getProgress(action, unit, todayTimestamp),
            repository.getTotalProgress(action, unit),
          ].wait;
      return (today, total);
    });

class _HealthStatsTile extends ConsumerWidget {
  final QuestAction action;
  final QuestUnit unit;
  final IconData icon;
  final String title;
  final Color? iconColor;

  const _HealthStatsTile({
    required this.action,
    required this.unit,
    required this.icon,
    required this.title,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.read(_healthTileStatsProvider((action, unit)));

    return statsAsync.when(
      data: (data) {
        final (today, total) = data;
        return ListTile(
          leading: Icon(icon, color: iconColor),
          title: Text(title),
          subtitle: Text('Today: ${toLettersNotation(today)}'),
          trailing: Text('Total: ${toLettersNotation(total)}'),
        );
      },
      loading:
          () => ListTile(
            leading: Icon(icon, color: iconColor),
            title: Text(title),
            subtitle: const Center(child: CircularProgressIndicator()),
            trailing: const Center(child: CircularProgressIndicator()),
          ),
      error:
          (_, __) => ListTile(
            leading: Icon(icon, color: iconColor),
            title: Text(title),
            subtitle: const Text('Error loading stats'),
            trailing: const Text(''),
          ),
    );
  }
}

class HealthStatsCard extends ConsumerWidget {
  const HealthStatsCard({super.key});

  Future<void> _syncHealthData(WidgetRef ref) async {
    await ref
        .read(healthServiceProvider)
        .syncHealthData(
          ref.read(gameStateProvider.notifier),
          ref.read(questStatsRepositoryProvider),
        );
    // Invalidate both providers to refresh all data
    ref.invalidate(_healthStatsProvider);
    ref.invalidate(_healthTileStatsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthStats = ref.read(_healthStatsProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Health Activity',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    healthStats.when(
                      data: (data) {
                        final (latest, earliest) = data;
                        if (latest == null) {
                          return Text(
                            'Last sync: Never',
                            style: Theme.of(context).textTheme.bodySmall,
                          );
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Last synced: ${formatRelativeTime(latest)}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            if (earliest != null)
                              Text(
                                'Started: ${formatRelativeTime(earliest)}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                          ],
                        );
                      },
                      loading: () => const Text('Loading...'),
                      error: (_, __) => const Text('Error loading health data'),
                    ),
                  ],
                ),
                CardButton(
                  icon: Icons.sync,
                  text: 'Sync',
                  onPressed: () => _syncHealthData(ref),
                ),
              ],
            ),
            const Divider(),
            const _HealthStatsTile(
              action: QuestAction.walk,
              unit: QuestUnit.steps,
              icon: Icons.directions_walk,
              title: "Steps",
              iconColor: Colors.blue,
            ),
            const _HealthStatsTile(
              action: QuestAction.burn,
              unit: QuestUnit.calories,
              icon: Icons.local_fire_department,
              title: "Calories Burned",
              iconColor: Colors.red,
            ),
          ],
        ),
      ),
    );
  }
}
