import 'dart:async';
import 'dart:io';
import 'package:health/health.dart';
import 'package:flutter/material.dart';
import 'package:idlefit/models/quest_repo.dart';
import 'package:idlefit/models/quest_stats.dart';
import 'package:idlefit/providers/game_state_provider.dart';
import 'package:idlefit/services/ios_health_service.dart';

class HealthService {
  final Health health = Health();

  HealthService();

  Future<void> initialize() async {
    try {
      await requestAuthorization();
    } catch (e) {
      debugPrint('Error initializing health service: $e');
    }
  }

  Future<bool> requestAuthorization() async {
    try {
      final List<HealthDataType> types = [
        HealthDataType.ACTIVE_ENERGY_BURNED,
        HealthDataType.STEPS,
      ];
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
    DateTime endOfDay,
    HealthDataType type,
  ) async {
    final data = await health.getHealthDataFromTypes(
      startTime: startOfDay,
      endTime: endOfDay,
      types: [type],
    );
    final total = data.fold(0.0, (sum, entry) {
      final value = (entry.value as NumericHealthValue).numericValue.toDouble();
      return sum + value;
    });
    return total;
    // Group data by time ranges and sources
    // Map<int, Map<String, double>> timeRangeData = {};

    // for (final entry in data) {
    //   final timeKey = entry.dateFrom.millisecondsSinceEpoch;
    //   timeRangeData[timeKey] ??= {};

    //   final value = (entry.value as NumericHealthValue).numericValue.toDouble();
    //   timeRangeData[timeKey]![entry.sourceId] =
    //       (timeRangeData[timeKey]![entry.sourceId] ?? 0) + value;
    // }

    // // For each time range, select the best source if there are multiple
    // double total = 0.0;
    // for (final timeRange in timeRangeData.entries) {
    //   if (timeRange.value.length == 1) {
    //     // Only one source for this time range, use it
    //     total += timeRange.value.values.first;
    //   } else {
    //     // Multiple sources, choose the one with higher value
    //     total += timeRange.value.values.reduce((a, b) => a > b ? a : b);
    //   }
    // }

    // return total;
  }

  Future<void> syncDay(
    DateTime day,
    GameStateNotifier gameStateNotifier,
    QuestStatsRepository questStatsRepository,
    IosHealthService? iosService,
  ) async {
    final startOfDay = DateTime(day.year, day.month, day.day);
    final endOfDay = DateTime(day.year, day.month, day.day, 23, 59, 59, 999);
    final dayTimestamp = startOfDay.millisecondsSinceEpoch;

    double steps = 0;
    double calories = 0;
    if (iosService != null) {
      (steps, calories) = await iosService.queryHealthForRange(
        start: startOfDay,
        end: endOfDay,
      );
    } else {
      [steps, calories] =
          await [
            _getDailyHealth(startOfDay, endOfDay, HealthDataType.STEPS),
            _getDailyHealth(
              startOfDay,
              endOfDay,
              HealthDataType.ACTIVE_ENERGY_BURNED,
            ),
          ].wait;
    }

    final stepsDif = await questStatsRepository.setProgress(
      QuestAction.walk,
      QuestUnit.steps,
      dayTimestamp,
      steps,
    );
    final caloriesDif = await questStatsRepository.setProgress(
      QuestAction.burn,
      QuestUnit.calories,
      dayTimestamp,
      calories,
    );
    gameStateNotifier.convertHealthStats(stepsDif.toInt(), caloriesDif);
  }

  Future<void> syncHealthData(
    GameStateNotifier gameStateNotifier,
    QuestStatsRepository questStatsRepository,
  ) async {
    final iosService = Platform.isIOS ? IosHealthService() : null;
    final now = DateTime.now();
    await [
      syncDay(now, gameStateNotifier, questStatsRepository, iosService),
      syncDay(
        now.subtract(const Duration(days: 1)),
        gameStateNotifier,
        questStatsRepository,
        iosService,
      ),
    ].wait;
  }
}
