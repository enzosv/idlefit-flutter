import 'package:collection/collection.dart';
import 'package:idlefit/models/daily_quest.dart';
import 'package:idlefit/models/shop_items_repo.dart';
import 'package:idlefit/models/currency_repo.dart';
import 'package:idlefit/services/background_activity.dart';
import 'package:idlefit/services/storage_service.dart';
import '../models/shop_items.dart';

class GameState {
  // Game state
  final bool _isPaused;
  final int _lastGenerated;
  final int _doubleCoinExpiry;
  final double _offlineCoinMultiplier;

  // Generators and shop items
  final List<ShopItem> _shopItems;

  // Services
  final BackgroundActivity _backgroundActivity;
  final StorageService storageService;
  final CurrencyRepo _currencyRepo;
  final ShopItemsRepo _shopItemRepo;
  final DailyQuestRepo _dailyQuestRepo;

  GameState({
    required bool isPaused,
    required int lastGenerated,
    required int doubleCoinExpiry,
    required double offlineCoinMultiplier,
    required List<ShopItem> shopItems,
    required this.storageService,
    required CurrencyRepo currencyRepo,
    required ShopItemsRepo shopItemRepo,
    required DailyQuestRepo dailyQuestRepo,
    BackgroundActivity? backgroundActivity,
  }) : _isPaused = isPaused,
       _lastGenerated = lastGenerated,
       _doubleCoinExpiry = doubleCoinExpiry,
       _offlineCoinMultiplier = offlineCoinMultiplier,
       _shopItems = List.unmodifiable(shopItems),
       _currencyRepo = currencyRepo,
       _shopItemRepo = shopItemRepo,
       _dailyQuestRepo = dailyQuestRepo,
       _backgroundActivity = backgroundActivity ?? BackgroundActivity();

  /// **Public Getters (Encapsulation)**
  bool get isPaused => _isPaused;
  int get lastGenerated => _lastGenerated;
  int get doubleCoinExpiry => _doubleCoinExpiry;
  double get offlineCoinMultiplier => _offlineCoinMultiplier;
  List<ShopItem> get shopItems => UnmodifiableListView(_shopItems);
  BackgroundActivity get backgroundActivity => _backgroundActivity;

  /// **Repositories (Encapsulation)**
  CurrencyRepo get currencyRepo => _currencyRepo;
  ShopItemsRepo get shopItemRepo => _shopItemRepo;
  DailyQuestRepo get dailyQuestRepo => _dailyQuestRepo;

  /// **CopyWith (Immutable Updates)**
  GameState copyWith({
    bool? isPaused,
    int? lastGenerated,
    int? doubleCoinExpiry,
    double? offlineCoinMultiplier,
    List<ShopItem>? shopItems,
    BackgroundActivity? backgroundActivity,
  }) {
    return GameState(
      isPaused: isPaused ?? _isPaused,
      lastGenerated: lastGenerated ?? _lastGenerated,
      doubleCoinExpiry: doubleCoinExpiry ?? _doubleCoinExpiry,
      offlineCoinMultiplier: offlineCoinMultiplier ?? _offlineCoinMultiplier,
      shopItems: shopItems ?? _shopItems,
      backgroundActivity: backgroundActivity ?? _backgroundActivity,
      storageService: storageService,
      currencyRepo: _currencyRepo,
      shopItemRepo: _shopItemRepo,
      dailyQuestRepo: _dailyQuestRepo,
    );
  }

  /// **Convert to JSON (Persistence)**
  Map<String, dynamic> toJson() {
    return {
      'lastGenerated': _lastGenerated,
      'offlineCoinMultiplier': _offlineCoinMultiplier,
      'doubleCoinExpiry': _doubleCoinExpiry,
    };
  }
}
