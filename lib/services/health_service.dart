// lib/services/health_service.dart
import 'dart:async';
import 'package:flame/game.dart';
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
  int caloriesBurned = 0;
  int exerciseMinutes = 0;

  bool _isAuthorized = false;
  Timer? _refreshTimer;

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

  int parseHealthData(List<HealthDataPoint> healthData, HealthDataType type) {
    final data = healthData.where((data) => data.type == type).toList();
    if (data.isEmpty) {
      return 0;
    }
    // if (type == HealthDataType.STEPS) {
    //   for (final point in data) {
    //     print(
    //       "${point.dateFrom}-${point.dateTo}: ${(point.value as NumericHealthValue).numericValue.toInt()}",
    //     );
    //   }
    // }

    return data
        .map((e) => (e.value as NumericHealthValue).numericValue.toInt())
        .reduce((a, b) => a + b);
  }

  Future<(int, int, int)> fetchLatestData(DateTime start, end) async {
    if (!_isAuthorized) return (0, 0, 0);

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
      return (steps, caloriesBurned, exerciseMinutes);
    } catch (e) {
      debugPrint('Error fetching health data: $e');
    }
    return (0, 0, 0);
  }

  /// for initializing data on health activity widget
  Future<void> collectHealthToday(GameState gameState, DateTime date) async {
    if (steps > 0 || caloriesBurned > 0 || exerciseMinutes > 0) {
      // already collected
      return;
    }
    if (gameState.lastHealthSync == 0) {
      // no data at all. run main collector
      return;
    }
    // on launch, previous is zero
    // get from start of day to last sync
    final today = DateTime(date.year, date.month, date.day);
    final previous = DateTime.fromMillisecondsSinceEpoch(
      gameState.lastHealthSync,
    );
    print("init health fetch $today - $previous");
    final (
      newSteps,
      newCaloriesBurned,
      newExerciseMinutes,
    ) = await fetchLatestData(today, previous);
    steps = newSteps;
    caloriesBurned = newCaloriesBurned;
    exerciseMinutes = newExerciseMinutes;
  }

  Future<void> collectHealth(GameState gameState) async {
    final now = DateTime.now();
    await collectHealthToday(gameState, now);

    final previousSteps = steps;
    final previousCalories = caloriesBurned;
    final previousExercise = exerciseMinutes;

    DateTime start;
    if (gameState.lastHealthSync > 0) {
      start = DateTime(now.year, now.month, now.day);
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
    ) = await fetchLatestData(start, now);
    print("fetched from $start to $now");

    // Calculate deltas
    final stepsDelta = newSteps - previousSteps;
    final caloriesDelta = newCaloriesBurned - previousCalories;
    final exerciseDelta = newExerciseMinutes - previousExercise;

    // Update game state with new health data
    if (caloriesDelta == 0 && stepsDelta == 0 && exerciseDelta == 0) {
      return;
    }
    print("got new health data $stepsDelta $caloriesDelta $exerciseDelta");
    gameState.processHealthData(stepsDelta, caloriesDelta, exerciseDelta);
    steps = newSteps;
    caloriesBurned = newCaloriesBurned;
    exerciseMinutes = newExerciseMinutes;
    gameState.lastHealthSync = now.millisecondsSinceEpoch;
  }

  // void startBackgroundCollection(GameState gameState) {
  //   // Check and update health data every minute
  //   _refreshTimer = Timer.periodic(const Duration(minutes: 15), (timer) async {
  //     collectHealth(gameState);
  //   });
  // }

  void dispose() {
    _refreshTimer?.cancel();
  }
}
