import 'package:idlefit/models/daily_quest.dart';
import 'package:idlefit/models/currency_repo.dart';
import 'package:idlefit/models/background_activity.dart';
import 'package:idlefit/services/storage_service.dart';

class GameState {
  // Game state
  final bool _isPaused;
  final int _lastGenerated;
  final int _doubleCoinExpiry;

  // Services
  final BackgroundActivity _backgroundActivity;
  final StorageService storageService;
  final CurrencyRepo _currencyRepo;
  final DailyQuestRepo _dailyQuestRepo;

  GameState({
    required bool isPaused,
    required int lastGenerated,
    required int doubleCoinExpiry,
    required this.storageService,
    required CurrencyRepo currencyRepo,
    required DailyQuestRepo dailyQuestRepo,
    BackgroundActivity? backgroundActivity,
  }) : _isPaused = isPaused,
       _lastGenerated = lastGenerated,
       _doubleCoinExpiry = doubleCoinExpiry,
       _currencyRepo = currencyRepo,
       _dailyQuestRepo = dailyQuestRepo,
       _backgroundActivity = backgroundActivity ?? BackgroundActivity();

  /// **Public Getters (Encapsulation)**
  bool get isPaused => _isPaused;
  int get lastGenerated => _lastGenerated;
  int get doubleCoinExpiry => _doubleCoinExpiry;
  BackgroundActivity get backgroundActivity => _backgroundActivity;

  /// **Repositories (Encapsulation)**
  CurrencyRepo get currencyRepo => _currencyRepo;
  DailyQuestRepo get dailyQuestRepo => _dailyQuestRepo;

  /// **CopyWith (Immutable Updates)**
  GameState copyWith({
    bool? isPaused,
    int? lastGenerated,
    int? doubleCoinExpiry,
    BackgroundActivity? backgroundActivity,
  }) {
    return GameState(
      isPaused: isPaused ?? _isPaused,
      lastGenerated: lastGenerated ?? _lastGenerated,
      doubleCoinExpiry: doubleCoinExpiry ?? _doubleCoinExpiry,
      backgroundActivity: backgroundActivity ?? _backgroundActivity,
      storageService: storageService,
      currencyRepo: _currencyRepo,
      dailyQuestRepo: _dailyQuestRepo,
    );
  }

  /// **Convert to JSON (Persistence)**
  Map<String, dynamic> toJson() {
    return {
      'lastGenerated': _lastGenerated,
      'doubleCoinExpiry': _doubleCoinExpiry,
    };
  }
}
