import 'package:flutter/material.dart';
import 'package:idlefit/services/game_state.dart';
import 'package:provider/provider.dart';
import 'package:idlefit/util.dart';
import 'package:intl/intl.dart';

class TimeBasedStatsScreen extends StatefulWidget {
  const TimeBasedStatsScreen({Key? key}) : super(key: key);

  @override
  State<TimeBasedStatsScreen> createState() => _TimeBasedStatsScreenState();
}

class _TimeBasedStatsScreenState extends State<TimeBasedStatsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedPeriod = 7; // Default to 7 days/weeks/months

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Time-Based Statistics'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Daily'),
            Tab(text: 'Weekly'),
            Tab(text: 'Monthly'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Time Period:'),
                DropdownButton<int>(
                  value: _selectedPeriod,
                  items: const [
                    DropdownMenuItem(value: 7, child: Text('Last 7')),
                    DropdownMenuItem(value: 14, child: Text('Last 14')),
                    DropdownMenuItem(value: 30, child: Text('Last 30')),
                    DropdownMenuItem(value: 90, child: Text('Last 90')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedPeriod = value;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDailyStatsView(),
                _buildWeeklyStatsView(),
                _buildMonthlyStatsView(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyStatsView() {
    final gameState = Provider.of<GameState>(context);
    final dailyStats = gameState.getStatsForLastNDays(_selectedPeriod);

    if (dailyStats.isEmpty) {
      return const Center(child: Text('No daily statistics available yet.'));
    }

    return _buildStatsView(dailyStats, 'day');
  }

  Widget _buildWeeklyStatsView() {
    final gameState = Provider.of<GameState>(context);
    final weeklyStats = gameState.getStatsForLastNWeeks(_selectedPeriod);

    if (weeklyStats.isEmpty) {
      return const Center(child: Text('No weekly statistics available yet.'));
    }

    return _buildStatsView(weeklyStats, 'week');
  }

  Widget _buildMonthlyStatsView() {
    final gameState = Provider.of<GameState>(context);
    final monthlyStats = gameState.getStatsForLastNMonths(_selectedPeriod);

    if (monthlyStats.isEmpty) {
      return const Center(child: Text('No monthly statistics available yet.'));
    }

    return _buildStatsView(monthlyStats, 'month');
  }

  Widget _buildStatsView(
    List<Map<String, dynamic>> statsList,
    String periodType,
  ) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCard(statsList, periodType),
            const SizedBox(height: 24),
            _buildStatsTable(statsList, periodType),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    List<Map<String, dynamic>> statsList,
    String periodType,
  ) {
    // Calculate totals
    double totalCoins = 0;
    double totalSteps = 0;
    double totalCalories = 0;
    double totalClicks = 0;
    double totalAdViews = 0;

    for (final stats in statsList) {
      totalCoins +=
          (stats['passive_coins_earned'] ?? 0.0) +
          (stats['manual_coins_earned'] ?? 0.0);
      totalSteps += stats['steps'] ?? 0.0;
      totalCalories += stats['calories'] ?? 0.0;
      totalClicks += (stats['manual_generator_clicks'] ?? 0).toDouble();
      totalAdViews += (stats['ad_view_count'] ?? 0).toDouble();
    }

    // Calculate averages
    final count = statsList.length;
    final avgCoins = totalCoins / count;
    final avgSteps = totalSteps / count;
    final avgCalories = totalCalories / count;
    final avgClicks = totalClicks / count;

    String periodName;
    if (periodType == 'day') {
      periodName = 'Daily';
    } else if (periodType == 'week') {
      periodName = 'Weekly';
    } else {
      periodName = 'Monthly';
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$periodName Summary',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Divider(),
            _buildSummaryRow('Total Coins Earned', formatNumber(totalCoins)),
            _buildSummaryRow(
              'Average Coins per $periodType',
              formatNumber(avgCoins),
            ),
            _buildSummaryRow('Total Steps', formatNumber(totalSteps)),
            _buildSummaryRow(
              'Average Steps per $periodType',
              formatNumber(avgSteps),
            ),
            _buildSummaryRow(
              'Total Calories Burned',
              formatNumber(totalCalories),
            ),
            _buildSummaryRow(
              'Average Calories per $periodType',
              formatNumber(avgCalories),
            ),
            _buildSummaryRow(
              'Total Generator Clicks',
              formatNumber(totalClicks),
            ),
            _buildSummaryRow(
              'Average Clicks per $periodType',
              formatNumber(avgClicks),
            ),
            _buildSummaryRow('Total Ad Views', formatNumber(totalAdViews)),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildStatsTable(
    List<Map<String, dynamic>> statsList,
    String periodType,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detailed Statistics',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: _buildTableColumns(periodType),
            rows: _buildTableRows(statsList, periodType),
          ),
        ),
      ],
    );
  }

  List<DataColumn> _buildTableColumns(String periodType) {
    String periodLabel;
    if (periodType == 'day') {
      periodLabel = 'Date';
    } else if (periodType == 'week') {
      periodLabel = 'Week';
    } else {
      periodLabel = 'Month';
    }

    return [
      DataColumn(label: Text(periodLabel)),
      const DataColumn(label: Text('Coins')),
      const DataColumn(label: Text('Steps')),
      const DataColumn(label: Text('Calories')),
      const DataColumn(label: Text('Clicks')),
      const DataColumn(label: Text('Ad Views')),
    ];
  }

  List<DataRow> _buildTableRows(
    List<Map<String, dynamic>> statsList,
    String periodType,
  ) {
    final rows = <DataRow>[];

    for (final stats in statsList.reversed) {
      final timestamp = stats['period_start'] as int;
      final date = DateTime.fromMillisecondsSinceEpoch(timestamp);

      String periodLabel;
      if (periodType == 'day') {
        periodLabel = DateFormat('MM/dd/yyyy').format(date);
      } else if (periodType == 'week') {
        periodLabel = 'Week ${DateFormat('w, yyyy').format(date)}';
      } else {
        periodLabel = DateFormat('MMMM yyyy').format(date);
      }

      final totalCoins =
          (stats['passive_coins_earned'] ?? 0.0) +
          (stats['manual_coins_earned'] ?? 0.0);

      rows.add(
        DataRow(
          cells: [
            DataCell(Text(periodLabel)),
            DataCell(Text(formatNumber(totalCoins))),
            DataCell(Text(formatNumber(stats['steps'] ?? 0.0))),
            DataCell(Text(formatNumber(stats['calories'] ?? 0.0))),
            DataCell(Text(formatNumber(stats['manual_generator_clicks'] ?? 0))),
            DataCell(Text(formatNumber(stats['ad_view_count'] ?? 0))),
          ],
        ),
      );
    }

    return rows;
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
