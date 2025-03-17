import 'dart:async';
import 'dart:io';
import 'package:health/health.dart';
import 'package:flutter/material.dart';
import 'package:idlefit/providers/daily_health_provider.dart';
import 'package:idlefit/providers/game_state_provider.dart';

class HealthService {
  final Health health = Health();

  HealthService();

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

    assert(
      await health.getTotalStepsInInterval(startOfDay, endOfDay) ==
          await _getDailyHealth(startOfDay, endOfDay, HealthDataType.STEPS),
      "steps implementation is different",
    );

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
  }
}
