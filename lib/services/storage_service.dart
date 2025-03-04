import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  final SharedPreferences _prefs;

  StorageService(this._prefs);

  Future<void> saveGameState(Map<String, dynamic> gameState) async {
    await _prefs.setString('game_state', jsonEncode(gameState));
  }

  Future<Map<String, dynamic>?> loadGameState() async {
    final stateString = _prefs.getString('game_state');
    if (stateString == null) return null;

    try {
      return jsonDecode(stateString) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  Future<void> clearGameState() async {
    await _prefs.remove('game_state');
  }
}
