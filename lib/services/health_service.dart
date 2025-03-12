import 'dart:async';
import 'package:health/health.dart';
import 'package:flutter/material.dart';
import 'package:idlefit/models/health_data_entry.dart';
import 'package:idlefit/models/health_data_repo.dart';
import 'package:idlefit/services/object_box.dart';
import 'game_state.dart';
import 'dart:math';

class HealthService {
  final Health health = Health();

  // Health data types we want to access
  final List<HealthDataType> types = [
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.STEPS,
    HealthDataType.EXERCISE_TIME,
  ];

  bool _isAuthorized = false;

  Future<void> initialize() async {
    try {
      _isAuthorized = await requestAuthorization();
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

  // check calories burned time
  // if lots burned in short time, count that as exercise time
  // any minute over 120bpm?
  double estimateExerciseTime(List<HealthDataPoint> healthData) {
    final data =
        healthData
            .where((data) => data.type == HealthDataType.ACTIVE_ENERGY_BURNED)
            .toList();

    if (data.isEmpty) {
      return 0;
    }

    Map<String, double> grouped = {};
    for (final entry in data) {
      final value = (entry.value as NumericHealthValue).numericValue.toDouble();

      final start = entry.dateFrom.millisecondsSinceEpoch;
      final end = entry.dateTo.millisecondsSinceEpoch;
      int duration = end - start;
      final bpm = estimateBPM(value, duration);
      duration = max(1, duration);
      if (bpm > 120) {
        grouped[entry.sourceName] = (grouped[entry.sourceName] ?? 0) + duration;
      }
    }
    String? bestSource =
        grouped.keys.isEmpty
            ? null
            : grouped.keys.reduce((a, b) => grouped[a]! > grouped[b]! ? a : b);
    return bestSource != null ? grouped[bestSource]! / 1000 / 60 : 0;
  }

  // use METs (Metabolic Equivalent of Task) or caloric expenditure formulas.
  double estimateBPM(
    double caloriesBurned,
    int durationMs, {
    double weightKg = 70,
    bool isMale = true,
  }) {
    if (durationMs <= 0) return 0; // Avoid division by zero
    double durationMinutes = durationMs / 60000.0;
    double k =
        isMale ? 0.6309 : 0.4472; // Different coefficient for males & females

    // Estimate heart rate using rearranged formula

    // Calories per minute= ((heartrate * weight * K)/1000)*5
    // cpm = 5*(hr*w*k)/1000
    // (1000*cpm)/5 = hr*w*k
    // 1000*cpm/5/w/k=hr
    print("cpm: ${caloriesBurned * 1000 / durationMinutes}");
    return (1000 * caloriesBurned) / (durationMinutes * 5 * weightKg * k);
    // return ((caloriesBurned / (durationMinutes * 5)) * 1000) / (weightKg * k);
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

    Map<String, double> grouped = {};
    for (final entry in newData) {
      final value = (entry.value as NumericHealthValue).numericValue.toDouble();
      grouped[entry.sourceId] = (grouped[entry.sourceId] ?? 0) + value;
    }
    String? bestSource =
        grouped.keys.isEmpty
            ? null
            : grouped.keys.reduce((a, b) => grouped[a]! > grouped[b]! ? a : b);

    // Convert to ObjectBox model
    return newData
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
  }

  Future<void> syncHealthData(
    ObjectBox objectBoxService,
    GameState gameState,
  ) async {
    // final store = await openStore(); // Initialize ObjectBox
    final box = objectBoxService.store.box<HealthDataEntry>();

    final repo = HealthDataRepo(box: box);
    final latestTime = await repo.latestEntryDate();

    final now = DateTime.now();

    // Fetch data from 10 minutes before the last saved time to now
    // to handle late recordings
    final startTime =
        latestTime?.subtract(Duration(minutes: 10)) ??
        DateTime(now.year, now.month, now.day);

    final entries = await queryHealthEntries(startTime, now);
    final newEntries = await repo.newFromList(entries, startTime);
    if (newEntries.isEmpty) {
      return;
    }

    box.putMany(newEntries);

    print("new: ${newEntries.length}, from: ${entries.length}");
    updateHealthState(newEntries, gameState);
  }

  void updateHealthState(
    List<HealthDataEntry> newEntries,
    GameState gameState,
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
    gameState.convertHealthStats(steps, calories, exercise);
  }
}
