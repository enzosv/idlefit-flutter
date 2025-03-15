import 'dart:async';
import 'package:health/health.dart';
import 'package:flutter/material.dart';
import 'package:idlefit/models/health_data_entry.dart';
import 'package:idlefit/models/health_data_repo.dart';
import 'package:idlefit/providers/game_state_provider.dart';
import 'package:idlefit/services/object_box.dart';

class HealthService {
  final Health health = Health();

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
    GameStateNotifier gameStateNotifier,
  ) async {
    // final store = await openStore(); // Initialize ObjectBox
    final box = objectBoxService.store.box<HealthDataEntry>();

    final repo = HealthDataRepo(box: box);
    final syncStart = await repo.syncStart();
    final entries = await queryHealthEntries(syncStart, DateTime.now());
    final newEntries = await repo.newFromList(entries, syncStart);
    if (newEntries.isEmpty) {
      return;
    }

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
}
