import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:idlefit/main.dart';
import 'package:idlefit/models/currency.dart';
import 'package:idlefit/objectbox.g.dart';
import 'package:objectbox/objectbox.dart';

@Entity()
class DailyCurrency {
  @Id(assignable: true)
  int dayTimestamp = 0;

  double coinsEarned = 0;
  double spaceEarned = 0;
  double energyEarned = 0;
  double coinsSpent = 0;
  double spaceSpent = 0;
  double energySpent = 0;
}

class DailyCurrencyRepository {
  final Box<DailyCurrency> box;

  DailyCurrencyRepository(this.box);

  Future<DailyCurrency> getToday() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    return getAtDay(today);
  }

  Future<DailyCurrency> getAtDay(int dayTimestamp) async {
    return box.get(dayTimestamp) ??
        (DailyCurrency()..dayTimestamp = dayTimestamp);
  }

  Future<void> updateCurrency(
    int dayTimestamp,
    CurrencyType type,
    double amount,
    bool isEarn,
  ) async {
    final dailyCurrency = await getAtDay(dayTimestamp);
    switch (type) {
      case CurrencyType.coin:
        isEarn
            ? dailyCurrency.coinsEarned += amount
            : dailyCurrency.coinsSpent += amount;
      case CurrencyType.space:
        isEarn
            ? dailyCurrency.spaceEarned += amount
            : dailyCurrency.spaceSpent += amount;
      case CurrencyType.energy:
        isEarn
            ? dailyCurrency.energyEarned += amount
            : dailyCurrency.energySpent += amount;
      default:
        return;
    }
    box.putAsync(dailyCurrency);
  }
}

class DailyCurrencyNotifier extends StateNotifier<DailyCurrency> {
  final DailyCurrencyRepository repository;

  DailyCurrencyNotifier(this.repository, super.state);

  Future<void> initialize() async {
    state = await repository.getToday();
  }

  Future<void> updateToday(
    CurrencyType type,
    double amount,
    bool isEarn,
  ) async {
    final now = DateTime.now();
    final dayTimestamp =
        DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    await repository.updateCurrency(dayTimestamp, type, amount, isEarn);
    state = await repository.getAtDay(dayTimestamp);
  }
}

final dailyCurrencyRepositoryProvider = Provider<DailyCurrencyRepository>((
  ref,
) {
  final box = ref.read(objectBoxProvider).store.box<DailyCurrency>();
  return DailyCurrencyRepository(box);
});

final dailyCurrencyProvider =
    StateNotifierProvider<DailyCurrencyNotifier, DailyCurrency>((ref) {
      final repository = ref.read(dailyCurrencyRepositoryProvider);
      return DailyCurrencyNotifier(repository, DailyCurrency());
    });
