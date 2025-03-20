import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:idlefit/models/daily_quest.dart';
import 'package:idlefit/models/quest_stats.dart';
import 'package:idlefit/helpers/util.dart';
import 'package:idlefit/providers/game_state_provider.dart';
import 'package:idlefit/widgets/card_button.dart';
import 'package:idlefit/main.dart';

class HealthStatsCard extends ConsumerStatefulWidget {
  const HealthStatsCard({super.key});

  @override
  ConsumerState<HealthStatsCard> createState() => _HealthStatsCardState();
}

class _HealthStatsTile extends StatelessWidget {
  final QuestAction action;
  final QuestUnit unit;
  final IconData icon;
  final String title;
  final Color? iconColor;
  final QuestStatsRepository questStatsRepository;
  const _HealthStatsTile({
    required this.questStatsRepository,
    required this.action,
    required this.unit,
    required this.icon,
    required this.title,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<(double, double)>(
      future: () async {
        final [today, total] =
            await [
              questStatsRepository.getProgress(action, unit, todayTimestamp),
              questStatsRepository.getTotalProgress(action, unit),
            ].wait;
        return (today, total);
      }(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return ListTile(
            leading: Icon(icon, color: iconColor),
            title: Text(title),
            subtitle: Text('Today: 0'),
            trailing: Text('Total: 0'),
          );
        }
        final (today, total) = snapshot.data!;
        return ListTile(
          leading: Icon(icon, color: iconColor),
          title: Text(title),
          subtitle: Text('Today: ${toLettersNotation(today)}'),
          trailing: Text('Total: ${toLettersNotation(total)}'),
        );
      },
    );
  }
}

class _HealthStatsCardState extends ConsumerState<HealthStatsCard> {
  late QuestStatsRepository _questStatsRepository;

  @override
  void initState() {
    super.initState();
    _questStatsRepository = ref.read(questStatsRepositoryProvider);
  }

  @override
  Widget build(BuildContext context) {
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
                    FutureBuilder<(DateTime?, DateTime?)>(
                      future: () async {
                        final earliest =
                            await _questStatsRepository.firstHealthDay();
                        final latest =
                            await _questStatsRepository.lastHealthDay();
                        return (latest, earliest);
                      }(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return Text(
                            'Last sync: Never',
                            style: Theme.of(context).textTheme.bodySmall,
                          );
                        }
                        final (latest, earliest) = snapshot.data!;
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
                    ),
                  ],
                ),
                CardButton(
                  icon: Icons.sync,
                  text: 'Sync',
                  onPressed: () async {
                    await ref
                        .read(healthServiceProvider)
                        .syncHealthData(
                          ref.read(gameStateProvider.notifier),
                          _questStatsRepository,
                        );
                    setState(
                      () {},
                    ); // Trigger rebuild to refresh last sync time
                  },
                ),
              ],
            ),
            const Divider(),
            _HealthStatsTile(
              questStatsRepository: _questStatsRepository,
              action: QuestAction.walk,
              unit: QuestUnit.steps,
              icon: Icons.directions_walk,
              title: "Steps",
              iconColor: Colors.blue,
            ),
            _HealthStatsTile(
              questStatsRepository: _questStatsRepository,
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
