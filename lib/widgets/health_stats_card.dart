import 'package:flutter/material.dart';
import 'package:idlefit/models/health_data_entry.dart';
import 'package:idlefit/models/health_data_repo.dart';
import 'package:idlefit/services/object_box.dart';
import 'package:idlefit/util.dart';
import 'package:provider/provider.dart';
import 'package:idlefit/services/health_service.dart';
import 'package:idlefit/services/game_state.dart';
import 'package:idlefit/widgets/card_button.dart';

class HealthStatsCard extends StatefulWidget {
  const HealthStatsCard({super.key});

  @override
  _HealthStatsCardState createState() => _HealthStatsCardState();
}

class _HealthStatsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final double today;
  final double total;
  final Color? iconColor;

  const _HealthStatsTile({
    super.key,
    required this.icon,
    required this.title,
    required this.today,
    required this.total,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(title),
      subtitle: Text('Today: ${toLettersNotation(today)}'),
      trailing: Text('Total: ${toLettersNotation(total)}'),
    );
  }
}

class _HealthStatsCardState extends State<HealthStatsCard> {
  HealthStats today = HealthStats();
  HealthStats total = HealthStats();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final healthBox =
        Provider.of<ObjectBox>(
          context,
          listen: false,
        ).store.box<HealthDataEntry>();
    final healthRepo = HealthDataRepo(box: healthBox);
    final (healthToday, healthTotal) =
        await (healthRepo.today(DateTime.now()), healthRepo.total()).wait;
    setState(() {
      today = healthToday;
      total = healthTotal;
    });
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
                        final box =
                            Provider.of<ObjectBox>(
                              context,
                              listen: false,
                            ).store.box<HealthDataEntry>();
                        final repo = HealthDataRepo(box: box);
                        final latest = await repo.latestEntryDate();
                        final earliest = await repo.earliestEntryDate();
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
                              'Lastest data: ${formatRelativeTime(latest)}',
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
                    final healthService = Provider.of<HealthService>(
                      context,
                      listen: false,
                    );
                    final gameState = Provider.of<GameState>(
                      context,
                      listen: false,
                    );
                    final objectBox = Provider.of<ObjectBox>(
                      context,
                      listen: false,
                    );
                    await healthService.syncHealthData(objectBox, gameState);
                    setState(
                      () {},
                    ); // Trigger rebuild to refresh last sync time
                    await _fetchData(); // Refresh displayed data
                  },
                ),
              ],
            ),
            const Divider(),
            _HealthStatsTile(
              icon: Icons.directions_walk,
              title: "Steps",
              today: today.steps,
              total: total.steps,
              iconColor: Colors.blue,
            ),
            _HealthStatsTile(
              icon: Icons.local_fire_department,
              title: "Calories Burned",
              today: today.calories,
              total: total.calories,
              iconColor: Colors.red,
            ),
          ],
        ),
      ),
    );
  }
}
