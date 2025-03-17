import 'dart:async';
import 'dart:io';
import 'package:health/health.dart';
import 'package:flutter/material.dart';
import 'package:idlefit/models/health_data_entry.dart';
import 'package:idlefit/models/health_data_repo.dart';
import 'package:idlefit/providers/daily_health_provider.dart';
import 'package:idlefit/providers/game_state_provider.dart';
import 'package:objectbox/objectbox.dart';

class HealthService {
  final Health health = Health();
  final Box<HealthDataEntry> box;

  HealthService({required this.box});

  // Health data types we want to access
  final List<HealthDataType> types = [
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.STEPS,
    HealthDataType.EXERCISE_TIME,
  ];

  Future<void> initialize() async {
    try {
      requestAuthorization();
    } catch (e) {
      debugPrint('Error initializing health service: $e');
    }
  }

  Future<bool> requestAuthorization() async {
    try {
      // Get permissions
      bool? hasPermissions = await health.hasPermissions(types);

      // If not authorized yet, request permissions
      if (hasPermissions == null || !hasPermissions) {
        return await health.requestAuthorization(types);
      }

      return hasPermissions;
    } catch (e) {
      debugPrint('Error requesting health authorization: $e');
      return false;
    }
  }

  Future<List<HealthDataEntry>> queryHealthEntries(
    DateTime startTime,
    endTime,
  ) async {
    print("getting health data from $startTime to $endTime");
    final newData = await health.getHealthDataFromTypes(
      types: types,
      startTime: startTime,
      endTime: endTime,
    );

    // Debug logging for available data types
    // print("Available data types: ${newData.map((d) => d.type.name).toSet()}");
    // print("Data sources: ${newData.map((d) => d.sourceName).toSet()}");

    Map<String, double> grouped = {};
    for (final entry in newData) {
      final value = (entry.value as NumericHealthValue).numericValue.toDouble();
      // print("${entry.type.name} from ${entry.sourceName}: $value");
      grouped[entry.sourceId] = (grouped[entry.sourceId] ?? 0) + value;
    }
    if (grouped.keys.isEmpty) {
      return [];
    }
    // apple chooses via user priority (https://support.apple.com/en-ca/108779)
    // we choose by which has the most data
    String bestSource = grouped.keys.reduce(
      (a, b) => grouped[a]! > grouped[b]! ? a : b,
    );
    print("best source: $bestSource");

    // Convert to ObjectBox model
    final entries =
        health
            .removeDuplicates(newData)
            .where((e) => e.sourceId == bestSource)
            .map(
              (e) => HealthDataEntry(
                timestamp: e.dateFrom.millisecondsSinceEpoch,
                duration:
                    e.dateTo.millisecondsSinceEpoch -
                    e.dateFrom.millisecondsSinceEpoch,
                value: (e.value as NumericHealthValue).numericValue.toDouble(),
                type: e.type.name,
              ),
            )
            .toList();
    double totalSteps = 0;
    double totalCalories = 0;
    for (final entry in entries) {
      switch (entry.type) {
        case "STEPS":
          totalSteps += entry.value;
        case "ACTIVE_ENERGY_BURNED":
          totalCalories += entry.value;
      }
    }
    print("total steps: $totalSteps");
    print("total calories: $totalCalories");
    return entries;
  }

  Future<double> _getDailyHealth(
    DateTime startOfDay,
    endOfDay,
    HealthDataType type,
  ) async {
    final data = await health.getHealthDataFromTypes(
      startTime: startOfDay,
      endTime: endOfDay,
      types: [type],
    );
    // Group data by time ranges and sources
    Map<int, Map<String, double>> timeRangeData = {};

    for (final entry in data) {
      final timeKey = entry.dateFrom.millisecondsSinceEpoch;
      timeRangeData[timeKey] ??= {};

      final value = (entry.value as NumericHealthValue).numericValue.toDouble();
      timeRangeData[timeKey]![entry.sourceId] =
          (timeRangeData[timeKey]![entry.sourceId] ?? 0) + value;
    }

    // For each time range, select the best source if there are multiple
    double total = 0.0;
    for (final timeRange in timeRangeData.entries) {
      if (timeRange.value.length == 1) {
        // Only one source for this time range, use it
        total += timeRange.value.values.first;
      } else {
        // Multiple sources, choose the one with higher value
        total += timeRange.value.values.reduce((a, b) => a > b ? a : b);
      }
    }

    return total;
  }

  Future<void> syncDay(
    DateTime day,
    DailyHealthNotifier dailyHealthNotifier,
  ) async {
    final startOfDay = DateTime(day.year, day.month, day.day);
    final endOfDay = DateTime(day.year, day.month, day.day, 23, 59, 59, 999);
    final steps = // https://github.com/cph-cachet/flutter-plugins/issues/1066#issuecomment-2545521041 iOS aggregates but android doesn't
        await (Platform.isIOS
            ? health.getTotalStepsInInterval(startOfDay, endOfDay)
            : _getDailyHealth(startOfDay, endOfDay, HealthDataType.STEPS));

    final calories = await _getDailyHealth(
      startOfDay,
      endOfDay,
      HealthDataType.ACTIVE_ENERGY_BURNED,
    );
    final exerciseMinutes = await _getDailyHealth(
      startOfDay,
      endOfDay,
      HealthDataType.EXERCISE_TIME,
    );

    dailyHealthNotifier.reset(
      startOfDay.millisecondsSinceEpoch,
      DailyHealth()
        ..steps = steps?.toInt() ?? 0
        ..caloriesBurned = calories
        ..exerciseMinutes = exerciseMinutes,
    );
  }

  Future<void> syncHealthData(
    GameStateNotifier gameStateNotifier,
    DailyHealthNotifier dailyHealthNotifier,
  ) async {
    // experiment
    final now = DateTime.now();
    await [
      syncDay(now, dailyHealthNotifier),
      syncDay(now.subtract(const Duration(days: 1)), dailyHealthNotifier),
    ].wait;
    return;

    final repo = HealthDataRepo(box: box);
    final syncStart = await repo.syncStart();
    final entries = await queryHealthEntries(syncStart, DateTime.now());
    if (entries.isEmpty) {
      return;
    }
    final newEntries = await repo.newFromList(entries, syncStart);
    if (newEntries.isEmpty) {
      return;
    }
    // not async. we want to wait for the data to be written to the database
    box.putMany(newEntries);

    print("new: ${newEntries.length}, from: ${entries.length}");
    updateHealthState(newEntries, gameStateNotifier);
  }

  void updateHealthState(
    List<HealthDataEntry> newEntries,
    GameStateNotifier gameStateNotifier,
  ) {
    double steps = 0;
    double calories = 0;
    double exercise = 0;
    for (final entry in newEntries) {
      if (entry.type == HealthDataType.STEPS.name) {
        steps += entry.value;
      } else if (entry.type == HealthDataType.ACTIVE_ENERGY_BURNED.name) {
        calories += entry.value;
      } else if (entry.type == HealthDataType.EXERCISE_TIME.name) {
        exercise += entry.value;
      }
    }
    if (calories == 0 && steps == 0 && exercise == 0) {
      return;
    }

    print("got new health data $steps $calories $exercise");
    gameStateNotifier.convertHealthStats(steps, calories, exercise);
  }

  // TODO: function to sync health data in the background
}
