import 'package:flutter/material.dart';
import 'package:idlefit/models/health_data_entry.dart';
import 'package:idlefit/models/health_data_repo.dart';
import 'package:idlefit/services/object_box.dart';
import 'package:idlefit/util.dart';
import 'package:provider/provider.dart';

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

  const _HealthStatsTile({
    super.key,
    required this.icon,
    required this.title,
    required this.today,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
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
            Text(
              'Health Activity',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const Divider(),
            _HealthStatsTile(
              icon: Icons.directions_walk,
              title: "Steps",
              today: today.steps,
              total: total.steps,
            ),
            _HealthStatsTile(
              icon: Icons.local_fire_department,
              title: "Calories Burned",
              today: today.calories,
              total: total.calories,
            ),
            _HealthStatsTile(
              icon: Icons.fitness_center,
              title: "Exercise Minutes",
              today: today.exerciseMinutes,
              total: total.exerciseMinutes,
            ),
          ],
        ),
      ),
    );
  }
}
