import 'dart:async';
import 'package:health/health.dart';
import 'package:flutter/material.dart';
import '../game/game_state.dart';

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
      final duration = end - start;
      final bpm = estimateBPM(value, end - start);
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

  Future<(int, double, int)> queryHealthData(DateTime start, end) async {
    if (!_isAuthorized) return (0, 0.0, 0);

    try {
      final healthData = await health.getHealthDataFromTypes(
        types: types,
        startTime: start,
        endTime: end,
      );

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
      return (steps.round(), caloriesBurned, exerciseMinutes.round());
    } catch (e) {
      debugPrint('Error fetching health data: $e');
    }
    return (0, 0.0, 0);
  }

  Future<void> collectHealthToday(GameState gameState, DateTime now) async {
    final todayStart = DateTime(now.year, now.month, now.day);
    final (
      newSteps,
      newCaloriesBurned,
      newExerciseMinutes,
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
      start = DateTime.fromMillisecondsSinceEpoch(gameState.lastHealthSync);
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
    gameState.lastHealthSync = now.millisecondsSinceEpoch;
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
    return ((caloriesBurned / (durationMinutes * 5)) * 1000) / (weightKg * k);
  }
}
