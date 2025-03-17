import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:idlefit/main.dart';
import 'package:idlefit/objectbox.g.dart';
import 'package:idlefit/providers/game_state_provider.dart';
import 'package:objectbox/objectbox.dart';

@Entity()
class DailyHealth {
  @Id(assignable: true)
  int dayTimestamp = 0;

  int steps = 0;
  double caloriesBurned = 0;
  double exerciseMinutes = 0;
}

class DailyHealthNotifier extends StateNotifier<DailyHealth> {
  final Box<DailyHealth> box;
  final Ref ref;
  DailyHealthNotifier(this.ref, this.box, super.state);

  Future<void> initialize() async {
    state = await _getToday();
  }

  Future<DailyHealth> _getToday() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    if (state.dayTimestamp == today) {
      return state;
    }
    return _getAtDay(today);
  }

  Future<DailyHealth> _getAtDay(int dayTimestamp) async {
    return box.get(dayTimestamp) ??
        (DailyHealth()..dayTimestamp = dayTimestamp);
  }

  Future<DailyHealth> total() async {
    final entries = await box.getAllAsync();
    final total = entries.fold(
      DailyHealth(),
      (acc, entry) =>
          acc
            ..caloriesBurned += entry.caloriesBurned
            ..steps += entry.steps
            ..exerciseMinutes += entry.exerciseMinutes,
    );
    return total;
  }

  Future<DateTime> firstDay() async {
    final first =
        await box
            .query()
            .order(DailyHealth_.dayTimestamp)
            .build()
            .findFirstAsync();
    if (first == null) {
      return DateTime.now();
    }
    return DateTime.fromMillisecondsSinceEpoch(first.dayTimestamp);
  }

  Future<void> reset(int dayTimestamp, DailyHealth newHealth) async {
    final old = await _getAtDay(dayTimestamp);
    final difCalories = newHealth.caloriesBurned - old.caloriesBurned;
    final difSteps = newHealth.steps - old.steps;
    final difExerciseMinutes = newHealth.exerciseMinutes - old.exerciseMinutes;

    old.caloriesBurned = newHealth.caloriesBurned;
    old.exerciseMinutes = newHealth.exerciseMinutes;
    old.steps = newHealth.steps;

    box.putAsync(old);
    if (dayTimestamp != state.dayTimestamp) {
      return;
    }
    state = old;
    ref
        .read(gameStateProvider.notifier)
        .convertHealthStats(
          difSteps.toDouble(),
          difCalories,
          difExerciseMinutes,
        );
  }
}

final dailyHealthProvider =
    StateNotifierProvider<DailyHealthNotifier, DailyHealth>((ref) {
      return DailyHealthNotifier(
        ref,
        ref.read(objectBoxProvider).store.box<DailyHealth>(),
        DailyHealth(),
      );
    });
