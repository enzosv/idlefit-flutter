import 'dart:convert';

import 'package:idlefit/models/background_activity.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GameState {
  // Game state
  final bool _isPaused;
  final int _lastGenerated;
  final int _doubleCoinExpiry;

  static const _gameStateKey = 'game_state';

  // Services
  final BackgroundActivity _backgroundActivity;

  GameState({
    required bool isPaused,
    required int lastGenerated,
    required int doubleCoinExpiry,
    BackgroundActivity? backgroundActivity,
  }) : _isPaused = isPaused,
       _lastGenerated = lastGenerated,
       _doubleCoinExpiry = doubleCoinExpiry,
       _backgroundActivity = backgroundActivity ?? BackgroundActivity();

  /// **Public Getters (Encapsulation)**
  bool get isPaused => _isPaused;
  int get lastGenerated => _lastGenerated;
  int get doubleCoinExpiry => _doubleCoinExpiry;
  BackgroundActivity get backgroundActivity => _backgroundActivity;

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
    );
  }

  /// **Persistence**

  Future<void> saveGameState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _gameStateKey,
      jsonEncode({
        'lastGenerated': _lastGenerated,
        'doubleCoinExpiry': _doubleCoinExpiry,
      }),
    );
  }

  Future<Map<String, dynamic>> loadGameState() async {
    final prefs = await SharedPreferences.getInstance();
    final stateString = prefs.getString(_gameStateKey);
    if (stateString == null) {
      return {'lastGenerated': 0, 'doubleCoinExpiry': 0};
    }

    return jsonDecode(stateString) as Map<String, dynamic>;
  }

  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_gameStateKey);
  }
}
