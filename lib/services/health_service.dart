import 'dart:async';
import 'package:health/health.dart';
import 'package:flutter/material.dart';
import 'package:idlefit/game/health_data_entry.dart';
import 'package:idlefit/objectbox.g.dart';
import 'package:idlefit/services/object_box.dart';
import '../game/game_state.dart';
import 'dart:math';
import 'package:objectbox/objectbox.dart';

class HealthService {
  final Health health = Health();

  // Health data types we want to access
  final List<HealthDataType> types = [
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.STEPS,
    HealthDataType.EXERCISE_TIME,
  ];

  // Health data metrics
  int steps = 0;
  double caloriesBurned = 0;
  int exerciseMinutes = 0;

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

  double parseHealthData(
    List<HealthDataPoint> healthData,
    HealthDataType type,
  ) {
    final data = healthData.where((data) => data.type == type).toList();

    if (data.isEmpty) {
      return 0;
    }

    // there are many data sources. apple uses the most trusted one. we use the one with the most data.
    Map<String, double> grouped = {};
    for (final entry in data) {
      final value = (entry.value as NumericHealthValue).numericValue.toDouble();
      grouped[entry.sourceName] = (grouped[entry.sourceName] ?? 0) + value;
    }
    String? bestSource =
        grouped.keys.isEmpty
            ? null
            : grouped.keys.reduce((a, b) => grouped[a]! > grouped[b]! ? a : b);
    return bestSource != null ? grouped[bestSource]! : 0;
  }

  Future<(int, double, int, int)> queryHealthData(DateTime start, end) async {
    if (!_isAuthorized) return (0, 0.0, 0, 0);

    try {
      final healthData = await health.getHealthDataFromTypes(
        types: types,
        startTime: start,
        endTime: end,
      );

      healthData.sort((a, b) => a.dateTo.compareTo(b.dateTo));

      final latest = healthData.lastOrNull?.dateTo.millisecondsSinceEpoch ?? 0;

      // print('latest health data: ${healthData.last.dateTo}');

      final steps = parseHealthData(healthData, HealthDataType.STEPS);
      final caloriesBurned = parseHealthData(
        healthData,
        HealthDataType.ACTIVE_ENERGY_BURNED,
      );
      final exerciseMinutes = parseHealthData(
        healthData,
        HealthDataType.EXERCISE_TIME,
      );
      // TODO: if exercise minutes < 1,
      // final exerciseMinutes2 = estimateExerciseTime(healthData);
      // print('$exerciseMinutes vs $exerciseMinutes2');
      return (steps.round(), caloriesBurned, exerciseMinutes.round(), latest);
    } catch (e) {
      debugPrint('Error fetching health data: $e');
    }
    return (0, 0.0, 0, 0);
  }

  Future<void> collectHealthToday(GameState gameState, DateTime now) async {
    final todayStart = DateTime(now.year, now.month, now.day);
    final (
      newSteps,
      newCaloriesBurned,
      newExerciseMinutes,
      latestDataEpoch,
    ) = await queryHealthData(todayStart, now);
    steps = newSteps;
    caloriesBurned = newCaloriesBurned;
    exerciseMinutes = newExerciseMinutes;
    print("today: $steps, $caloriesBurned, $exerciseMinutes");
  }

  Future<void> collectHealth(GameState gameState) async {
    final now = DateTime.now();
    final promise = collectHealthToday(gameState, now);

    DateTime start;
    if (gameState.lastHealthSync > 0) {
      // start = DateTime(now.year, now.month, now.day);
      start = DateTime.fromMillisecondsSinceEpoch(
        gameState.lastHealthSync,
      ).subtract(
        Duration(minutes: 10),
      ); //subtract 10 minutes to capture late recording
    } else {
      start = DateTime(
        now.year,
        now.month,
        now.day,
      ); //.subtract(Duration(days: 2));
    }
    final (
      newSteps,
      newCaloriesBurned,
      newExerciseMinutes,
      latestDataEpoch,
    ) = await queryHealthData(start, now);
    print("fetched from $start to $now");

    await promise;
    // Update game state with new health data
    if (newCaloriesBurned == 0 && newSteps == 0 && newExerciseMinutes == 0) {
      return;
    }
    print(
      "got new health data $newSteps $newCaloriesBurned $newExerciseMinutes",
    );
    gameState.processHealthData(
      newSteps,
      newCaloriesBurned,
      newExerciseMinutes,
    );
    gameState.lastHealthSync = latestDataEpoch;
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

    // Convert to ObjectBox model and deduplicate
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
        .toSet() // Remove duplicates
        .toList();
  }

  Future<void> syncHealthData(
    ObjectBox objectBoxService,
    GameState gameState,
  ) async {
    // final store = await openStore(); // Initialize ObjectBox
    final box = objectBoxService.store.box<HealthDataEntry>();

    // Fetch data from 10 minutes before the last saved time to now
    // to handle late recordings
    final startTime =
        (await HealthDataEntry.latestEntryDate(
          box,
        ))?.subtract(Duration(minutes: 10)) ??
        DateTime.fromMillisecondsSinceEpoch(gameState.startHealthSync);

    final now = DateTime.now();
    final entries = await queryHealthEntries(startTime, now);
    // Insert new records into ObjectBox
    box.putMany(entries);
    updateHealthState(box, gameState, now);
  }

  void updateHealthState(
    Box<HealthDataEntry> box,
    GameState gameState,
    DateTime now,
  ) async {
    final (newSteps, newCalories, newExercise) =
        await (
          HealthDataEntry.healthForDay(box, HealthDataType.STEPS.name, now),
          HealthDataEntry.healthForDay(
            box,
            HealthDataType.ACTIVE_ENERGY_BURNED.name,
            now,
          ),
          HealthDataEntry.healthForDay(
            box,
            HealthDataType.EXERCISE_TIME.name,
            now,
          ),
        ).wait;

    final previousSteps = steps;
    final previousCalories = caloriesBurned;
    final previousExercise = exerciseMinutes;
    steps = newSteps.round();
    caloriesBurned = newCalories;
    exerciseMinutes = newExercise.round();

    final stepsDelta = steps - previousSteps;
    final caloriesDelta = caloriesBurned - previousCalories;
    final exerciseDelta = exerciseMinutes - previousExercise;

    if (caloriesDelta == 0 && stepsDelta == 0 && exerciseDelta == 0) {
      return;
    }
    print("got new health data $newSteps $caloriesDelta $exerciseDelta");
    gameState.processHealthData(stepsDelta, caloriesDelta, exerciseDelta);
  }
}
