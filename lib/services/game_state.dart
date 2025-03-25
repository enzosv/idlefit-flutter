import 'dart:convert';

import 'package:idlefit/models/background_activity.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GameState {
  // Game state
  final int _doubleCoinExpiry;
  final int _healthLastSynced;
  final double _passiveOutput;

  static const _gameStateKey = 'game_state';

  // Services
  final BackgroundActivity _backgroundActivity;

  GameState({
    required int doubleCoinExpiry,
    required int healthLastSynced,
    required double passiveOutput,
    BackgroundActivity? backgroundActivity,
  }) : _doubleCoinExpiry = doubleCoinExpiry,
       _healthLastSynced = healthLastSynced,
       _passiveOutput = passiveOutput,
       _backgroundActivity = backgroundActivity ?? BackgroundActivity();

  /// **Public Getters (Encapsulation)**
  int get doubleCoinExpiry => _doubleCoinExpiry;
  int get healthLastSynced => _healthLastSynced;
  double get passiveOutput => _passiveOutput;
  BackgroundActivity get backgroundActivity => _backgroundActivity;

  /// **CopyWith (Immutable Updates)**
  GameState copyWith({
    int? doubleCoinExpiry,
    int? healthLastSynced,
    double? passiveOutput,
    BackgroundActivity? backgroundActivity,
  }) {
    return GameState(
      doubleCoinExpiry: doubleCoinExpiry ?? _doubleCoinExpiry,
      healthLastSynced: healthLastSynced ?? _healthLastSynced,
      passiveOutput: passiveOutput ?? _passiveOutput,
      backgroundActivity: backgroundActivity ?? _backgroundActivity,
    );
  }

  /// **Persistence**

  Future<void> saveGameState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _gameStateKey,
      jsonEncode({
        'doubleCoinExpiry': _doubleCoinExpiry,
        'healthLastSynced': _healthLastSynced,
      }),
    );
  }

  Future<Map<String, dynamic>> loadGameState() async {
    final prefs = await SharedPreferences.getInstance();
    final stateString = prefs.getString(_gameStateKey);
    if (stateString == null) {
      return {'lastGenerated': 0, 'doubleCoinExpiry': 0, 'healthLastSynced': 0};
    }

    return jsonDecode(stateString) as Map<String, dynamic>;
  }

  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_gameStateKey);
  }
}
