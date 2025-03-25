import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:idlefit/models/quest_repo.dart';
import 'package:idlefit/models/quest_stats.dart';
import 'package:idlefit/helpers/util.dart';
import 'package:idlefit/widgets/card_button.dart';
import 'package:idlefit/providers/providers.dart';

class _HealthStatsTile extends StatelessWidget {
  final QuestAction action;
  final QuestUnit unit;
  final IconData icon;
  final String title;
  final Color? iconColor;
  final QuestStatsRepository repository;

  const _HealthStatsTile({
    required this.action,
    required this.unit,
    required this.icon,
    required this.title,
    required this.repository,
    this.iconColor,
  });

  Future<(double, double)> _fetchStats(QuestStatsRepository repository) async {
    final today = repository.getProgress(action, unit, todayTimestamp);
    final total = repository.getTotalProgress(action, unit);
    return (today, total).wait;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<(double, double)>(
      future: _fetchStats(repository),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ListTile(
            leading: Icon(icon, color: iconColor),
            title: Text(title),
            subtitle: const Text('Today: loading...'),
          );
        } else if (snapshot.hasError || !snapshot.hasData) {
          return ListTile(
            leading: Icon(icon, color: iconColor),
            title: Text(title),
            subtitle: const Text('Error loading'),
          );
        }
        final (today, total) = snapshot.data!;
        return ListTile(
          leading: Icon(icon, color: iconColor, size: 28),
          title: Text(title),
          subtitle: Text('Today: ${toLettersNotation(today)}'),
          trailing: Text('Total: ${toLettersNotation(total)}'),
        );
      },
    );
  }
}

class _HealthDateLabels extends StatelessWidget {
  final Future<DateTime?> earliestFetch;
  final int latest;

  const _HealthDateLabels({required this.latest, required this.earliestFetch});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DateTime?>(
      future: earliestFetch,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text('Loading...');
        } else if (snapshot.hasError || !snapshot.hasData) {
          return const Text('Error loading health data');
        }
        final earliest = snapshot.data;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Last synced: ${formatRelativeTime(DateTime.fromMillisecondsSinceEpoch(latest))}',
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
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(questStatsRepositoryProvider);

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
                      'Health Stats',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    _HealthDateLabels(
                      latest: ref.read(gameStateProvider).healthLastSynced,
                      earliestFetch: repository.firstHealthDay(),
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
            _HealthStatsTile(
              action: QuestAction.walk,
              unit: QuestUnit.steps,
              icon: Icons.directions_walk,
              title: "Steps",
              iconColor: Colors.blue,
              repository: repository,
            ),
            _HealthStatsTile(
              action: QuestAction.burn,
              unit: QuestUnit.calories,
              icon: Icons.local_fire_department,
              title: "Calories Burned",
              iconColor: Colors.red,
              repository: repository,
            ),
          ],
        ),
      ),
    );
  }
}
