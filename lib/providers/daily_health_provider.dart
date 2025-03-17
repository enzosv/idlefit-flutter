import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:idlefit/main.dart';
import 'package:idlefit/objectbox.g.dart';

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
  DailyHealthNotifier(this.box, super.state);

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

  // returns the difference betweeen old health and new health
  Future<DailyHealth> reset(DateTime day, DailyHealth newHealth) async {
    final dayTimestamp =
        DateTime(day.year, day.month, day.day).millisecondsSinceEpoch;
    final old = await _getAtDay(dayTimestamp);
    final dif =
        DailyHealth()
          ..caloriesBurned = newHealth.caloriesBurned - old.caloriesBurned
          ..steps = newHealth.steps - old.steps
          ..exerciseMinutes = newHealth.exerciseMinutes - old.exerciseMinutes;

    old.caloriesBurned = newHealth.caloriesBurned;
    old.exerciseMinutes = newHealth.exerciseMinutes;
    old.steps = newHealth.steps;

    box.putAsync(old);
    if (dayTimestamp == state.dayTimestamp) {
      state = old;
    }
    return dif;
  }
}

final dailyHealthProvider =
    StateNotifierProvider<DailyHealthNotifier, DailyHealth>((ref) {
      return DailyHealthNotifier(
        ref.read(objectBoxProvider).store.box<DailyHealth>(),
        DailyHealth(),
      );
    });
